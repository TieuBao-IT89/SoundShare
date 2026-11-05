import { assetIdSchema } from "../validation/upload.schema.js";
import { HttpError } from "../utils/http-error.js";

export const createUploadController = (service) => ({
  upload: (mediaType) => async (req, res) => {
    req.uploadProcessing = true;
    try {
      const result = await service.upload({
        userId: req.clerkUserId, mediaType, file: req.file, requestId: req.requestId,
      });
      res.set("Cache-Control", "no-store");
      return res.status(result.created ? 201 : 200).json({
        success: true, data: { ...result.asset, access: result.access },
      });
    } finally {
      req.uploadProcessing = false;
      req.releaseUploadSlot?.();
    }
  },
  getAccess: async (req, res) => {
    if (!assetIdSchema.safeParse(req.params.assetId).success || Object.keys(req.query).length) {
      throw new HttpError(400, "VALIDATION_ERROR", "A valid asset UUID and no query parameters are required.");
    }
    const result = await service.getAccess({ id: req.params.assetId, userId: req.clerkUserId });
    res.set("Cache-Control", "no-store");
    return res.json({ success: true, data: { ...result.asset, access: result.access } });
  },
  remove: async (req, res) => {
    const hasBody = req.body !== undefined || Number(req.get("content-length") || 0) > 0 || req.get("transfer-encoding");
    if (!assetIdSchema.safeParse(req.params.assetId).success || Object.keys(req.query).length || hasBody) {
      throw new HttpError(400, "VALIDATION_ERROR", "A valid asset UUID with no query parameters or request body is required.");
    }
    await service.remove({ id: req.params.assetId, userId: req.clerkUserId, requestId: req.requestId });
    res.set("Cache-Control", "no-store");
    return res.status(204).end();
  },
});
