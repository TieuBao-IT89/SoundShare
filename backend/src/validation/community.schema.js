import { z } from "zod";
export const reservedUsernames = new Set([
  "admin",
  "support",
  "soundshare",
  "system",
  "official",
  "search",
]);
const text = (max) =>
  z
    .string()
    .trim()
    .max(max)
    .refine((v) => !/[\u0000-\u001f\u007f]/.test(v));
const paragraph = (max) =>
  z
    .string()
    .trim()
    .max(max)
    .refine((v) => !/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(v));
export const usernameSchema = text(25)
  .transform((v) => v.replace(/^@/, "").toLowerCase())
  .pipe(
    z
      .string()
      .min(3)
      .max(24)
      .regex(/^[a-z0-9_][a-z0-9._]*[a-z0-9_]$/)
      .refine((v) => !reservedUsernames.has(v)),
  );
export const pageSchema = z
  .object({
    limit: z.coerce.number().int().min(1).max(50).default(20),
    offset: z.coerce.number().int().min(0).max(10000).default(0),
  })
  .strict();
export const searchSchema = pageSchema.extend({
  q: text(120).default(""),
  type: z.enum(["all", "songs", "users", "playlists"]).default("all"),
  genre: text(100).optional(),
});
export const discoverSchema = pageSchema.extend({
  period: z.enum(["today", "week", "month", "all"]).default("week"),
  mode: z
    .enum(["featured", "new", "popular", "growing", "emerging"])
    .default("featured"),
  genre: text(100).optional(),
});
export const homeSchema = z
  .object({
    utcOffsetMinutes: z
      .union([z.number(), z.string().regex(/^-?\d{1,3}$/)])
      .pipe(z.coerce.number().int().min(-720).max(840))
      .default(420),
  })
  .strict();
export const profileSchema = z
  .object({
    username: usernameSchema,
    displayName: text(100).min(1),
    bio: paragraph(500).default(""),
    avatarAssetId: z.uuid().nullable().optional(),
    coverAssetId: z.uuid().nullable().optional(),
  })
  .strict();
export const songPatchSchema = z
  .object({
    title: text(120).min(1).optional(),
    artist: text(120).min(1).optional(),
    genre: text(100).min(1).optional(),
    description: text(1000).optional(),
    visibility: z.enum(["public", "private"]).optional(),
    rightsConfirmed: z.boolean().optional(),
  })
  .strict()
  .refine((v) => Object.keys(v).length > 0);
export const heartbeatSchema = z
  .object({
    positionMs: z.number().int().min(0).max(86400000),
    playing: z.boolean(),
  })
  .strict();
export const playlistSchema = z
  .object({
    title: text(150).min(1),
    description: text(1000).default(""),
    visibility: z.enum(["public", "private"]).default("private"),
  })
  .strict();
export const playlistTrackSchema = z.object({ trackId: z.uuid() }).strict();
export const reportSchema = z
  .object({
    trackId: z.uuid().optional(),
    profileId: z.uuid().optional(),
    reason: z.enum(["copyright", "abuse", "spam", "other"]),
    details: text(1000).default(""),
  })
  .strict()
  .refine((v) => !!v.trackId !== !!v.profileId);
