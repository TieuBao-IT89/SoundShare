import assert from "node:assert/strict";
import { generateKeyPairSync, sign, randomUUID } from "node:crypto";
import { once } from "node:events";
import test from "node:test";
import { createApp } from "../src/app.js";
import { createTrackService } from "../src/services/track.service.js";
import { createTrackRepository } from "../src/repositories/track.repository.js";
import { createUploadService } from "../src/services/upload.service.js";
import { parse, listTracksSchema, createTrackSchema, decodeCursor, encodeCursor } from "../src/validation/track.schema.js";
import { createFakes, audioFile } from "./helpers/upload-fixtures.js";

const keys = generateKeyPairSync("rsa", { modulusLength: 2048 });
const issuer = "https://fixture.clerk.accounts.dev";
const clerkOptions = { publishableKey: `pk_test_${Buffer.from("fixture.clerk.accounts.dev$").toString("base64")}`, secretKey: "sk_test_fixture", jwtKey: keys.publicKey.export({ type: "spki", format: "pem" }), issuer, audience: "soundshare-api" };
const token = (sub = "user_owner") => {
  const now = Math.floor(Date.now() / 1000);
  const parts = [Buffer.from(JSON.stringify({ alg: "RS256", kid: "fixture" })).toString("base64url"), Buffer.from(JSON.stringify({ sub, sid: "sess_fixture", sts: "active", v: 2, iss: issuer, aud: "soundshare-api", iat: now, nbf: now - 5, exp: now + 120 })).toString("base64url")];
  const input = parts.join(".");
  return `${input}.${sign("RSA-SHA256", Buffer.from(input), keys.privateKey).toString("base64url")}`;
};

test("private catalog API verifies identity, isolates owners, signs playback and persists likes", async (t) => {
  const rows = new Map(); const likes = new Set(); let calls = 0; let fail = false;
  const repository = {
    ensureUser: async (owner) => { calls++; if (fail) throw new Error("private-connection-sentinel"); return { id: randomUUID(), clerk_user_id: owner }; },
    create: async (owner, input) => { const row = { ...input, id: randomUUID(), clerk_user_id: owner, audio_asset_id: input.audioAssetId, created_at: new Date(), liked: false }; rows.set(row.id, row); return { row, created: true }; },
    find: async (id, owner) => { const row = rows.get(id); return row?.clerk_user_id === owner ? row : null; },
    list: async (owner) => [...rows.values()].filter((row) => row.clerk_user_id === owner).map((row) => ({ ...row, liked: likes.has(`${owner}:${row.id}`) })),
    setFavorite: async (id, owner, liked) => { if (!await repository.find(id, owner)) { const { HttpError } = await import("../src/utils/http-error.js"); throw new HttpError(404, "SONG_NOT_FOUND", "Track not found."); } liked ? likes.add(`${owner}:${id}`) : likes.delete(`${owner}:${id}`); },
  };
  const playbackCalls = [];
  const service = createTrackService({ repository, storage: { createAccess: () => ({ url: "https://example.com/private", expiresAt: new Date().toISOString() }) }, uploadService: { getAccess: async (input) => { playbackCalls.push(input); return { access: { url: "https://example.com/audio", expiresAt: new Date().toISOString() } }; } } });
  const app = createApp({ clerkOptions, trackService: service, logging: false });
  const server = app.listen(0, "127.0.0.1"); await once(server, "listening");
  t.after(() => new Promise((resolve) => { server.close(resolve); server.closeAllConnections(); }));
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;
  const request = (path, method = "GET", body, owner = "user_owner") => fetch(base + path, { method, headers: { ...(owner ? { Authorization: `Bearer ${token(owner)}` } : {}), ...(body ? { "Content-Type": "application/json" } : {}) }, body: body ? JSON.stringify(body) : undefined });
  for (const path of ["/songs", "/auth/me"]) assert.equal((await request(path, "GET", undefined, null)).status, 401);
  assert.equal(calls, 0);
  assert.equal((await request("/auth/me")).status, 200);
  const input = { audioAssetId: randomUUID(), title: "My own song", artist: "Owner", genre: "Indie", description: "" };
  for (const invalid of [{ ...input, clerkUserId: "user_other" }, { ...input, audioAssetId: "bad" }, { ...input, title: " " }]) assert.equal((await request("/songs", "POST", invalid)).status, 400);
  const created = await request("/songs", "POST", input); assert.equal(created.status, 201);
  const id = (await created.json()).data.id;
  const listing = await request("/songs"); assert.equal(listing.headers.get("cache-control"), "no-store");
  assert.equal((await listing.json()).data.items.length, 1);
  assert.deepEqual((await (await request("/songs", "GET", undefined, "user_other")).json()).data.items, []);
  for (const path of [`/songs/${id}/playback`, `/songs/${id}/favorite`]) {
    assert.equal((await request(path, path.endsWith("favorite") ? "PUT" : "GET", undefined, "user_other")).status, 404);
  }
  assert.equal(playbackCalls.length, 0);
  assert.equal((await request(`/songs/${id}/playback`)).status, 200);
  assert.deepEqual(playbackCalls[0], { id: input.audioAssetId, userId: "user_owner" });
  for (const method of ["PUT", "PUT", "DELETE", "DELETE"]) assert.equal((await request(`/songs/${id}/favorite`, method)).status, 204);
  assert.equal(likes.size, 0);
  for (const path of ["/songs?limit=51", "/songs?cursor=invalid", "/songs?owner=other", `/songs/${id}/playback?owner=other`]) assert.equal((await request(path)).status, 400);
  fail = true;
  const response = await request("/auth/me"); assert.equal(response.status, 503);
  const error = await response.json(); assert.ok(error.error.requestId); assert.ok(!JSON.stringify(error).includes("private-connection-sentinel"));
});

