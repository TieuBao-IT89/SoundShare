import "dotenv/config";
import { pool } from "./src/config/database.js";
import { randomUUID } from "node:crypto";

const client = await pool.connect();
let transactionStarted = false;

const assert = (condition, message) => {
  if (!condition) {
    throw new Error(`TEST FAILED: ${message}`);
  }
};

try {
  await client.query("BEGIN");
  transactionStarted = true;

  console.log("\n=== SOUNDSHARE CRUD TEST ===\n");

  // 1. CREATE USER
  const userResult = await client.query(
    `INSERT INTO users (clerk_user_id, email, username, display_name)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [
      `test_${randomUUID()}`,
      `test_${randomUUID()}@example.com`,
      `test_${randomUUID().slice(0, 12)}`,
      "Test User",
    ],
  );

  const user = userResult.rows[0];
  assert(user.id, "Create user");
  console.log("PASS: Create user");

  // 2. CREATE ARTIST
  const artistResult = await client.query(
    `INSERT INTO artists (name, bio)
     VALUES ($1, $2) RETURNING *`,
    ["Test Artist", "Artist for CRUD testing"],
  );

  const artist = artistResult.rows[0];
  console.log("PASS: Create artist");

  // 3. CREATE ALBUM
  const albumResult = await client.query(
    `INSERT INTO albums (artist_id, title)
     VALUES ($1, $2) RETURNING *`,
    [artist.id, "Test Album"],
  );

  const album = albumResult.rows[0];
  console.log("PASS: Create album");

  // 4. CREATE SONG
  const songResult = await client.query(
    `INSERT INTO songs
      (artist_id, album_id, title, audio_url, duration_seconds, genre)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [
      artist.id,
      album.id,
      "Test Song",
      "https://example.com/test-audio.mp3",
      180,
      "Pop",
    ],
  );

  const song = songResult.rows[0];
  console.log("PASS: Create song");

  // 5. CREATE PLAYLIST
  const playlistResult = await client.query(
    `INSERT INTO playlists (user_id, title, description)
     VALUES ($1, $2, $3) RETURNING *`,
    [user.id, "Test Playlist", "Playlist for CRUD testing"],
  );

  const playlist = playlistResult.rows[0];
  console.log("PASS: Create playlist");

  // 6. CREATE PLAYLIST SONG
  await client.query(
    `INSERT INTO playlist_songs (playlist_id, song_id, position)
     VALUES ($1, $2, $3)`,
    [playlist.id, song.id, 0],
  );

  console.log("PASS: Create playlist_songs");

  // 7. CREATE FAVORITE
  await client.query(
    `INSERT INTO favorites (user_id, song_id)
     VALUES ($1, $2)`,
    [user.id, song.id],
  );

  console.log("PASS: Create favorite");

  // 8. CREATE LISTENING HISTORY
  const historyResult = await client.query(
    `INSERT INTO listening_history (user_id, song_id, progress_seconds)
     VALUES ($1, $2, $3) RETURNING *`,
    [user.id, song.id, 30],
  );

  const history = historyResult.rows[0];
  console.log("PASS: Create listening history");

  // READ
  const readSong = await client.query(
    `SELECT s.title, a.name AS artist_name, al.title AS album_title
     FROM songs s
     JOIN artists a ON s.artist_id = a.id
     JOIN albums al ON s.album_id = al.id
     WHERE s.id = $1`,
    [song.id],
  );

  assert(readSong.rowCount === 1, "Read song with artist and album");
  console.log("PASS: Read song with artist and album");

  const readPlaylist = await client.query(
    `SELECT p.title, s.title AS song_title
     FROM playlists p
     JOIN playlist_songs ps ON ps.playlist_id = p.id
     JOIN songs s ON s.id = ps.song_id
     WHERE p.id = $1`,
    [playlist.id],
  );

  assert(readPlaylist.rowCount === 1, "Read playlist and songs");
  console.log("PASS: Read playlist and songs");

  const readFavorite = await client.query(
    `SELECT * FROM favorites WHERE user_id = $1 AND song_id = $2`,
    [user.id, song.id],
  );

  assert(readFavorite.rowCount === 1, "Read favorite");
  console.log("PASS: Read favorite");

  // UPDATE
  await client.query(`UPDATE users SET display_name = $1 WHERE id = $2`, [
    "Updated Test User",
    user.id,
  ]);

  await client.query(`UPDATE artists SET bio = $1 WHERE id = $2`, [
    "Updated artist bio",
    artist.id,
  ]);

  await client.query(`UPDATE albums SET title = $1 WHERE id = $2`, [
    "Updated Test Album",
    album.id,
  ]);

  await client.query(`UPDATE songs SET title = $1 WHERE id = $2`, [
    "Updated Test Song",
    song.id,
  ]);

  await client.query(`UPDATE playlists SET title = $1 WHERE id = $2`, [
    "Updated Test Playlist",
    playlist.id,
  ]);

  await client.query(
    `UPDATE playlist_songs SET position = $1
     WHERE playlist_id = $2 AND song_id = $3`,
    [1, playlist.id, song.id],
  );

  await client.query(
    `UPDATE favorites SET created_at = NOW()
     WHERE user_id = $1 AND song_id = $2`,
    [user.id, song.id],
  );

  await client.query(
    `UPDATE listening_history SET progress_seconds = $1 WHERE id = $2`,
    [60, history.id],
  );

  const updatedSong = await client.query(
    `SELECT title FROM songs WHERE id = $1`,
    [song.id],
  );

  assert(updatedSong.rows[0].title === "Updated Test Song", "Update song");

  console.log("PASS: Update records across 8 tables");

  // DELETE - children first, then parent records
  await client.query(`DELETE FROM listening_history WHERE id = $1`, [
    history.id,
  ]);

  await client.query(
    `DELETE FROM favorites WHERE user_id = $1 AND song_id = $2`,
    [user.id, song.id],
  );

  await client.query(
    `DELETE FROM playlist_songs
     WHERE playlist_id = $1 AND song_id = $2`,
    [playlist.id, song.id],
  );

  await client.query(`DELETE FROM playlists WHERE id = $1`, [playlist.id]);
  await client.query(`DELETE FROM songs WHERE id = $1`, [song.id]);
  await client.query(`DELETE FROM albums WHERE id = $1`, [album.id]);
  await client.query(`DELETE FROM artists WHERE id = $1`, [artist.id]);
  await client.query(`DELETE FROM users WHERE id = $1`, [user.id]);

  console.log("PASS: Delete records across 8 tables");

  await client.query("ROLLBACK");
  transactionStarted = false;

  console.log("\n================================");
  console.log("ALL CRUD TESTS PASSED!");
  console.log("Test data was rolled back.");
  console.log("================================\n");
} catch (error) {
  if (transactionStarted) {
    await client.query("ROLLBACK");
  }

  console.error("\nCRUD TEST FAILED:");
  console.error(error.message);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
