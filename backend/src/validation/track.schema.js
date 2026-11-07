import { z } from "zod";
import { HttpError } from "../utils/http-error.js";

export const trackIdSchema = z.uuid();
const text = (max) => z.string().trim().min(1).max(max).refine((value) => !/[\u0000-\u001f\u007f]/.test(value));
export const createTrackSchema = z.object({
  audioAssetId: trackIdSchema, artworkAssetId: trackIdSchema.nullable().optional(),
  title: text(120), artist: text(120), genre: text(100), description: z.string().trim().max(1000).refine((value) => !value.includes('\u0000')).default(""),
  visibility: z.enum(['private','public']).default('private'), rightsConfirmed: z.boolean().default(false),
  lyricsLrc: z.string().min(1).max(65536).optional(),
}).strict().refine(value => value.visibility !== 'public' || value.rightsConfirmed);
const cursorSchema = z.object({ at: z.iso.datetime({ offset: true }), id: trackIdSchema }).strict();
export const listTracksSchema = z.object({
  query: z.string().trim().max(120).refine((value) => !/[\u0000-\u001f\u007f]/.test(value)).default(""), genre: text(100).optional(),
  collection: z.enum(["soft-focus", "after-hours"]).optional(),
  limit: z.string().regex(/^\d{1,2}$/).transform(Number).pipe(z.number().int().min(1).max(50)).default(50),
  cursor: z.string().max(400).regex(/^[A-Za-z0-9_-]+$/).optional(),
}).strict();
export const parse = (schema, value) => {
  const result = schema.safeParse(value);
  if (!result.success) throw new HttpError(400, "VALIDATION_ERROR", "The request contains invalid fields.");
  return result.data;
};
export const decodeCursor = (cursor) => {
  if (!cursor) return null;
  try { return parse(cursorSchema, JSON.parse(Buffer.from(cursor, "base64url").toString("utf8"))); }
  catch { throw new HttpError(400, "VALIDATION_ERROR", "The page cursor is invalid."); }
};
export const encodeCursor = (row) => Buffer.from(JSON.stringify({ at: row.cursor_time || new Date(row.created_at).toISOString(), id: row.id })).toString("base64url");
