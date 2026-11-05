import assert from "node:assert/strict";
import test from "node:test";
import { createMediaRepository } from "../src/repositories/media.repository.js";

test("repository parameterizes untrusted values and commits transaction locks", async () => {
  const calls = [];
  const releases = [];
  const client = {
    query: async (sql, values) => {
      calls.push({ sql, values });
      return { rows: sql.includes("pg_try_advisory_xact_lock") ? [{ locked: true }] : [] };
    },
    release: (destroy) => releases.push(destroy),
  };
  const repository = createMediaRepository({ connect: async () => client, query: client.query });
  const hostile = "'; DROP TABLE media_assets; --";
  await repository.withAssetLock(hostile, async (records) => {
    await records.findById(hostile, hostile);
    await records.deleteById(hostile, hostile);
    await records.findByPublicId(hostile, hostile);
    await records.insert({ clerk_user_id: hostile, public_id: hostile, original_filename: hostile });
  });
  await repository.findById(hostile, hostile);
  for (const { sql, values } of calls) {
    assert.ok(!sql.includes(hostile));
    if (values) assert.ok(values.includes(hostile));
  }
  assert.ok(calls.some(({ sql }) => sql === "COMMIT"));
  const deletion = calls.find(({ sql }) => sql.startsWith("DELETE FROM media_assets"));
  assert.ok(deletion.sql.includes("WHERE id = $1 AND clerk_user_id = $2"));
  assert.deepEqual(deletion.values, [hostile, hostile]);
  assert.ok(!calls.some(({ sql }) => sql.includes("pg_advisory_unlock")));
  assert.deepEqual(releases, [false]);
});

test("repository discards a connection if rollback fails", async () => {
  let destroyed = false;
  const repository = createMediaRepository({ connect: async () => ({
    query: async (sql) => {
      if (sql === "ROLLBACK") throw new Error("connection lost");
      return { rows: [{ locked: true }] };
    },
    release: (value) => { destroyed = value; },
  }) });
  await assert.rejects(repository.withAssetLock("fixture", async () => { throw new Error("upload failed"); }), /upload failed/);
  assert.equal(destroyed, true);
});

test("repository rolls back a failed media deletion and releases the connection", async () => {
  const sqlCalls = [];
  let released;
  const repository = createMediaRepository({ connect: async () => ({
    query: async (sql) => {
      sqlCalls.push(sql);
      if (sql.startsWith("DELETE")) throw new Error("database failure");
      return { rows: [{ locked: true }] };
    },
    release: (destroy) => { released = destroy; },
  }) });
  await assert.rejects(repository.withAssetLock("fixture", (records) => records.deleteById("id", "owner")), /database failure/);
  assert.equal(sqlCalls.at(-1), "ROLLBACK");
  assert.ok(!sqlCalls.includes("COMMIT"));
  assert.equal(released, false);
});
