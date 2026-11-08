import assert from "node:assert/strict";
import test from "node:test";
import { readdir } from "node:fs/promises";
import { communityDatabase } from "./helpers/community-fixture.js";
import { assertSchemaReady } from "../src/database/schema-readiness.js";

test("startup refuses a missing V9 migration or missing table; passes the complete migrated schema", async (t) => {
  const { db, pool, close } = await communityDatabase();
  t.after(close);
  await assert.rejects(
    () => assertSchemaReady(pool),
    /Database schema check failed/,
  );
  await db.exec("CREATE TABLE schema_migrations(filename TEXT PRIMARY KEY)");
  const files = (
    await readdir(new URL("../src/database/migrations/", import.meta.url))
  )
    .filter((v) => v.endsWith(".sql"))
    .sort();
  for (const file of files)
    await db.query("INSERT INTO schema_migrations(filename) VALUES($1)", [
      file,
    ]);
  await assert.doesNotReject(() => assertSchemaReady(pool));
  await db.query("DELETE FROM schema_migrations WHERE filename=$1", [
    "006_social_discovery.sql",
  ]);
  await assert.rejects(
    () => assertSchemaReady(pool),
    /pending: 006_social_discovery.sql/,
  );
  await db.query("INSERT INTO schema_migrations(filename) VALUES($1)", [
    "006_social_discovery.sql",
  ]);
  await db.exec("DROP TABLE notifications");
  await assert.rejects(
    () => assertSchemaReady(pool),
    /Database schema is incomplete/,
  );
});