test("catalog SQL parameterizes filters and applies owner, keyset pagination and literal search", async () => {
  const calls = [];
  const repository = createTrackRepository({ query: async (sql, values) => { calls.push({ sql, values }); return { rows: [] }; } });
  const malicious = "%' OR 1=1 --";
  await repository.list("user_owner", { query: malicious, genre: "Jazz", collection: "after-hours", limit: 10, cursor: { at: "2026-01-01T00:00:00Z", id: randomUUID() } });
  assert.ok(!calls[0].sql.includes(malicious));
  assert.match(calls[0].sql, /t.clerk_user_id = \$1/);
  assert.match(calls[0].sql, /ORDER BY t.created_at DESC, t.id DESC/);
  assert.equal(calls[0].values[0], "user_owner"); assert.equal(calls[0].values.at(-1), 11);
  assert.ok(calls[0].values[1].startsWith("%\\%"));
});

test("track creation rechecks ownership under media locks, commits retries and rejects foreign media", async () => {
  const audio = { id: randomUUID(), public_id: "fixture/audio", media_type: "audio" };
  let existing; let assets = [audio]; const commands = [];
  const client = { release: () => commands.push("release"), query: async (sql) => {
    commands.push(sql);
    if (sql.startsWith("SELECT * FROM media_assets")) return { rows: assets };
    if (sql.startsWith("SELECT * FROM private_tracks")) return { rows: existing ? [existing] : [] };
    if (sql.startsWith("INSERT INTO private_tracks")) return { rows: [{ id: randomUUID() }] };
    return { rows: [] };
  } };
  const repo = createTrackRepository({ connect: async () => client });
  const input = { audioAssetId: audio.id, title: "Title", artist: "Artist", genre: "Jazz", description: "" };
  assert.equal((await repo.create("owner", input)).created, true);
  assert.ok(commands.findIndex((sql) => sql.includes("pg_advisory_xact_lock")) < commands.lastIndexOf("SELECT * FROM media_assets WHERE id = ANY($1::uuid[]) AND clerk_user_id = $2"));
  existing = { ...input, artwork_asset_id: null };
  assert.equal((await repo.create("owner", input)).created, false);
  await assert.rejects(repo.create("owner", { ...input, title: "Different" }), (e) => e.code === "TRACK_ALREADY_EXISTS");
  assets = [];
  await assert.rejects(repo.create("other", input), (e) => e.statusCode === 404);
  assert.ok(commands.includes("ROLLBACK"));
});

test("in-use media cannot be deleted from Cloudinary", async () => {
  const fakes = createFakes(); const service = createUploadService(fakes);
  const uploaded = await service.upload({ userId: "owner", mediaType: "audio", file: audioFile() });
  fakes.records.isReferencedByTrack = async () => true;
  await assert.rejects(service.remove({ id: uploaded.asset.id, userId: "owner" }), (e) => e.code === "MEDIA_IN_USE");
  assert.equal(fakes.calls.remove, 0); assert.equal(fakes.calls.delete, 0);
});

test("cursor validation rejects malformed shapes and strict schemas reject owner injection", () => {
  const id = randomUUID(); const row = { id, created_at: new Date() };
  assert.equal(decodeCursor(encodeCursor(row)).id, id);
  assert.equal(decodeCursor(encodeCursor({ ...row, cursor_time: '2026-11-05T12:00:00.123456Z' })).at, '2026-11-05T12:00:00.123456Z');
  assert.throws(() => decodeCursor(Buffer.from('{"at":"bad","id":"bad"}').toString("base64url")));
  assert.throws(() => parse(listTracksSchema, { limit: "999" }));
  assert.throws(() => parse(createTrackSchema, { title: "x", owner: "other" }));
});
