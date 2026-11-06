import { HttpError } from "../utils/http-error.js";
import { recommendationQuery } from "./recommendation-query.js";
import { recommendationContext } from "../utils/listening-context.js";

const missing = () =>
  new HttpError(404, "RESOURCE_NOT_FOUND", "Content is unavailable.");
const pattern = (value) => `%${value.replace(/[\\%_]/g, "\\$&")}%`;
const PUBLIC =
  "t.visibility = 'public' AND t.status = 'active' AND u.username IS NOT NULL AND u.profile_status = 'active'";
const ACCESS = `(t.status = 'active' AND (t.clerk_user_id = $1 OR (${PUBLIC})))`;
const PROFILE = `u.id,u.username,u.display_name,u.bio,u.created_at,
  a.public_id AS avatar_public_id,a.format AS avatar_format,a.resource_type AS avatar_resource_type,
  c.public_id AS cover_public_id,c.format AS cover_format,c.resource_type AS cover_resource_type,
  (SELECT count(*) FROM user_follows WHERE following_id=u.id) AS follower_count,
  (SELECT count(*) FROM user_follows WHERE follower_id=u.id) AS following_count,
  (SELECT count(*) FROM private_tracks WHERE clerk_user_id=u.clerk_user_id AND visibility='public' AND status='active') AS song_count,
  EXISTS(SELECT 1 FROM user_follows f JOIN users me ON me.id=f.follower_id WHERE me.clerk_user_id=$1 AND f.following_id=u.id) AS following,
  (u.clerk_user_id=$1) AS is_self`;
const PROFILE_FROM = `FROM users u LEFT JOIN media_assets a ON a.id=u.avatar_asset_id LEFT JOIN media_assets c ON c.id=u.cover_asset_id`;
const TRACK = `t.*,u.username,u.display_name,u.id AS uploader_id,
  a.public_id AS artwork_public_id,a.format AS artwork_format,a.resource_type AS artwork_resource_type,
  EXISTS(SELECT 1 FROM track_likes l JOIN users me ON me.id=l.user_id WHERE me.clerk_user_id=$1 AND l.track_id=t.id) AS liked,
  EXISTS(SELECT 1 FROM saved_tracks s JOIN users me ON me.id=s.user_id WHERE me.clerk_user_id=$1 AND s.track_id=t.id) AS saved`;
const TRACK_FROM = `FROM private_tracks t JOIN users u ON u.clerk_user_id=t.clerk_user_id LEFT JOIN media_assets a ON a.id=t.artwork_asset_id`;
const RECOMMENDATIONS = recommendationQuery({ TRACK, TRACK_FROM, PUBLIC, ACCESS });

