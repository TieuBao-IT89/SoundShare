import "dotenv/config";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { pool } from "../config/database.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const migrationsDirectory = path.join(__dirname, "migrations");

const runMigrations = async () => {
  const client = await pool.connect();

  try {
    // Prevent two migration processes from running simultaneously.
    await client.query("SELECT pg_advisory_lock($1)", [20261101]);

    // Create migration tracking table.
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    const files = (await fs.readdir(migrationsDirectory))
      .filter((file) => file.endsWith(".sql"))
      .sort();

    console.log(`Found ${files.length} migration file(s).`);

    for (const file of files) {
      const existing = await client.query(
        "SELECT id FROM schema_migrations WHERE filename = $1",
        [file],
      );

      if (existing.rowCount > 0) {
        console.log(`SKIPPED: ${file} (already executed)`);
        continue;
      }

      console.log(`RUNNING: ${file}`);

      const sql = await fs.readFile(
        path.join(migrationsDirectory, file),
        "utf8",
      );

      try {
        await client.query("BEGIN");
        await client.query(sql);

        await client.query(
          "INSERT INTO schema_migrations (filename) VALUES ($1)",
          [file],
        );

        await client.query("COMMIT");

        console.log(`SUCCESS: ${file}`);
      } catch (error) {
        await client.query("ROLLBACK");
        throw new Error(`Migration ${file} failed; database details omitted.`);
      }
    }

    console.log("All migrations completed.");
  } finally {
    try {
      await client.query("SELECT pg_advisory_unlock($1)", [20261101]);
    } finally {
      client.release();
      await pool.end();
    }
  }
};

runMigrations().catch((error) => {
  console.error("MIGRATION FAILED:", error.message);
  process.exitCode = 1;
});
