import { randomUUID } from "node:crypto";
import { HttpError } from "../../src/utils/http-error.js";

export const png = Buffer.from("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aXioAAAAASUVORK5CYII=", "base64");
const frame = Buffer.alloc(417);
Buffer.from([0xff, 0xfb, 0x90, 0x00]).copy(frame);
export const mp3 = Buffer.concat([frame, frame, frame]);
export const artworkFile = () => ({ buffer: png, originalname: "fixture.png", mimetype: "image/png" });
export const audioFile = () => ({ buffer: mp3, originalname: "silence.mp3", mimetype: "audio/mpeg" });

export const createFakes = () => {
  const assets = new Map();
  const objects = new Map();
  const locks = new Set();
  const events = [];
  const calls = { upload: 0, remove: 0, insert: 0, delete: 0 };
  const findById = async (id, owner) => [...assets.values()].find((asset) => asset.id === id && asset.clerk_user_id === owner) || null;
  const records = {
    isReferencedByTrack: async () => false,
    findById,
    deleteById: async (id, owner) => {
      calls.delete++;
      const asset = await findById(id, owner);
      if (asset) assets.delete(asset.public_id);
    },
    findByPublicId: async (id, owner) => {
      const asset = assets.get(id);
      return asset?.clerk_user_id === owner ? asset : null;
    },
    insert: async (asset) => {
      calls.insert++;
      const stored = { ...asset, id: randomUUID(), created_at: new Date(), bytes: String(asset.bytes) };
      assets.set(asset.public_id, stored);
      return stored;
    },
  };
  const repository = {
    withAssetLock: async (id, action) => {
      if (locks.has(id)) throw new HttpError(409, "UPLOAD_IN_PROGRESS", "Retry shortly.");
      locks.add(id);
      try { return await action(records); }
      finally { locks.delete(id); }
    },
    findById,
  };
  const storage = {
    find: async (id) => objects.get(id) || null,
    upload: async ({ buffer, publicId, resourceType, formats }) => {
      calls.upload++;
      objects.set(publicId, {
        public_id: publicId, resource_type: resourceType, type: "authenticated",
        format: resourceType === "video" ? "mp3" : formats.includes("png") ? "png" : formats[0],
        bytes: buffer.length,
        secure_url: `https://res.cloudinary.com/fixture/${resourceType}/authenticated/${publicId}.png`,
      });
    },
    remove: async (id) => { calls.remove++; objects.delete(id); },
    createAccess: () => ({ url: "https://example.com/private?signature=fixture", expiresAt: new Date(Date.now() + 300000).toISOString() }),
  };
  return { assets, objects, records, repository, storage, calls, events };
};
