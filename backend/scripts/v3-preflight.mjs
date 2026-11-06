import "dotenv/config";
if (process.env.NODE_ENV !== "development") {
  console.error(
    "V3 preflight requires the configured development environment. No database changes made.",
  );
  process.exitCode = 1;
} else {
  const { pool } = await import("../src/config/database.js");
  try {
    const counts = (
      await pool.query(`SELECT (SELECT count(*) FROM users)::int AS users,(SELECT count(*) FROM private_tracks)::int AS tracks,
      (SELECT count(*) FROM users WHERE username IS NOT NULL AND (username<>lower(username) OR length(username) NOT BETWEEN 3 AND 24 OR username !~ '^[a-z0-9_][a-z0-9._]*[a-z0-9_]$' OR username IN ('admin','support','soundshare','system','official','search')))::int AS incompatible_usernames`)
    ).rows[0];
    const migrations = (
      await pool.query(
        "SELECT filename FROM schema_migrations ORDER BY filename",
      )
    ).rows.map((row) => row.filename);
    const social = migrations.includes("004_social_music.sql")
      ? (
          await pool.query(`SELECT
      (SELECT count(*) FROM private_tracks WHERE visibility='private')::int AS private_tracks,
      (SELECT count(*) FROM private_tracks WHERE visibility='public')::int AS public_tracks,
      (SELECT count(*) FROM users WHERE username IS NOT NULL)::int AS public_profiles,
      (SELECT count(*) FROM user_follows)::int AS follows`)
        ).rows[0]
      : null;
    console.log(
      JSON.stringify({
        environment: "development",
        ...counts,
        migrations,
        social,
      }),
    );
    if (counts.incompatible_usernames) process.exitCode = 1;
  } catch {
    console.error("V3 preflight failed; connection details omitted.");
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
