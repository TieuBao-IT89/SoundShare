import { Router } from "express";
import { createRateLimit } from "../middleware/upload-limits.middleware.js";
import { createTrackSchema, listTracksSchema, trackIdSchema, parse, decodeCursor } from "../validation/track.schema.js";
import { HttpError } from "../utils/http-error.js";

export const createTrackRouter = ({ service, requireAuth }) => {
  const router = Router();
  router.use(requireAuth);
  router.use((req, res, next) => { res.set("Cache-Control", "no-store"); next(); });
  router.use(createRateLimit({ limit: 120 }));
  router.get("/", async (req, res) => {
    const filters = parse(listTracksSchema, req.query);
    if (req.body !== undefined) throw new HttpError(400, "VALIDATION_ERROR", "A request body is not accepted.");
    res.json({ success: true, data: await service.list(req.clerkUserId, { ...filters, cursor: decodeCursor(filters.cursor) }) });
  });
  router.post("/", createRateLimit({ limit: 20 }), async (req, res) => {
    if (Object.keys(req.query).length) throw new HttpError(400, "VALIDATION_ERROR", "Query parameters are not accepted.");
    const result = await service.create(req.clerkUserId, parse(createTrackSchema, req.body));
    res.status(result.created ? 201 : 200).json({ success: true, data: { id: result.id } });
  });
  router.use("/:songId", (req, res, next) => {
    parse(trackIdSchema, req.params.songId);
    if (Object.keys(req.query).length || req.body !== undefined || Number(req.get("content-length") || 0) > 0 || req.get("transfer-encoding")) {
      throw new HttpError(400, "VALIDATION_ERROR", "No query parameters or body are accepted.");
    }
    next();
  });
  router.get("/:songId/playback", async (req, res) => res.json({ success: true, data: await service.playback(req.clerkUserId, req.params.songId) }));
  for (const [method, liked] of [["put", true], ["delete", false]]) router[method]("/:songId/favorite", async (req, res) => {
    await service.favorite(req.clerkUserId, req.params.songId, liked);
    res.status(204).end();
  });
  return router;
};
