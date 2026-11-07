import { z } from "zod";
import { HttpError } from "../utils/http-error.js";
import {
  rankRecommendations,
  recommendationContext,
} from "./recommendation.service.js";
const encode = (v) => Buffer.from(JSON.stringify(v)).toString("base64url");
const keyset = z
  .object({
    at: z.iso.datetime({ offset: true }),
    id: z.uuid(),
    scope: z.string().max(100),
  })
  .strict();
const feedCursor = z
  .object({ snapshot: z.uuid(), offset: z.number().int().min(0).max(200) })
  .strict();
const decode = (value, schema) => {
  try {
    return schema.parse(
      JSON.parse(Buffer.from(value, "base64url").toString("utf8")),
    );
  } catch {
    throw new HttpError(400, "INVALID_CURSOR", "Invalid cursor.");
  }
};
export const createSocialService = ({
  repository: r,
  communityRepository: community,
  storage,
}) => {
  const access = (row, p) =>
    row[`${p}_public_id`]
      ? storage.createAccess({
          public_id: row[`${p}_public_id`],
          format: row[`${p}_format`],
          resource_type: row[`${p}_resource_type`],
        })
      : null;
  const actor = (row) => ({
    id: row.author_id ?? row.actor_id,
    username: row.username,
    displayName: row.display_name || row.username || "",
    avatar: access(row, "avatar"),
  });
  const song = (row) => ({
    id: row.id,
    title: row.title,
    artist: row.artist,
    genre: row.genre,
    description: row.description,
    visibility: "public",
    community: true,
    artwork: access(row, "artwork"),
    durationSeconds: row.duration_seconds,
    previewStartMs: 0,
    previewDurationMs: Math.min(
      30000,
      Math.floor((row.duration_seconds || 30) * 1000),
    ),
    uploader: {
      id: row.uploader_id,
      username: row.username,
      displayName: row.display_name || row.username,
      avatar: access(row, "avatar"),
    },
    liked: !!row.liked,
    saved: !!row.saved,
    following: !!row.following,
    likeCount: Number(row.like_count || 0),
    commentCount: Number(row.comment_count || 0),
  });
  const after = (cursor, scope) => {
    if (!cursor) return undefined;
    const value = decode(cursor, keyset);
    if (value.scope !== scope)
      throw new HttpError(400, "INVALID_CURSOR", "Invalid cursor.");
    return value;
  };
  const page = (items, limit, map, scope) => ({
    items: items.slice(0, limit).map(map),
    nextCursor:
      items.length > limit
        ? encode({
            at:
              items[limit - 1].cursor_at ??
              new Date(items[limit - 1].created_at).toISOString(),
            id: items[limit - 1].id,
            scope,
          })
        : null,
  });
  const actions = {
    feed: async (owner, input) => {
      let cursor;
      if (input.cursor) cursor = decode(input.cursor, feedCursor);
      else {
        await community.user(owner);
        let ids;
        if (input.mode === "for-you") {
          const at = new Date();
          ids = rankRecommendations(
            await community.recommendations(owner, { at }),
            recommendationContext(at, 420),
            200,
          ).items.map((v) => v.id);
        } else {
          const filters = { limit: 199, offset: 0 };
          ids = (
            input.mode === "following"
              ? await community.tracks(owner, { ...filters, feed: true })
              : await community.trending(owner, { ...filters, period: "week" })
          )
            .map((v) => v.id)
            .slice(0, 200);
        }
        const snap = await r.snapshot(owner, input.mode, [...new Set(ids)]);
        cursor = { snapshot: snap.id, offset: 0 };
      }
      const rows = await r.snapshotPage(
        owner,
        cursor.snapshot,
        input.mode,
        cursor.offset,
        input.limit,
      );
      return {
        items: rows.slice(0, input.limit).map(song),
        nextCursor:
          rows.length > input.limit
            ? encode({
                snapshot: cursor.snapshot,
                offset: Number(rows[input.limit - 1].pos),
              })
            : null,
      };
    },
    song: async (owner, id) => {
      await community.user(owner);
      const snap = await r.snapshot(owner, "for-you", [id]);
      const rows = await r.snapshotPage(owner, snap.id, "for-you", 0, 1);
      if (!rows.length)
        throw new HttpError(
          404,
          "RESOURCE_NOT_FOUND",
          "Content is unavailable.",
        );
      return song(rows[0]);
    },
    comments: async (owner, id, input) => {
      await community.user(owner);
      const scope = `comments:${id}:${input.parentId ?? ""}`;
      const result = await r.comments(owner, id, {
        ...input,
        after: after(input.cursor, scope),
      });
      return {
        ...page(
          result.items,
          input.limit,
          (row) => ({
            id: row.id,
            parentId: row.parent_id,
            content: row.content,
            deleted: row.status === "deleted",
            createdAt: row.created_at,
            author: actor(row),
            isSelf: row.is_self,
            likeCount: Number(row.like_count),
            liked: row.liked,
            replyCount: Number(row.reply_count),
          }),
          scope,
        ),
        total: result.total,
      };
    },
    addComment: async (owner, id, input) => {
      await community.user(owner);
      return r.addComment(owner, id, input.content);
    },
    reply: async (owner, id, input) => {
      await community.user(owner);
      return r.addComment(owner, null, input.content, id);
    },
    commentContext: (owner, id) => r.commentContext(owner, id),
    deleteComment: (owner, id) => r.deleteComment(owner, id),
    likeComment: async (owner, id, enabled) => {
      await community.user(owner);
      return r.likeComment(owner, id, enabled);
    },
    reportComment: async (owner, id, input) => {
      await community.user(owner);
      return r.reportComment(owner, id, input);
    },
    notifications: async (owner, input) =>
      page(
        await r.notifications(owner, {
          ...input,
          after: after(input.cursor, "notifications"),
        }),
        input.limit,
        (row) => ({
          id: row.id,
          type: row.type,
          trackId: row.track_id,
          commentId: row.comment_id,
          title: row.title,
          actor: actor(row),
          read: !!row.read_at,
          createdAt: row.created_at,
        }),
        "notifications",
      ),
    unread: async (owner) => ({ count: await r.unread(owner) }),
    read: (owner, id) => r.read(owner, id),
    preferences: async (owner, input) => {
      await community.user(owner);
      return r.preferences(owner, input);
    },
  };
  return Object.fromEntries(
    Object.entries(actions).map(([name, action]) => [
      name,
      async (...args) => {
        try {
          return await action(...args);
        } catch (error) {
          if (error instanceof HttpError) throw error;
          throw new HttpError(
            503,
            "SOCIAL_UNAVAILABLE",
            "Community is temporarily unavailable.",
          );
        }
      },
    ]),
  );
};
