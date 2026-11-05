import { createHash } from "node:crypto";
import { z } from "zod";
import { validateUpload } from "../validation/upload.schema.js";
import { HttpError } from "../utils/http-error.js";

const storedAssetSchema = z.object({
  public_id: z.string(), type: z.literal("authenticated"),
  resource_type: z.enum(["image", "video"]), format: z.string(),
  bytes: z.number().int().positive(), secure_url: z.url(),
});
const hash = (value) => createHash("sha256").update(value).digest("hex");
const safeMetadata = (asset) => ({
  id: asset.id, mediaType: asset.media_type, resourceType: asset.resource_type,
  format: asset.format, bytes: Number(asset.bytes), originalFilename: asset.original_filename,
  mimeType: asset.mime_type, createdAt: asset.created_at,
});

export const createUploadService = ({ repository, storage, report = (event) => console.error(JSON.stringify(event)) }) => {
  const access = (asset) => {
    try { return storage.createAccess(asset); }
    catch { throw new HttpError(502, "STORAGE_UNAVAILABLE", "Media access is temporarily unavailable."); }
  };
  return {
    upload: async ({ userId, mediaType, file, requestId }) => {
      const policy = validateUpload(file, mediaType);
      // Owner + type + content identify retries without storing client-controlled keys.
      const publicId = `soundshare/${mediaType}/${hash(userId)}/${hash(file.buffer)}`;
      try {
        const completed = await repository.withAssetLock(publicId, async (records) => {
          const existing = await records.findByPublicId(publicId, userId);
          if (existing) return { created: false, record: existing };

          let stored;
          let uploaded = false;
          try {
            stored = await storage.find(publicId, policy.resourceType);
            if (!stored) {
              await storage.upload({ buffer: file.buffer, publicId, resourceType: policy.resourceType, formats: policy.formats });
              uploaded = true;
              stored = await storage.find(publicId, policy.resourceType);
            }
          } catch {
            // An interrupted upload may have reached Storage. A retry reconciles it.
            throw new HttpError(502, "STORAGE_UNAVAILABLE", "Cloud storage is temporarily unavailable. Retry the same file.");
          }

          const parsed = storedAssetSchema.safeParse(stored);
          const url = parsed.success ? new URL(parsed.data.secure_url) : null;
          if (!parsed.success || stored.public_id !== publicId || stored.resource_type !== policy.resourceType ||
              stored.format !== policy.format || stored.bytes !== file.buffer.length ||
              url.protocol !== "https:" || url.search || /\/s--/.test(url.pathname)) {
            if (stored) {
              try { await storage.remove(publicId, policy.resourceType); }
              catch { report({ requestId, code: "UPLOAD_CLEANUP_REQUIRED" }); }
            }
            throw new HttpError(502, "STORAGE_VERIFICATION_FAILED", "Stored file verification failed.");
          }

          let asset;
          try {
            asset = await records.insert({
              clerk_user_id: userId, media_type: mediaType, public_id: publicId,
              secure_url: stored.secure_url, resource_type: stored.resource_type,
              format: stored.format, bytes: stored.bytes,
              original_filename: file.originalname, mime_type: policy.mimeType,
            });
          } catch {
            // Resolve an ambiguous INSERT before deciding whether cleanup is safe.
            let absent = false;
            try {
              asset = await records.findByPublicId(publicId, userId);
              absent = !asset;
            } catch { /* Keep a private object when database state is unknown. */ }
            if (!asset) {
              if (absent && uploaded) {
                try { await storage.remove(publicId, policy.resourceType); }
                catch { report({ requestId, code: "UPLOAD_CLEANUP_REQUIRED" }); }
              } else {
                report({ requestId, code: "UPLOAD_RECONCILIATION_REQUIRED" });
              }
              throw new HttpError(503, "DATABASE_UNAVAILABLE", "Metadata could not be saved. Retry the same file.");
            }
          }
          return { created: true, record: asset };
        });
        // Issue access only after the repository has committed successfully.
        return { created: completed.created, asset: safeMetadata(completed.record), access: access(completed.record) };
      } catch (error) {
        if (error instanceof HttpError) throw error;
        throw new HttpError(503, "DATABASE_UNAVAILABLE", "The media database is temporarily unavailable.");
      }
    },
    getAccess: async ({ id, userId }) => {
      let asset;
      try { asset = await repository.findById(id, userId); }
      catch { throw new HttpError(503, "DATABASE_UNAVAILABLE", "The media database is temporarily unavailable."); }
      if (!asset) throw new HttpError(404, "MEDIA_NOT_FOUND", "Media asset not found.");
      return { asset: safeMetadata(asset), access: access(asset) };
    },
    remove: async ({ id, userId, requestId }) => {
      let storageDeleted = false;
      try {
        const initial = await repository.findById(id, userId);
        if (!initial) throw new HttpError(404, "MEDIA_NOT_FOUND", "Media asset not found.");
        await repository.withAssetLock(initial.public_id, async (records) => {
          // A deleted asset may have been re-uploaded with the same public ID
          // while this request waited. Recheck the original UUID and owner.
          const current = await records.findById(id, userId);
          if (!current) throw new HttpError(404, "MEDIA_NOT_FOUND", "Media asset not found.");
          if (current.public_id !== initial.public_id) {
            throw new HttpError(409, "MEDIA_BUSY", "This asset is being changed. Retry shortly.");
          }
          if (await records.isReferencedByTrack(id, userId)) {
            throw new HttpError(409, "MEDIA_IN_USE", "This file is used by a saved track.");
          }
          try {
            // Storage accepts both a confirmed deletion and an already missing file.
            await storage.remove(current.public_id, current.resource_type);
            storageDeleted = true;
          } catch {
            throw new HttpError(502, "STORAGE_DELETE_FAILED", "Cloud storage could not confirm deletion. Retry this request.");
          }
          await records.deleteById(id, userId);
        });
      } catch (error) {
        if (storageDeleted) report({ requestId, code: "MEDIA_DELETE_RECONCILIATION_REQUIRED" });
        if (error instanceof HttpError) {
          if (error.code === "UPLOAD_IN_PROGRESS") {
            throw new HttpError(409, "MEDIA_BUSY", "This asset is being changed. Retry shortly.");
          }
          throw error;
        }
        throw new HttpError(503, "DATABASE_UNAVAILABLE", "Media deletion could not be confirmed. Retry this request.");
      }
    },
  };
};