export const createCommunityRepository = (pool) => {
  const one = async (sql, params, client = pool) =>
    (await client.query(sql, params)).rows[0] || null;
  const rows = async (sql, params, client = pool) =>
    (await client.query(sql, params)).rows;
  const transaction = async (action) => {
    const client = await pool.connect();
    let open = false,
      broken = false;
    try {
      await client.query("BEGIN");
      open = true;
      await client.query("SET LOCAL lock_timeout = '5s'");
      const result = await action(client);
      await client.query("COMMIT");
      open = false;
      return result;
    } finally {
      if (open)
        try {
          await client.query("ROLLBACK");
        } catch {
          broken = true;
        }
      client.release(broken);
    }
  };
  const user = (owner) =>
    one(
      `INSERT INTO users(clerk_user_id) VALUES ($1) ON CONFLICT (clerk_user_id)
    DO UPDATE SET clerk_user_id=EXCLUDED.clerk_user_id RETURNING *`,
      [owner],
    );
  const track = (owner, id, client = pool) =>
    one(
      `SELECT ${TRACK},m.public_id AS audio_public_id,m.format AS audio_format,m.resource_type AS audio_resource_type
    ${TRACK_FROM} JOIN media_assets m ON m.id=t.audio_asset_id WHERE t.id=$2 AND ${ACCESS}`,
      [owner, id],
      client,
    );
  const repo = {
    user,
    me: async (owner) => {
      await user(owner);
      return one(`SELECT ${PROFILE} ${PROFILE_FROM} WHERE u.clerk_user_id=$1`, [
        owner,
      ]);
    },
    profile: (owner, username) =>
      one(
        `SELECT ${PROFILE} ${PROFILE_FROM} WHERE u.username=$2 AND u.profile_status='active'`,
        [owner, username],
      ),
    updateProfile: (owner, input) =>
      transaction(async (client) => {
        const me = await one(
          "SELECT id FROM users WHERE clerk_user_id=$1 FOR UPDATE",
          [owner],
          client,
        );
        if (!me) throw missing();
        const assets = [input.avatarAssetId, input.coverAssetId].filter(
          Boolean,
        );
        const initial = await rows(
          "SELECT public_id FROM media_assets WHERE id=ANY($1::uuid[]) AND clerk_user_id=$2 ORDER BY public_id",
          [assets, owner],
          client,
        );
        for (const asset of initial)
          await client.query(
            "SELECT pg_advisory_xact_lock(hashtextextended($1,0))",
            [asset.public_id],
          );
        for (const id of assets) {
          const asset = await one(
            "SELECT id FROM media_assets WHERE id=$1 AND clerk_user_id=$2 AND media_type='artwork' FOR KEY SHARE",
            [id, owner],
            client,
          );
          if (!asset) throw missing();
        }
        await client.query(
          `UPDATE users SET username=$2,display_name=$3,bio=$4,
        avatar_asset_id=CASE WHEN $5 THEN $6::uuid ELSE avatar_asset_id END,
        cover_asset_id=CASE WHEN $7 THEN $8::uuid ELSE cover_asset_id END,updated_at=NOW() WHERE id=$9 AND clerk_user_id=$1`,
          [
            owner,
            input.username,
            input.displayName,
            input.bio,
            "avatarAssetId" in input,
            input.avatarAssetId || null,
            "coverAssetId" in input,
            input.coverAssetId || null,
            me.id,
          ],
        );
      }),
    searchUsers: (owner, { q, limit, offset }) => {
      const normalized = q.replace(/^@/, "").toLowerCase();
      return rows(
        `SELECT ${PROFILE} ${PROFILE_FROM} WHERE u.username IS NOT NULL AND u.profile_status='active'
        AND (u.username ILIKE $2 ESCAPE '\\' OR u.display_name ILIKE $2 ESCAPE '\\')
        ORDER BY CASE WHEN u.username=$3 THEN 0 WHEN u.username LIKE $4 ESCAPE '\\' THEN 1 WHEN u.username ILIKE $2 ESCAPE '\\' THEN 2 ELSE 3 END,u.username,u.id LIMIT $5 OFFSET $6`,
        [
          owner,
          pattern(normalized),
          normalized,
          pattern(normalized).slice(1),
          limit + 1,
          offset,
        ],
      );
    },
    follow: (owner, id, enabled) =>
      transaction(async (client) => {
        const me = await one(
          "SELECT id FROM users WHERE clerk_user_id=$1",
          [owner],
          client,
        );
        const target = await one(
          "SELECT id FROM users WHERE id=$1 AND username IS NOT NULL AND profile_status='active' FOR KEY SHARE",
          [id],
          client,
        );
        if (!me || !target) throw missing();
        if (me.id === id)
          throw new HttpError(
            400,
            "CANNOT_FOLLOW_SELF",
            "You cannot follow yourself.",
          );
        if (enabled)
          await client.query(
            "INSERT INTO user_follows(follower_id,following_id) VALUES ($1,$2) ON CONFLICT DO NOTHING",
            [me.id, id],
          );
        else
          await client.query(
            "DELETE FROM user_follows WHERE follower_id=$1 AND following_id=$2",
            [me.id, id],
          );
      }),
    connections: async (owner, id, kind, { limit, offset }) => {
      if (
        !(await one(
          "SELECT id FROM users WHERE id=$1 AND username IS NOT NULL AND profile_status='active'",
          [id],
        ))
      )
        throw missing();
      const [source, target] =
        kind === "followers"
          ? ["following_id", "follower_id"]
          : ["follower_id", "following_id"];
      return rows(
        `SELECT ${PROFILE} ${PROFILE_FROM} JOIN user_follows f ON f.${target}=u.id
        WHERE f.${source}=$2 AND u.profile_status='active' AND u.username IS NOT NULL ORDER BY f.created_at DESC,u.id LIMIT $3 OFFSET $4`,
        [owner, id, limit + 1, offset],
      );
    },
    creators: (owner, { mode, limit, offset }) => {
      const order = {
        new: "created_at DESC",
        popular: "follower_count DESC",
        growing: "recent_followers DESC",
        featured: "(recent_followers + recent_plays) DESC",
        emerging: "follower_count ASC,recent_plays DESC,created_at DESC",
      }[mode];
      return rows(
        `WITH candidates AS (SELECT ${PROFILE},
        (SELECT count(*) FROM user_follows WHERE following_id=u.id AND created_at>NOW()-INTERVAL '7 days') AS recent_followers,
        (SELECT count(*) FROM valid_play_events e JOIN private_tracks t ON t.id=e.track_id WHERE t.clerk_user_id=u.clerk_user_id AND t.visibility='public' AND t.status='active' AND e.created_at>NOW()-INTERVAL '7 days') AS recent_plays
        ${PROFILE_FROM} WHERE u.username IS NOT NULL AND u.profile_status='active'
        AND EXISTS(SELECT 1 FROM private_tracks WHERE clerk_user_id=u.clerk_user_id AND visibility='public' AND status='active')
        ) SELECT * FROM candidates ORDER BY ${order},id LIMIT $2 OFFSET $3`,
        [owner, limit + 1, offset],
      );
    },
    tracks: (
      owner,
      {
        q = "",
        genre,
        limit,
        offset,
        username,
        feed = false,
        recent = false,
        saved = false,
        liked = false,
      },
    ) => {
      const params = [owner];
      const where = [saved || liked || recent ? ACCESS : PUBLIC];
      const bind = (v) => {
        params.push(v);
        return `$${params.length}`;
      };
      if (q)
        where.push(
          `concat_ws(' ',t.title,t.artist,t.genre) ILIKE ${bind(pattern(q))} ESCAPE '\\'`,
        );
      if (genre) where.push(`lower(t.genre)=lower(${bind(genre)})`);
      if (username) where.push(`u.username=${bind(username)}`);
      if (feed)
        where.push(
          "EXISTS(SELECT 1 FROM user_follows f JOIN users me ON me.id=f.follower_id WHERE me.clerk_user_id=$1 AND f.following_id=u.id)",
        );
      if (saved)
        where.push(
          "EXISTS(SELECT 1 FROM saved_tracks s JOIN users me ON me.id=s.user_id WHERE me.clerk_user_id=$1 AND s.track_id=t.id)",
        );
      if (liked)
        where.push(
          "EXISTS(SELECT 1 FROM track_likes l JOIN users me ON me.id=l.user_id WHERE me.clerk_user_id=$1 AND l.track_id=t.id)",
        );
      if (recent)
        where.push(
          "EXISTS(SELECT 1 FROM playback_sessions ps JOIN users me ON me.id=ps.user_id WHERE me.clerk_user_id=$1 AND ps.track_id=t.id AND ps.credited_ms>0)",
        );
      const order = recent
        ? "(SELECT max(ps.started_at) FROM playback_sessions ps JOIN users me ON me.id=ps.user_id WHERE me.clerk_user_id=$1 AND ps.track_id=t.id) DESC,"
        : "";
      const resume = recent
        ? `,(SELECT ps.last_position_ms FROM playback_sessions ps JOIN users me ON me.id=ps.user_id WHERE me.clerk_user_id=$1 AND ps.track_id=t.id ORDER BY ps.started_at DESC,ps.id LIMIT 1) AS resume_position_ms`
        : "";
      return rows(
        `SELECT ${TRACK}${resume} ${TRACK_FROM} WHERE ${where.join(" AND ")} ORDER BY ${order}t.created_at DESC,t.id DESC LIMIT ${bind(limit + 1)} OFFSET ${bind(offset)}`,
        params,
      );
    },
    recommendations: (owner, { utcOffsetMinutes = 420, at = new Date() } = {}) =>
      rows(RECOMMENDATIONS, [
        owner,
        at,
        utcOffsetMinutes,
        recommendationContext(at, utcOffsetMinutes).daypart,
      ]),
    genres: (owner) =>
      rows(
        `SELECT t.genre,count(*) AS song_count ${TRACK_FROM} WHERE ${PUBLIC} GROUP BY t.genre ORDER BY lower(t.genre)`,
        [],
      ),
    trending: (owner, { period, limit, offset }) =>
      rows(
        `WITH cutoff AS (SELECT CASE $2::text WHEN 'today' THEN date_trunc('day',NOW() AT TIME ZONE 'Asia/Ho_Chi_Minh') AT TIME ZONE 'Asia/Ho_Chi_Minh'
      WHEN 'week' THEN NOW()-INTERVAL '7 days' WHEN 'month' THEN NOW()-INTERVAL '30 days' ELSE '1970-01-01'::timestamptz END AS at),
      plays AS (SELECT track_id,count(*)::float AS valid_plays,count(DISTINCT user_id)::float AS unique_listeners FROM valid_play_events,cutoff WHERE created_at>=cutoff.at GROUP BY track_id),
      likes AS (SELECT track_id,count(*)::float AS like_count FROM track_likes,cutoff WHERE created_at>=cutoff.at GROUP BY track_id),
      saves AS (SELECT track_id,count(*)::float AS save_count FROM saved_tracks,cutoff WHERE created_at>=cutoff.at GROUP BY track_id),
      stats AS (SELECT ${TRACK},COALESCE(p.valid_plays,0) AS valid_plays,COALESCE(p.unique_listeners,0) AS unique_listeners,
        COALESCE(l.like_count,0) AS like_count,COALESCE(s.save_count,0) AS save_count,
        (SELECT count(*) FROM playback_sessions ps,cutoff WHERE ps.track_id=t.id AND ps.started_at>=cutoff.at) AS total_plays
        ${TRACK_FROM} LEFT JOIN plays p ON p.track_id=t.id LEFT JOIN likes l ON l.track_id=t.id LEFT JOIN saves s ON s.track_id=t.id WHERE ${PUBLIC}),
      ranked AS (SELECT *,0.45*valid_plays/GREATEST(MAX(valid_plays) OVER(),1) + 0.25*unique_listeners/GREATEST(MAX(unique_listeners) OVER(),1)
        + 0.20*like_count/GREATEST(MAX(like_count) OVER(),1) + 0.10*save_count/GREATEST(MAX(save_count) OVER(),1) AS score FROM stats)
      SELECT * FROM ranked ORDER BY score DESC,created_at DESC,id DESC LIMIT $3 OFFSET $4`,
        [owner, period, limit + 1, offset],
      ),
    track,
    patchTrack: (owner, id, input) =>
      transaction(async (client) => {
        const row = await one(
          "SELECT * FROM private_tracks WHERE id=$1 AND clerk_user_id=$2 AND status='active' FOR UPDATE",
          [id, owner],
          client,
        );
        if (!row) throw missing();
        if (input.visibility === "public") {
          const me = await one(
            "SELECT username FROM users WHERE clerk_user_id=$1 AND profile_status='active'",
            [owner],
            client,
          );
          if (!me?.username)
            throw new HttpError(
              409,
              "PROFILE_REQUIRED",
              "Create your public profile first.",
            );
          if (!input.rightsConfirmed)
            throw new HttpError(
              400,
              "RIGHTS_REQUIRED",
              "Confirm your right to share this recording.",
            );
        }
        return one(
          `UPDATE private_tracks SET title=COALESCE($3,title),artist=COALESCE($4,artist),genre=COALESCE($5,genre),description=COALESCE($6,description),
        visibility=COALESCE($7,visibility),rights_confirmed_at=CASE WHEN $8 THEN NOW() ELSE rights_confirmed_at END,updated_at=NOW() WHERE id=$1 AND clerk_user_id=$2 RETURNING id`,
          [
            id,
            owner,
            input.title ?? null,
            input.artist ?? null,
            input.genre ?? null,
            input.description ?? null,
            input.visibility ?? null,
            input.rightsConfirmed === true,
          ],
          client,
        );
      }),
    deleteTrack: (owner, id) =>
      transaction(async (client) => {
        const row = await one(
          "SELECT * FROM private_tracks WHERE id=$1 AND clerk_user_id=$2 FOR UPDATE",
          [id, owner],
          client,
        );
        if (!row)
          return one(
            "SELECT track_id AS id FROM track_deletions WHERE track_id=$1 AND clerk_user_id=$2",
            [id, owner],
            client,
          );
        await client.query(
          "INSERT INTO track_deletions(track_id,clerk_user_id) VALUES ($1,$2) ON CONFLICT DO NOTHING",
          [id, owner],
        );
        await client.query(
          "DELETE FROM private_tracks WHERE id=$1 AND clerk_user_id=$2",
          [id, owner],
        );
        for (const assetId of [row.audio_asset_id, row.artwork_asset_id].filter(
          Boolean,
        ))
          await client.query(
            "INSERT INTO media_cleanup_jobs(asset_id,track_id,clerk_user_id) VALUES ($1,$2,$3) ON CONFLICT DO NOTHING",
            [assetId, id, owner],
          );
        return { id };
      }),
    interact: (owner, id, kind, enabled) =>
      transaction(async (client) => {
        if (!(await track(owner, id, client))) throw missing();
        // Lock the track to serialize with visibility/delete changes.
        await client.query(
          "SELECT id FROM private_tracks WHERE id=$1 FOR SHARE",
          [id],
        );
        if (!(await track(owner, id, client))) throw missing();
        const me = await one(
          "SELECT id FROM users WHERE clerk_user_id=$1",
          [owner],
          client,
        );
        const table = kind === "like" ? "track_likes" : "saved_tracks";
        if (enabled)
          await client.query(
            `INSERT INTO ${table}(user_id,track_id) VALUES ($1,$2) ON CONFLICT DO NOTHING`,
            [me.id, id],
          );
        else
          await client.query(
            `DELETE FROM ${table} WHERE user_id=$1 AND track_id=$2`,
            [me.id, id],
          );
        if (kind === "like") {
          if (enabled)
            await client.query(
              "INSERT INTO private_track_favorites(clerk_user_id,track_id) SELECT clerk_user_id,id FROM private_tracks WHERE id=$1 AND clerk_user_id=$2 ON CONFLICT DO NOTHING",
              [id, owner],
            );
          else
            await client.query(
              "DELETE FROM private_track_favorites WHERE track_id=$1 AND clerk_user_id=$2",
              [id, owner],
            );
        }
      }),
    startPlayback: (owner, id, duration) =>
      transaction(async (client) => {
        await client.query(
          "SELECT id FROM private_tracks WHERE id=$1 FOR SHARE",
          [id],
        );
        if (!(await track(owner, id, client))) throw missing();
        const me = await one(
          "SELECT id FROM users WHERE clerk_user_id=$1",
          [owner],
          client,
        );
        return one(
          `INSERT INTO playback_sessions(user_id,track_id,threshold_ms) VALUES ($1,$2,$3) RETURNING id,threshold_ms`,
          [
            me.id,
            id,
            Math.max(1, Math.ceil(Math.min(30, duration / 2) * 1000)),
          ],
          client,
        );
      }),
    heartbeat: (owner, id, input) =>
      transaction(async (client) => {
        const session = await one(
          `SELECT ps.*,clock_timestamp() AS server_now FROM playback_sessions ps JOIN users me ON me.id=ps.user_id
        WHERE ps.id=$1 AND me.clerk_user_id=$2 AND ps.started_at>NOW()-INTERVAL '2 hours' FOR UPDATE OF ps`,
          [id, owner],
          client,
        );
        if (!session || !(await track(owner, session.track_id, client)))
          throw missing();
        const elapsed = Math.max(
          0,
          new Date(session.server_now) - new Date(session.last_heartbeat_at),
        );
        const delta = Math.max(0, input.positionMs - session.last_position_ms);
        const credit = input.playing
          ? Math.floor(Math.min(elapsed, 20000, delta))
          : 0;
        const total = Math.min(
          session.threshold_ms,
          session.credited_ms + credit,
        );
        await client.query(
          "UPDATE playback_sessions SET credited_ms=$2,last_position_ms=$3,last_heartbeat_at=clock_timestamp() WHERE id=$1",
          [id, total, input.positionMs],
        );
        if (total >= session.threshold_ms) {
          await client.query(
            "SELECT pg_advisory_xact_lock(hashtextextended($1,0))",
            [`${session.user_id}:${session.track_id}`],
          );
          const event = await one(
            `INSERT INTO valid_play_events(session_id,user_id,track_id,dedup_bucket)
          SELECT $1,$2,$3,floor(extract(epoch FROM NOW())/1800)::bigint
          WHERE NOT EXISTS(SELECT 1 FROM valid_play_events WHERE user_id=$2 AND track_id=$3 AND created_at>NOW()-INTERVAL '30 minutes')
          ON CONFLICT DO NOTHING RETURNING session_id`,
            [id, session.user_id, session.track_id],
            client,
          );
          if (event)
            await client.query(
              "UPDATE playback_sessions SET is_valid=TRUE WHERE id=$1",
              [id],
            );
        }
        return { creditedMs: total, isValid: total >= session.threshold_ms };
      }),
    duration: (id, seconds) =>
      pool.query("UPDATE private_tracks SET duration_seconds=$2 WHERE id=$1", [
        id,
        seconds,
      ]),
    playlists: (owner, { limit, offset, username }) =>
      rows(
        `SELECT p.id,p.title,p.description,p.is_public,p.created_at,u.username,u.id AS owner_id,(u.clerk_user_id=$1) AS is_self,
      (SELECT count(*) FROM playlist_tracks pt JOIN private_tracks t ON t.id=pt.track_id JOIN users creator ON creator.clerk_user_id=t.clerk_user_id
       WHERE pt.playlist_id=p.id AND t.status='active' AND (t.clerk_user_id=$1 OR (t.visibility='public' AND creator.username IS NOT NULL AND creator.profile_status='active'))) AS song_count
      FROM playlists p JOIN users u ON u.id=p.user_id WHERE ${username ? "u.username=$4 AND p.is_public=TRUE AND u.profile_status='active'" : "u.clerk_user_id=$1"} ORDER BY p.created_at DESC,p.id LIMIT $2 OFFSET $3`,
        [owner, limit + 1, offset, ...(username ? [username] : [])],
      ),
    createPlaylist: async (owner, input) => {
      const me = await user(owner);
      return one(
        "INSERT INTO playlists(user_id,title,description,is_public) VALUES ($1,$2,$3,$4) RETURNING id",
        [me.id, input.title, input.description, input.visibility === "public"],
      );
    },
    searchPlaylists: (owner, { q, limit, offset }) =>
      rows(
        `SELECT p.id,p.title,p.description,p.is_public,u.username,FALSE AS is_self,
      (SELECT count(*) FROM playlist_tracks pt JOIN private_tracks t ON t.id=pt.track_id JOIN users creator ON creator.clerk_user_id=t.clerk_user_id
       WHERE pt.playlist_id=p.id AND t.status='active' AND t.visibility='public' AND creator.username IS NOT NULL AND creator.profile_status='active') AS song_count
      FROM playlists p JOIN users u ON u.id=p.user_id WHERE p.is_public=TRUE AND u.username IS NOT NULL AND u.profile_status='active'
      AND concat_ws(' ',p.title,p.description) ILIKE $1 ESCAPE '\\' ORDER BY p.created_at DESC,p.id LIMIT $2 OFFSET $3`,
        [pattern(q), limit + 1, offset],
      ),
    playlist: (owner, id) =>
      one(
        `SELECT p.*,u.username,(u.clerk_user_id=$1) AS is_self FROM playlists p JOIN users u ON u.id=p.user_id
      WHERE p.id=$2 AND (u.clerk_user_id=$1 OR (p.is_public=TRUE AND u.username IS NOT NULL AND u.profile_status='active'))`,
        [owner, id],
      ),
    playlistTracks: (owner, id, { limit, offset }) =>
      rows(
        `SELECT ${TRACK} ${TRACK_FROM} JOIN playlist_tracks pt ON pt.track_id=t.id WHERE pt.playlist_id=$2 AND ${ACCESS} ORDER BY pt.position,t.id LIMIT $3 OFFSET $4`,
        [owner, id, limit + 1, offset],
      ),
    changePlaylist: (owner, id, input, remove = false) =>
      transaction(async (client) => {
        const playlist = await one(
          "SELECT p.id FROM playlists p JOIN users u ON u.id=p.user_id WHERE p.id=$1 AND u.clerk_user_id=$2 FOR UPDATE OF p",
          [id, owner],
          client,
        );
        if (!playlist) throw missing();
        if (!input) {
          await client.query("DELETE FROM playlists WHERE id=$1", [id]);
          return;
        }
        if (remove) {
          await client.query(
            "DELETE FROM playlist_tracks WHERE playlist_id=$1 AND track_id=$2",
            [id, input.trackId],
          );
          return;
        }
        if (!(await track(owner, input.trackId, client))) throw missing();
        await client.query(
          `INSERT INTO playlist_tracks(playlist_id,track_id,position) SELECT $1,$2,COALESCE(max(position),-1)+1 FROM playlist_tracks WHERE playlist_id=$1 ON CONFLICT (playlist_id,track_id) DO NOTHING`,
          [id, input.trackId],
        );
      }),
    report: (owner, input) =>
      transaction(async (client) => {
        if (input.trackId && !(await track(owner, input.trackId, client)))
          throw missing();
        if (
          input.profileId &&
          !(await one(
            "SELECT id FROM users WHERE id=$1 AND username IS NOT NULL AND profile_status='active'",
            [input.profileId],
            client,
          ))
        )
          throw missing();
        const me = await one(
          "SELECT id FROM users WHERE clerk_user_id=$1",
          [owner],
          client,
        );
        await client.query(
          "INSERT INTO content_reports(reporter_id,track_id,profile_id,reason,details) VALUES ($1,$2,$3,$4,$5) ON CONFLICT DO NOTHING",
          [
            me.id,
            input.trackId || null,
            input.profileId || null,
            input.reason,
            input.details,
          ],
        );
      }),
  };
  return repo;
};
