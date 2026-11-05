import "dotenv/config";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import test from "node:test";
import pg from "pg";

const testDatabaseUrl = process.env.TEST_DATABASE_URL;

const databaseIdentity = (value) => {
  try {
    const url = new URL(value);
    return `${url.hostname.replace(/-pooler(?=\.)/, "")}:${url.port || "5432"}${url.pathname}`;
  } catch {
    throw new Error("Invalid database URL; connection details omitted.");
  }
};

test("media_assets migrations and constraints", {
  skip: !testDatabaseUrl && "Set TEST_DATABASE_URL to an isolated test database.",
}, async (t) => {
  assert.notEqual(process.env.NODE_ENV, "production", "Never run against production.");
  if (process.env.DATABASE_URL) {
    assert.ok(
      databaseIdentity(testDatabaseUrl) !== databaseIdentity(process.env.DATABASE_URL),
      "TEST_DATABASE_URL must use a different database from DATABASE_URL.",
    );
  }

  const client = new pg.Client({
    connectionString: testDatabaseUrl,
    connectionTimeoutMillis: 10000,
  });
  try {
    await client.connect();
  } catch {
    await client.end();
    throw new Error("Cannot connect to the test database; connection details omitted.");
  }
  t.after(async () => {
    try {
      await client.query("ROLLBACK");
    } finally {
      await client.end();
    }
  });

  await client.query("BEGIN");
  // This identifier is generated locally, never taken from user input.
  const schema = `test_media_assets_${randomUUID().replaceAll("-", "")}`;
  await client.query(`CREATE SCHEMA "${schema}"`);
  await client.query("SELECT set_config('search_path', $1, true)", [schema]);

  const migrations = new URL("../src/database/migrations/", import.meta.url);
  for (const filename of (await readdir(migrations)).filter((name) => name.endsWith(".sql")).sort()) {
    await client.query(await readFile(new URL(filename, migrations), "utf8"));
  }

  const insert = (values) => client.query(
    `INSERT INTO media_assets
      (clerk_user_id, media_type, public_id, secure_url, resource_type, bytes)
     VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
    values,
  );
  const artwork = ["user_fixture", "artwork", "fixture/artwork", "https://example.com/artwork.jpg", "image", 0];
  const audio = ["user_fixture", "audio", "fixture/audio", "https://example.com/audio.mp3", "video", "2147483648"];

  await t.test("accepts assets before user synchronization and generates defaults", async () => {
    const result = await insert(artwork);
    const asset = result.rows[0];
    assert.match(asset.id, /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i);
    assert.ok(asset.created_at instanceof Date);
    assert.equal(asset.bytes, "0");
    assert.equal(asset.format, null);
    assert.equal(asset.original_filename, null);
    assert.equal(asset.mime_type, null);
    assert.equal((await client.query("SELECT count(*) FROM users")).rows[0].count, "0");
    assert.equal((await insert(audio)).rows[0].bytes, "2147483648");
  });

  const invalidCases = [
    ["duplicate public_id", artwork, "23505"],
    ["unsupported media_type", [artwork[0], "document", "invalid/type", artwork[3], "image", 1], "23514"],
    ["unsupported resource_type", [artwork[0], "audio", "invalid/resource", audio[3], "raw", 1], "23514"],
    ["negative size", [artwork[0], "audio", "invalid/size", audio[3], "video", -1], "23514"],
    ["missing owner", [null, "audio", "invalid/owner", audio[3], "video", 1], "23502"],
    ["missing size", [artwork[0], "audio", "invalid/null-size", audio[3], "video", null], "23502"],
  ];
  for (const [name, values, code] of invalidCases) {
    await t.test(`rejects ${name}`, async () => {
      await client.query("SAVEPOINT invalid_asset");
      try {
        await assert.rejects(insert(values), (error) => error.code === code);
      } finally {
        await client.query("ROLLBACK TO SAVEPOINT invalid_asset");
        await client.query("RELEASE SAVEPOINT invalid_asset");
      }
    });
  }

  await t.test("reapplying migration 002 preserves existing metadata", async () => {
    await client.query(await readFile(new URL("002_create_media_assets.sql", migrations), "utf8"));
    assert.equal((await client.query("SELECT count(*) FROM media_assets")).rows[0].count, "2");
  });
});
