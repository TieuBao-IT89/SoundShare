import { HttpError } from '../utils/http-error.js';

const missing = () => new HttpError(404, 'SONG_NOT_FOUND', 'Track not found.');
const accessSql = `SELECT t.id,t.clerk_user_id FROM private_tracks t
  JOIN users u ON u.clerk_user_id=t.clerk_user_id
  WHERE t.id=$1 AND t.status='active' AND (t.clerk_user_id=$2 OR
    (t.visibility='public' AND u.profile_status='active' AND u.username IS NOT NULL))`;
export const createLyricsRepository = pool => ({
  read: async (owner, id) => {
    const row = (await pool.query(`SELECT t.clerk_user_id,l.lrc,COALESCE(l.revision,0) AS revision,l.updated_at
      FROM (${accessSql}) t LEFT JOIN track_lyrics l ON l.track_id=t.id`, [id, owner])).rows[0];
    if (!row) throw missing();
    return row;
  },
  write: async (owner, id, lrc, revision) => {
    const client = await pool.connect();
    let open = false, broken = false;
    try {
      await client.query('BEGIN'); open = true;
      await client.query("SET LOCAL lock_timeout='5s'");
      const track = (await client.query(`${accessSql} FOR UPDATE OF t`, [id, owner])).rows[0];
      if (!track) throw missing();
      if (track.clerk_user_id !== owner) throw new HttpError(403, 'FORBIDDEN', 'Only the uploader can edit lyrics.');
      const current = (await client.query('SELECT revision FROM track_lyrics WHERE track_id=$1', [id])).rows[0];
      if ((current?.revision || 0) !== revision) throw new HttpError(409, 'LYRICS_CHANGED', 'Lyrics changed. Reload before saving.');
      const row = (await client.query(`INSERT INTO track_lyrics(track_id,lrc) VALUES($1,$2)
        ON CONFLICT(track_id) DO UPDATE SET lrc=EXCLUDED.lrc,revision=track_lyrics.revision+1,updated_at=NOW()
        RETURNING lrc,revision,updated_at`, [id, lrc])).rows[0];
      await client.query('COMMIT'); open = false;
      return { ...row, clerk_user_id: owner };
    } finally {
      if (open) try { await client.query('ROLLBACK'); } catch { broken = true; }
      client.release(broken);
    }
  },
});
