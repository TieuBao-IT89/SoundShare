import { readdir } from "node:fs/promises";

const migrationFiles = (
  await readdir(new URL("./migrations/", import.meta.url))
)
  .filter((name) => /^\d+.*\.sql$/.test(name))
  .sort();
const socialTables = [
  "track_lyrics",
  "track_comments",
  "comment_likes",
  "content_reports",
  "social_outbox",
  "notifications",
  "notification_preferences",
  "shorts_snapshots",
];

// Read-only check. Starting a server never applies a migration implicitly.
export const assertSchemaReady = async (pool) => {
  let applied, tables;
  try {
    applied = (
      await pool.query("SELECT filename FROM schema_migrations")
    ).rows.map((row) => row.filename);
    tables = (
      await pool.query(
        "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name=ANY($1::text[])",
        [socialTables],
      )
    ).rows.map((row) => row.table_name);
  } catch {
    throw new Error(
      "Database schema check failed. Check database access and run npm run migrate in the intended environment.",
    );
  }
  const pending = migrationFiles.filter((name) => !applied.includes(name));
  if (pending.length || socialTables.some((name) => !tables.includes(name))) {
    throw new Error(
      `Database schema is incomplete${pending.length ? ` (pending: ${pending.join(", ")})` : ""}. Run npm run migrate in the intended environment before starting the server.`,
    );
  }
};
