import { HttpError } from "../utils/http-error.js";
const missing = () =>
  new HttpError(404, "RESOURCE_NOT_FOUND", "Content is unavailable.");
export const publicTrack =
  "t.visibility='public' AND t.status='active' AND u.profile_status='active' AND u.username IS NOT NULL";
const commentVisible =
  "c.status='active' AND author.profile_status='active' AND (c.parent_id IS NULL OR EXISTS(SELECT 1 FROM track_comments p JOIN users pu ON pu.id=p.user_id WHERE p.id=c.parent_id AND p.status<>'hidden' AND pu.profile_status='active'))";
export const notificationVisible = `actor.profile_status='active' AND
 ((n.type='follower' AND EXISTS(SELECT 1 FROM user_follows f WHERE f.follower_id=n.actor_id AND f.following_id=n.recipient_id)) OR
 (n.type<>'follower' AND ${publicTrack} AND (n.comment_id IS NULL OR
 EXISTS(SELECT 1 FROM track_comments c JOIN users author ON author.id=c.user_id WHERE c.id=n.comment_id AND ${commentVisible}))))`;
const notificationFrom = `FROM notifications n JOIN users me ON me.id=n.recipient_id JOIN users actor ON actor.id=n.actor_id
 LEFT JOIN private_tracks t ON t.id=n.track_id LEFT JOIN users u ON u.clerk_user_id=t.clerk_user_id`;
