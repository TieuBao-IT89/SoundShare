import { Router } from "express";
import { z } from "zod";
import { parse } from "../validation/track.schema.js";
import {
  feedSchema,
  commentPage,
  commentSchema,
  inboxSchema,
  preferencesSchema,
  commentReportSchema,
} from "../validation/social.schema.js";
import { createRateLimit } from "../middleware/upload-limits.middleware.js";
import { communityController as controller } from "../controllers/community.controller.js";
export const createSocialRouter = ({ service: s, requireAuth }) => {
  const router = Router();
  router.use((req, res, next) => {
    const path = req.path;
    if (
      path === "/shorts" ||
      path.startsWith("/shorts/") ||
      path === "/notifications" ||
      path.startsWith("/notifications/") ||
      path.startsWith("/community/comments/") ||
      /^\/community\/songs\/[^/]+\/comments$/.test(path)
    )
      return next();
    return next("router");
  });
  router.use(requireAuth);
  router.use((req, res, next) => {
    res.set("Cache-Control", "no-store");
    next();
  });
  const none = z.object({}).strict(),
    id = z.object({ id: z.uuid() }).strict();
  const validate =
    (query = none, body = z.undefined(), params = none) =>
    (req, res, next) => {
      req.validated = {
        ...parse(query, req.query),
        ...parse(body, req.body),
        ...parse(params, req.params),
      };
      next();
    };
  const write = createRateLimit({ limit: 30, windowMs: 60000 });
  const read = createRateLimit({ limit: 120, windowMs: 60000 });
  router.use(read);
  router.get(
    "/shorts/feed",
    validate(feedSchema),
    controller((o, i) => s.feed(o, i)),
  );
  router.get(
    "/shorts/songs/:id",
    validate(none, z.undefined(), id),
    controller((o, i) => s.song(o, i.id)),
  );
  router.get(
    "/community/songs/:id/comments",
    validate(commentPage, z.undefined(), id),
    controller((o, i) => s.comments(o, i.id, i)),
  );
  router.get(
    "/community/comments/:id",
    validate(none, z.undefined(), id),
    controller((o, i) => s.commentContext(o, i.id)),
  );
  router.post(
    "/community/songs/:id/comments",
    write,
    validate(none, commentSchema, id),
    controller((o, i) => s.addComment(o, i.id, i), { status: 201 }),
  );
  router.post(
    "/community/comments/:id/replies",
    write,
    validate(none, commentSchema, id),
    controller((o, i) => s.reply(o, i.id, i), { status: 201 }),
  );
  router.delete(
    "/community/comments/:id",
    write,
    validate(none, z.undefined(), id),
    controller((o, i) => s.deleteComment(o, i.id), {
      status: 204,
      empty: true,
    }),
  );
  for (const [method, enabled] of [
    ["put", true],
    ["delete", false],
  ])
    router[method](
      "/community/comments/:id/like",
      write,
      validate(none, z.undefined(), id),
      controller((o, i) => s.likeComment(o, i.id, enabled), {
        status: 204,
        empty: true,
      }),
    );
  router.post(
    "/community/comments/:id/report",
    createRateLimit({ limit: 10 }),
    validate(none, commentReportSchema, id),
    controller((o, i) => s.reportComment(o, i.id, i), { status: 202 }),
  );
  router.get(
    "/notifications",
    validate(inboxSchema),
    controller((o, i) => s.notifications(o, i)),
  );
  router.get(
    "/notifications/unread-count",
    validate(),
    controller((o) => s.unread(o)),
  );
  router.get(
    "/notifications/preferences",
    validate(),
    controller((o) => s.preferences(o)),
  );
  router.patch(
    "/notifications/preferences",
    validate(none, preferencesSchema),
    controller((o, i) => s.preferences(o, i)),
  );
  router.patch(
    "/notifications/read-all",
    validate(),
    controller((o) => s.read(o), { status: 204, empty: true }),
  );
  router.patch(
    "/notifications/:id/read",
    validate(none, z.undefined(), id),
    controller((o, i) => s.read(o, i.id), { status: 204, empty: true }),
  );
  return router;
};
