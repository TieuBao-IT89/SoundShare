import "dotenv/config";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import test from "node:test";
import pg from "pg";
import { createTrackRepository } from "../src/repositories/track.repository.js";
import { encodeCursor, decodeCursor } from "../src/validation/track.schema.js";

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

  await t.test("private track constraints enforce ownership and cursor retains timestamp precision", async () => {
    await client.query("INSERT INTO users(clerk_user_id) VALUES ($1),($2)", ["user_fixture", "user_other"]);
    const firstAudio = (await client.query("SELECT id FROM media_assets WHERE public_id=$1", [audio[2]])).rows[0].id;
    const secondAudio = (await insert([audio[0], audio[1], "fixture/audio-two", audio[3], audio[4], 20])).rows[0].id;
    const create = (owner, asset, at) => client.query(`INSERT INTO private_tracks(clerk_user_id,audio_asset_id,title,artist,genre,created_at)
      VALUES ($1,$2,'Fixture title','Fixture artist','Jazz',$3) RETURNING id`, [owner, asset, at]);
    const first = (await create("user_fixture", firstAudio, "2026-11-05T00:00:00.123456Z")).rows[0].id;
    await create("user_fixture", secondAudio, "2026-11-05T00:00:00.123455Z");
    const reject = async (action, code) => {
      await client.query("SAVEPOINT private_constraint");
      try { await assert.rejects(action, (error) => error.code === code); }
      finally { await client.query("ROLLBACK TO SAVEPOINT private_constraint"); await client.query("RELEASE SAVEPOINT private_constraint"); }
    };
    await reject(() => create("user_other", firstAudio, new Date()), "23505");
    const foreignAsset = (await insert(["user_other", "audio", "fixture/foreign", audio[3], "video", 1])).rows[0].id;
    await reject(() => create("user_fixture", foreignAsset, new Date()), "23503");
    await reject(() => client.query("INSERT INTO private_track_favorites(clerk_user_id,track_id) VALUES ($1,$2)", ["user_other", first]), "23503");
    await client.query("INSERT INTO private_track_favorites(clerk_user_id,track_id) VALUES ($1,$2)", ["user_fixture", first]);
    await reject(() => client.query("DELETE FROM media_assets WHERE id=$1", [firstAudio]), "23503");
    const repository = createTrackRepository(client);
    const filters = { query: "Fixture", genre: "Jazz", limit: 1 };
    const page = await repository.list("user_fixture", filters);
    assert.equal(page[0].id, first); assert.ok(page[0].liked);
    const cursor = decodeCursor(encodeCursor(page[0])); assert.match(cursor.at, /123456Z$/);
    const next = await repository.list("user_fixture", { ...filters, cursor });
    assert.equal(next.length, 1); assert.notEqual(next[0].id, first);
    assert.deepEqual(await repository.list("user_other", filters), []);
    await client.query("DELETE FROM private_tracks WHERE id=$1", [first]);
    assert.equal((await client.query("SELECT count(*) FROM private_track_favorites")).rows[0].count, "0");
  });
});
