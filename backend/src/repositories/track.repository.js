import { HttpError } from "../utils/http-error.js";

export const createTrackRepository = (pool) => {
  const lookup = async (id, owner, client = pool) => (await client.query(
    "SELECT * FROM private_tracks WHERE id = $1 AND clerk_user_id = $2", [id, owner],
  )).rows[0] || null;
  return {
    ensureUser: async (owner) => (await pool.query(
      `INSERT INTO users(clerk_user_id) VALUES ($1) ON CONFLICT (clerk_user_id)
       DO UPDATE SET clerk_user_id = EXCLUDED.clerk_user_id RETURNING id, clerk_user_id`, [owner],
    )).rows[0],
    find: lookup,
    list: async (owner, { query, genre, collection, limit, cursor }) => {
      const values = [owner];
      const where = ["t.clerk_user_id = $1", "t.status = 'active'"];
      const add = (value) => { values.push(value); return `$${values.length}`; };
      if (query) {
        const pattern = `%${query.replace(/[\\%_]/g, "\\$&")}%`;
        where.push(`concat_ws(' ', t.title, t.artist, t.genre) ILIKE ${add(pattern)} ESCAPE '\\'`);
      }
      if (genre) where.push(`lower(t.genre) = lower(${add(genre)})`);
      if (collection) where.push(`lower(t.genre) = ANY(${add(collection === "soft-focus" ? ["dream pop", "indie folk"] : ["alternative", "electronic"])})`);
      if (cursor) where.push(`(t.created_at, t.id) < (${add(cursor.at)}::timestamptz, ${add(cursor.id)}::uuid)`);
      const pageSize = add(limit + 1);
      return (await pool.query(`SELECT t.*, to_char(t.created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS cursor_time,
        a.public_id AS artwork_public_id, a.format AS artwork_format,
        a.resource_type AS artwork_resource_type, (f.track_id IS NOT NULL) AS liked
        FROM private_tracks t LEFT JOIN media_assets a ON a.id = t.artwork_asset_id AND a.clerk_user_id = t.clerk_user_id
        LEFT JOIN private_track_favorites f ON f.track_id = t.id AND f.clerk_user_id = t.clerk_user_id
        WHERE ${where.join(" AND ")} ORDER BY t.created_at DESC, t.id DESC LIMIT ${pageSize}`, values)).rows;
    },
    create: async (owner, input) => {
      const client = await pool.connect();
      let open = false;
      try {
        await client.query("BEGIN"); open = true;
        await client.query("SET LOCAL lock_timeout = '5s'");
        if (input.visibility === 'public') {
          const profile=(await client.query("SELECT username FROM users WHERE clerk_user_id=$1 AND profile_status='active' FOR KEY SHARE",[owner])).rows[0];
          if (!profile?.username) throw new HttpError(409,'PROFILE_REQUIRED','Create your public profile first.');
          if (!input.rightsConfirmed) throw new HttpError(400,'RIGHTS_REQUIRED','Confirm your right to share this recording.');
        }
        const ids = [input.audioAssetId, input.artworkAssetId].filter(Boolean);
        const readAssets = async () => (await client.query("SELECT * FROM media_assets WHERE id = ANY($1::uuid[]) AND clerk_user_id = $2", [ids, owner])).rows;
        const initial = await readAssets();
        // Use the same locks as upload/delete, then recheck under the locks.
        for (const key of initial.map((asset) => asset.public_id).sort()) {
          await client.query("SELECT pg_advisory_xact_lock(hashtextextended($1, 0))", [key]);
        }
        const assets = await readAssets();
        if (!assets.some((a) => a.id === input.audioAssetId && a.media_type === "audio") ||
            (input.artworkAssetId && !assets.some((a) => a.id === input.artworkAssetId && a.media_type === "artwork"))) {
          throw new HttpError(404, "MEDIA_NOT_FOUND", "An uploaded file is unavailable.");
        }
        const existing = (await client.query("SELECT * FROM private_tracks WHERE audio_asset_id = $1 AND clerk_user_id = $2", [input.audioAssetId, owner])).rows[0];
        if (existing) {
          if (input.lyricsLrc !== undefined) {
            const lyrics = (await client.query('SELECT lrc FROM track_lyrics WHERE track_id=$1', [existing.id])).rows[0];
            if (lyrics?.lrc !== input.lyricsLrc) throw new HttpError(409, 'TRACK_ALREADY_EXISTS', 'This MP3 is already saved with different details.');
          }
          if (["title", "artist", "genre", "description"].some((field) => existing[field] !== input[field]) || existing.artwork_asset_id !== (input.artworkAssetId || null) || (existing.visibility||'private') !== (input.visibility||'private') || existing.status === 'deleted') {
            throw new HttpError(409, "TRACK_ALREADY_EXISTS", "This MP3 is already saved with different details.");
          }
          await client.query("COMMIT"); open = false; return { created: false, row: existing };
        }
        const row = (await client.query(`INSERT INTO private_tracks(clerk_user_id, audio_asset_id, artwork_asset_id, title, artist, genre, description, visibility, rights_confirmed_at)
          VALUES ($1,$2,$3,$4,$5,$6,$7,$8,CASE WHEN $9 THEN NOW() ELSE NULL END) RETURNING *`, [owner, input.audioAssetId, input.artworkAssetId || null, input.title, input.artist, input.genre, input.description,input.visibility||'private',input.rightsConfirmed===true])).rows[0];
        if (input.lyricsLrc !== undefined) await client.query('INSERT INTO track_lyrics(track_id,lrc) VALUES($1,$2)', [row.id, input.lyricsLrc]);
        await client.query("COMMIT"); open = false;
        return { created: true, row };
      } finally {
        let broken = false;
        if (open) try { await client.query("ROLLBACK"); } catch { broken = true; }
        client.release(broken);
      }
    },
    setFavorite: async (id, owner, liked) => {
      if (!await lookup(id, owner)) throw new HttpError(404, "SONG_NOT_FOUND", "Track not found.");
      if (liked) await pool.query(`WITH legacy AS (INSERT INTO private_track_favorites(clerk_user_id,track_id)
        SELECT clerk_user_id,id FROM private_tracks WHERE id=$1 AND clerk_user_id=$2 ON CONFLICT DO NOTHING RETURNING track_id)
        INSERT INTO track_likes(user_id,track_id) SELECT u.id,t.id FROM private_tracks t JOIN users u ON u.clerk_user_id=t.clerk_user_id WHERE t.id=$1 AND t.clerk_user_id=$2 ON CONFLICT DO NOTHING`,[id,owner]);
      else await pool.query(`WITH legacy AS (DELETE FROM private_track_favorites WHERE track_id=$1 AND clerk_user_id=$2 RETURNING track_id)
        DELETE FROM track_likes l USING users u WHERE l.user_id=u.id AND u.clerk_user_id=$2 AND l.track_id=$1`,[id,owner]);
    },
  };
};