export const createSocialRepository = (pool) => {
  const one = async (sql, p = [], c = pool) => (await c.query(sql, p)).rows[0];
  const rows = async (sql, p = [], c = pool) => (await c.query(sql, p)).rows;
  const tx = async (fn) => {
    const c = await pool.connect();
    let open = false,
      broken = false;
    try {
      await c.query("BEGIN");
      open = true;
      await c.query("SET LOCAL lock_timeout='5s'");
      const value = await fn(c);
      await c.query("COMMIT");
      open = false;
      return value;
    } finally {
      if (open)
        try {
          await c.query("ROLLBACK");
        } catch {
          broken = true;
        }
      c.release(broken);
    }
  };
  const me = (owner, c = pool) =>
    one("SELECT id FROM users WHERE clerk_user_id=$1", [owner], c);
  const access = async (id, c = pool) => {
    const row = await one(
      `SELECT t.id FROM private_tracks t JOIN users u ON u.clerk_user_id=t.clerk_user_id WHERE t.id=$1 AND ${publicTrack} FOR SHARE OF t,u`,
      [id],
      c,
    );
    if (!row) throw missing();
  };
  const comment = async (id, c = pool) => {
    const row = await one(
      `SELECT c.* FROM track_comments c JOIN users author ON author.id=c.user_id WHERE c.id=$1 AND ${commentVisible} FOR SHARE OF c,author`,
      [id],
      c,
    );
    if (!row) throw missing();
    await access(row.track_id, c);
    return row;
  };
  const commentsFrom = `FROM track_comments c JOIN users author ON author.id=c.user_id JOIN users me ON me.clerk_user_id=$1 LEFT JOIN media_assets a ON a.id=author.avatar_asset_id`;
  return {
    tx,
    me,
    access,
    comment,
    commentContext: (owner, id) =>
      tx(async (c) => {
        const target = await comment(id, c);
        const root = await one(
          "SELECT p.id,p.content,p.status FROM track_comments p JOIN users author ON author.id=p.user_id WHERE p.id=$1 AND p.status<>'hidden' AND author.profile_status='active' FOR SHARE OF p,author",
          [target.parent_id ?? target.id],
          c,
        );
        if (!root) throw missing();
        return {
          trackId: target.track_id,
          rootId: root.id,
          content: root.status === "deleted" ? "" : root.content,
          deleted: root.status === "deleted",
          targetId: target.id,
        };
      }),
    snapshot: async (owner, mode, ids) =>
      tx(async (c) => {
        const user = await me(owner, c);
        if (!user) throw missing();
        await c.query("SELECT id FROM users WHERE id=$1 FOR UPDATE", [user.id]);
        await c.query(
          "DELETE FROM shorts_snapshots WHERE user_id=$1 AND (expires_at<NOW() OR id IN (SELECT id FROM shorts_snapshots WHERE user_id=$1 ORDER BY expires_at DESC OFFSET 4))",
          [user.id],
        );
        return one(
          "INSERT INTO shorts_snapshots(user_id,mode,track_ids) VALUES($1,$2,$3) RETURNING id",
          [user.id, mode, ids],
          c,
        );
      }),
    snapshotPage: async (owner, id, mode, offset, limit) => {
      const snap = await one(
        "SELECT s.* FROM shorts_snapshots s JOIN users me ON me.id=s.user_id WHERE s.id=$1 AND me.clerk_user_id=$2 AND s.mode=$3 AND expires_at>NOW()",
        [id, owner, mode],
      );
      if (!snap) throw new HttpError(410, "FEED_EXPIRED", "Refresh the feed.");
      // Filter visibility again on EVERY page. Scan snapshot positions, not mutable ranking.
      const found = await rows(
        `SELECT t.*,u.id AS uploader_id,u.username,u.display_name,a.public_id AS artwork_public_id,a.format AS artwork_format,a.resource_type AS artwork_resource_type,
    av.public_id AS avatar_public_id,av.format AS avatar_format,av.resource_type AS avatar_resource_type,
    EXISTS(SELECT 1 FROM track_likes l JOIN users me ON me.id=l.user_id WHERE me.clerk_user_id=$1 AND l.track_id=t.id) AS liked,
    EXISTS(SELECT 1 FROM saved_tracks s JOIN users me ON me.id=s.user_id WHERE me.clerk_user_id=$1 AND s.track_id=t.id) AS saved,
    EXISTS(SELECT 1 FROM user_follows f JOIN users me ON me.id=f.follower_id WHERE me.clerk_user_id=$1 AND f.following_id=u.id) AS following,
    (SELECT count(*) FROM track_likes WHERE track_id=t.id) AS like_count,
    (SELECT count(*) FROM track_comments c JOIN users author ON author.id=c.user_id WHERE c.track_id=t.id AND ${commentVisible}) AS comment_count,
    ordering.pos FROM unnest($2::uuid[]) WITH ORDINALITY ordering(id,pos) JOIN private_tracks t ON t.id=ordering.id JOIN users u ON u.clerk_user_id=t.clerk_user_id
    LEFT JOIN media_assets a ON a.id=t.artwork_asset_id LEFT JOIN media_assets av ON av.id=u.avatar_asset_id
    WHERE ordering.pos>$3 AND ${publicTrack} AND ($5<>'following' OR EXISTS(SELECT 1 FROM user_follows f JOIN users me ON me.id=f.follower_id WHERE me.clerk_user_id=$1 AND f.following_id=u.id)) ORDER BY ordering.pos LIMIT $4`,
        [owner, snap.track_ids, offset, limit + 1, mode],
      );
      return found;
    },
    comments: (owner, id, { limit, parentId, after }) =>
      tx(async (c) => {
        await access(id, c);
        if (parentId) {
          const parent = await one(
            "SELECT p.id FROM track_comments p JOIN users author ON author.id=p.user_id WHERE p.id=$1 AND p.track_id=$2 AND p.parent_id IS NULL AND p.status<>'hidden' AND author.profile_status='active' FOR SHARE OF p,author",
            [parentId, id],
            c,
          );
          if (!parent) throw missing();
        }
        const items = await rows(
          `SELECT c.id,c.parent_id,c.created_at,to_char(c.created_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS cursor_at,c.status,CASE WHEN c.status='deleted' THEN '' ELSE c.content END AS content,author.id AS author_id,author.username,author.display_name,a.public_id AS avatar_public_id,a.format AS avatar_format,a.resource_type AS avatar_resource_type,(c.user_id=me.id) AS is_self,
    (SELECT count(*) FROM comment_likes WHERE comment_id=c.id) AS like_count,EXISTS(SELECT 1 FROM comment_likes WHERE comment_id=c.id AND user_id=me.id) AS liked,
    (SELECT count(*) FROM track_comments r JOIN users ru ON ru.id=r.user_id WHERE r.parent_id=c.id AND r.status='active' AND ru.profile_status='active') AS reply_count
    ${commentsFrom} WHERE c.track_id=$2 AND c.parent_id IS NOT DISTINCT FROM $3::uuid AND author.profile_status='active' AND (c.status='active' OR (c.status='deleted' AND c.parent_id IS NULL AND EXISTS(SELECT 1 FROM track_comments r WHERE r.parent_id=c.id AND r.status='active')))
    AND ($4::timestamptz IS NULL OR (c.created_at,c.id)<($4::timestamptz,$5::uuid)) ORDER BY c.created_at DESC,c.id DESC LIMIT $6`,
          [
            owner,
            id,
            parentId ?? null,
            after?.at ?? null,
            after?.id ?? null,
            limit + 1,
          ],
          c,
        );
        const total = await one(
          `SELECT count(*) AS count FROM track_comments c JOIN users author ON author.id=c.user_id WHERE c.track_id=$1 AND ${commentVisible}`,
          [id],
          c,
        );
        return { items, total: Number(total.count) };
      }),
    addComment: (owner, trackId, content, parentId) =>
      tx(async (c) => {
        const user = await me(owner, c);
        if (!user) throw missing();
        await c.query("SELECT id FROM users WHERE id=$1 FOR UPDATE", [user.id]);
        if (parentId) {
          const parent = await comment(parentId, c);
          if (parent.parent_id)
            throw new HttpError(
              400,
              "REPLY_DEPTH",
              "Reply to the original comment.",
            );
          trackId = parent.track_id;
        }
        await access(trackId, c);
        const recent = await one(
          "SELECT count(*) AS count,bool_or(content=$2) AS duplicate FROM track_comments WHERE user_id=$1 AND created_at>clock_timestamp()-INTERVAL '1 minute'",
          [user.id, content],
          c,
        );
        if (Number(recent.count) >= 8 || recent.duplicate)
          throw new HttpError(
            429,
            "COMMENT_RATE_LIMITED",
            "Please wait before commenting again.",
          );
        return one(
          "INSERT INTO track_comments(track_id,user_id,parent_id,content) VALUES($1,$2,$3,$4) RETURNING id,track_id",
          [trackId, user.id, parentId ?? null, content],
          c,
        );
      }),
    deleteComment: (owner, id) =>
      tx(async (c) => {
        const row = await one(
          "SELECT c.*,u.clerk_user_id FROM track_comments c JOIN users u ON u.id=c.user_id WHERE c.id=$1 FOR UPDATE OF c",
          [id],
          c,
        );
        if (!row || row.clerk_user_id !== owner) throw missing();
        await access(row.track_id, c);
        await c.query(
          "UPDATE track_comments SET status='deleted',content='[deleted]',deleted_at=NOW(),updated_at=NOW() WHERE id=$1",
          [id],
        );
      }),
    likeComment: (owner, id, enabled) =>
      tx(async (c) => {
        await comment(id, c);
        const user = await me(owner, c);
        if (!user) throw missing();
        await c.query(
          enabled
            ? "INSERT INTO comment_likes(comment_id,user_id) VALUES($1,$2) ON CONFLICT DO NOTHING"
            : "DELETE FROM comment_likes WHERE comment_id=$1 AND user_id=$2",
          [id, user.id],
        );
      }),
    reportComment: (owner, id, input) =>
      tx(async (c) => {
        await comment(id, c);
        const user = await me(owner, c);
        if (!user) throw missing();
        await c.query(
          "INSERT INTO content_reports(reporter_id,comment_id,reason,details) VALUES($1,$2,$3,$4) ON CONFLICT DO NOTHING",
          [user.id, id, input.reason, input.details],
        );
        return { status: "pending" };
      }),
    notifications: (owner, { limit, unread, after }) =>
      rows(
        `SELECT n.id,n.type,n.track_id,n.comment_id,n.created_at,to_char(n.created_at AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS cursor_at,n.read_at,actor.id AS actor_id,actor.username,actor.display_name,a.public_id AS avatar_public_id,a.format AS avatar_format,a.resource_type AS avatar_resource_type,t.title ${notificationFrom} LEFT JOIN media_assets a ON a.id=actor.avatar_asset_id WHERE me.clerk_user_id=$1 AND ${notificationVisible} AND ($2::boolean=FALSE OR n.read_at IS NULL) AND ($3::timestamptz IS NULL OR (n.created_at,n.id)<($3::timestamptz,$4::uuid)) ORDER BY n.created_at DESC,n.id DESC LIMIT $5`,
        [
          owner,
          unread === "true",
          after?.at ?? null,
          after?.id ?? null,
          limit + 1,
        ],
      ),
    unread: async (owner) =>
      Number(
        (
          await one(
            `SELECT count(*) AS count ${notificationFrom} WHERE me.clerk_user_id=$1 AND n.read_at IS NULL AND ${notificationVisible}`,
            [owner],
          )
        ).count,
      ),
    read: async (owner, id) => {
      const result = await pool.query(
        `UPDATE notifications n SET read_at=COALESCE(read_at,NOW()) FROM users me WHERE me.id=n.recipient_id AND me.clerk_user_id=$1 ${id ? "AND n.id=$2" : ""} RETURNING n.id`,
        id ? [owner, id] : [owner],
      );
      if (id && !result.rowCount) throw missing();
    },
    preferences: async (owner, input) => {
      const user = await me(owner);
      if (!user) throw missing();
      if (input)
        await pool.query(
          `INSERT INTO notification_preferences(user_id,followers,comments,replies,likes,new_tracks) VALUES($1,COALESCE($2,TRUE),COALESCE($3,TRUE),COALESCE($4,TRUE),COALESCE($5,TRUE),COALESCE($6,TRUE)) ON CONFLICT(user_id) DO UPDATE SET followers=COALESCE($2,notification_preferences.followers),comments=COALESCE($3,notification_preferences.comments),replies=COALESCE($4,notification_preferences.replies),likes=COALESCE($5,notification_preferences.likes),new_tracks=COALESCE($6,notification_preferences.new_tracks)`,
          [
            user.id,
            input.followers ?? null,
            input.comments ?? null,
            input.replies ?? null,
            input.likes ?? null,
            input.newTracks ?? null,
          ],
        );
      return (
        (await one(
          'SELECT followers,comments,replies,likes,new_tracks AS "newTracks" FROM notification_preferences WHERE user_id=$1',
          [user.id],
        )) ?? {
          followers: true,
          comments: true,
          replies: true,
          likes: true,
          newTracks: true,
        }
      );
    },
  };
};
