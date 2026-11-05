import { Router } from "express";
import { createUploadController } from "../controllers/upload.controller.js";
import { uploadArtwork, uploadAudio } from "../middleware/upload.middleware.js";
import { createRateLimit, createUploadConcurrencyLimit } from "../middleware/upload-limits.middleware.js";

export const createUploadRouter = ({ service, requireAuth, rateLimit }) => {
  const router = Router();
  const controller = createUploadController(service);
  router.use(requireAuth);
  router.use(createRateLimit({ limit: 60 }));
  const uploadLimit = rateLimit || createRateLimit();
  const deleteLimit = createRateLimit({ limit: 20 });
  const concurrency = createUploadConcurrencyLimit();
  router.post("/artwork", uploadLimit, concurrency, uploadArtwork, controller.upload("artwork"));
  router.post("/audio", uploadLimit, concurrency, uploadAudio, controller.upload("audio"));
  router.get("/:assetId/access", controller.getAccess);
  router.delete("/:assetId", deleteLimit, controller.remove);
  return router;
};
