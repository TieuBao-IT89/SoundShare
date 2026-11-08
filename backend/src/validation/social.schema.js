import { z } from "zod";
export const cursorPage = z
  .object({
    limit: z.coerce.number().int().min(1).max(30).default(15),
    cursor: z
      .string()
      .max(500)
      .regex(/^[A-Za-z0-9_-]+$/)
      .optional(),
  })
  .strict();
export const feedSchema = cursorPage.extend({
  mode: z.enum(["for-you", "following", "trending"]).default("for-you"),
});
export const commentPage = cursorPage.extend({ parentId: z.uuid().optional() });
export const commentSchema = z
  .object({
    content: z
      .string()
      .trim()
      .min(1)
      .max(1000)
      .refine((v) => !/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(v)),
  })
  .strict();
export const inboxSchema = cursorPage.extend({
  unread: z.enum(["true", "false"]).default("false"),
});
export const preferencesSchema = z
  .object({
    followers: z.boolean().optional(),
    comments: z.boolean().optional(),
    replies: z.boolean().optional(),
    likes: z.boolean().optional(),
    newTracks: z.boolean().optional(),
  })
  .strict()
  .refine((v) => Object.keys(v).length > 0);
export const commentReportSchema = z
  .object({
    reason: z.enum(["copyright", "abuse", "spam", "other"]),
    details: z
      .string()
      .trim()
      .max(1000)
      .refine((v) => !/[\u0000-\u001f\u007f]/.test(v))
      .default(""),
  })
  .strict();
