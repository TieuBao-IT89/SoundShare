import assert from "node:assert/strict";
import { generateKeyPairSync, sign } from "node:crypto";
import { once } from "node:events";
import test from "node:test";
import { createApp } from "../src/app.js";
import { createUploadService } from "../src/services/upload.service.js";
import { createRateLimit } from "../src/middleware/upload-limits.middleware.js";
import { createFakes, png, mp3 } from "./helpers/upload-fixtures.js";

const keys = generateKeyPairSync("rsa", { modulusLength: 2048 });
const issuer = "https://fixture.clerk.accounts.dev";
const clerkOptions = {
  publishableKey: `pk_test_${Buffer.from("fixture.clerk.accounts.dev$").toString("base64")}`,
  secretKey: "sk_test_fixture", jwtKey: keys.publicKey.export({ type: "spki", format: "pem" }),
  issuer, audience: "soundshare-api", debug: false,
};
const token = (claims = {}, privateKey = keys.privateKey) => {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: "RS256", typ: "JWT", kid: "fixture" })).toString("base64url");
  const payload = Buffer.from(JSON.stringify({
    sub: "user_fixture", sid: "sess_fixture", sts: "active", v: 2,
    iss: issuer, aud: "soundshare-api", iat: now, nbf: now - 5, exp: now + 120,
    ...claims,
  })).toString("base64url");
  const input = `${header}.${payload}`;
  return `${input}.${sign("RSA-SHA256", Buffer.from(input), privateKey).toString("base64url")}`;
};

const start = async (t, options = {}) => {
  const fakes = createFakes();
  const service = createUploadService({ ...fakes, report: (event) => fakes.events.push(event) });
  const app = createApp({ uploadService: service, clerkOptions, logging: false, ...options });
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(() => new Promise((resolve) => { server.close(resolve); server.closeAllConnections(); }));
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;
  const upload = async ({ type = "artwork", bytes = png, filename = "fixture.png", mime = "image/png", auth = token(), extra, query = "" } = {}) => {
    const body = new FormData();
    if (bytes !== null) body.append("file", new Blob([bytes], { type: mime }), filename);
    if (extra) for (const [key, value] of Object.entries(extra)) body.append(key, value);
    const response = await fetch(`${base}/uploads/${type}${query}`, {
      method: "POST", headers: auth === null ? {} : { Authorization: `Bearer ${auth}` }, body,
    });
    const json = await response.json();
    if (!response.ok) {
      assert.ok(json.error.requestId);
      assert.equal(json.error.requestId, response.headers.get("x-request-id"));
    }
    return { response, json };
  };
  return { ...fakes, base, upload };
};

test("upload HTTP API with actual Clerk signature verification", async (t) => {
  const api = await start(t);
  await t.test("missing, malformed, expired, forged, wrong issuer/audience and missing audience tokens get 401", async () => {
    const otherKey = generateKeyPairSync("rsa", { modulusLength: 2048 }).privateKey;
    for (const auth of [null, "invalid", token({ exp: 1 }), token({}, otherKey), token({ iss: "https://other.clerk.accounts.dev" }), token({ aud: "another-api" }), token({ aud: undefined }), token({ nbf: Math.floor(Date.now() / 1000) + 120 }), token({ sid: undefined }), token({ sts: "pending" })]) {
      const { response, json } = await api.upload({ auth });
      assert.equal(response.status, 401);
      assert.equal(json.error.code, "UNAUTHORIZED");
      assert.equal(response.headers.get("www-authenticate"), "Bearer");
    }
    assert.equal(api.calls.upload, 0);
    assert.equal(api.calls.insert, 0);
  });
  let assetId;
  await t.test("uploads artwork and MP3, persists verified ownership and makes retries idempotent", async () => {
    const first = await api.upload();
    assert.equal(first.response.status, 201);
    assert.equal(first.json.data.mediaType, "artwork");
    assert.equal(first.response.headers.get("cache-control"), "no-store");
    assetId = first.json.data.id;
    const stored = [...api.assets.values()][0];
    assert.equal(stored.clerk_user_id, "user_fixture");
    assert.equal(stored.bytes, String(png.length));
    assert.ok(!stored.secure_url.includes("signature"));
    assert.equal(stored.access, undefined);
    const replay = await api.upload();
    assert.equal(replay.response.status, 200);
    assert.equal(replay.json.data.id, assetId);
    assert.equal(api.calls.upload, 1);
    const audio = await api.upload({ type: "audio", bytes: mp3, filename: "silence.mp3", mime: "audio/mpeg" });
    assert.equal(audio.response.status, 201);
    assert.equal(audio.json.data.resourceType, "video");
    assert.equal(audio.json.data.format, "mp3");
    assert.equal(api.assets.size, 2);
  });
  await t.test("only the owner obtains expiring access and foreign IDs reveal no metadata", async () => {
    for (const [sub, status] of [["user_fixture", 200], ["user_other", 404]]) {
      const response = await fetch(`${api.base}/uploads/${assetId}/access`, { headers: { Authorization: `Bearer ${token({ sub })}` } });
      assert.equal(response.status, status);
      const json = await response.json();
      if (status === 200) {
        const ttl = Date.parse(json.data.access.expiresAt) - Date.now();
        assert.ok(ttl > 290000 && ttl <= 300000);
      } else {
        assert.equal(json.error.code, "MEDIA_NOT_FOUND");
        assert.equal(json.data, undefined);
      }
    }
    const invalid = await fetch(`${api.base}/uploads/not-a-uuid/access`, { headers: { Authorization: `Bearer ${token()}` } });
    assert.equal(invalid.status, 400);
  });
});

test("file validation and request limits reject invalid input before Storage", async (t) => {
  const api = await start(t);
  for (const [name, input, status, code] of [
    ["missing file", { bytes: null }, 400, "FILE_REQUIRED"],
    ["spoofed PNG", { bytes: Buffer.from("not an image") }, 415, "INVALID_FILE_TYPE"],
    ["extension mismatch", { filename: "fake.jpg" }, 415, "INVALID_FILE_TYPE"],
    ["owner body", { extra: { clerk_user_id: "user_other" } }, 400, "INVALID_MULTIPART"],
    ["object key query", { query: "?public_id=another-user" }, 400, "INVALID_MULTIPART"],
    ["ID3 only", { type: "audio", bytes: Buffer.from("ID3\x04\x00\x00\x00\x00\x00\x00fake"), filename: "fake.mp3", mime: "audio/mpeg" }, 415, "INVALID_FILE_TYPE"],
    ["WAV outside MVP", { type: "audio", bytes: mp3, filename: "fake.wav", mime: "audio/wav" }, 415, "INVALID_FILE_TYPE"],
    ["oversize artwork", { bytes: Buffer.alloc(5 * 1024 * 1024 + 1) }, 413, "FILE_TOO_LARGE"],
    ["oversize audio", { type: "audio", bytes: Buffer.alloc(20 * 1024 * 1024 + 1), filename: "large.mp3", mime: "audio/mpeg" }, 413, "FILE_TOO_LARGE"],
  ]) {
    await t.test(name, async () => {
      const { response, json } = await api.upload(input);
      assert.equal(response.status, status);
      assert.equal(json.error.code, code);
    });
  }
  assert.equal(api.calls.upload, 0);
  assert.equal(api.calls.insert, 0);
});

test("upload rate limiting applies before file buffering", async (t) => {
  const api = await start(t, { uploadRateLimit: createRateLimit({ limit: 2 }) });
  assert.equal((await api.upload()).response.status, 201);
  assert.equal((await api.upload()).response.status, 200);
  const denied = await api.upload();
  assert.equal(denied.response.status, 429);
  assert.ok(Number(denied.response.headers.get("retry-after")) > 0);
  assert.equal(api.calls.upload, 1);
});

test("provider errors do not expose secrets in API responses or logs", async (t) => {
  const api = await start(t);
  const messages = [];
  t.mock.method(console, "error", (message) => messages.push(message));
  api.storage.upload = async () => { throw new Error("secret-sentinel postgresql://private-host password=hidden"); };
  const failed = await api.upload();
  assert.equal(failed.response.status, 502);
  assert.equal(failed.json.error.code, "STORAGE_UNAVAILABLE");
  assert.ok(!JSON.stringify([failed.json, messages]).includes("secret-sentinel"));
  assert.ok(!JSON.stringify([failed.json, messages]).includes("private-host"));
  assert.equal(api.assets.size, 0);
});

test("DELETE media requires Clerk and deletes only the owner asset", async (t) => {
  const api = await start(t);
  const artwork = (await api.upload()).json.data;
  const audio = (await api.upload({ type: "audio", bytes: mp3, filename: "silence.mp3", mime: "audio/mpeg" })).json.data;
  for (const auth of [null, "invalid", token({ exp: 1 })]) {
    const response = await fetch(`${api.base}/uploads/${artwork.id}`, {
      method: "DELETE", headers: auth === null ? {} : { Authorization: `Bearer ${auth}` },
    });
    assert.equal(response.status, 401);
  }
  const foreign = await fetch(`${api.base}/uploads/${artwork.id}`, {
    method: "DELETE", headers: { Authorization: `Bearer ${token({ sub: "user_other" })}` },
  });
  assert.equal(foreign.status, 404);
  assert.equal((await foreign.json()).error.code, "MEDIA_NOT_FOUND");
  assert.equal(api.calls.remove, 0);
  const types = [];
  const remove = api.storage.remove;
  api.storage.remove = async (id, type) => { types.push(type); await remove(id, type); };
  for (const asset of [artwork, audio]) {
    const response = await fetch(`${api.base}/uploads/${asset.id}`, { method: "DELETE", headers: { Authorization: `Bearer ${token()}` } });
    assert.equal(response.status, 204);
    assert.equal(await response.text(), "");
    assert.equal(response.headers.get("cache-control"), "no-store");
    const access = await fetch(`${api.base}/uploads/${asset.id}/access`, { headers: { Authorization: `Bearer ${token()}` } });
    assert.equal(access.status, 404);
  }
  assert.deepEqual(types, ["image", "video"]);
  assert.equal(api.objects.size, 0);
  assert.equal(api.assets.size, 0);
  const replay = await fetch(`${api.base}/uploads/${artwork.id}`, { method: "DELETE", headers: { Authorization: `Bearer ${token()}` } });
  assert.equal(replay.status, 404);
  assert.equal(api.calls.remove, 2);
});

test("DELETE rejects invalid IDs, extra queries and client-supplied owner/object metadata", async (t) => {
  const api = await start(t);
  const asset = (await api.upload()).json.data;
  for (const [path, body] of [
    ["not-a-uuid", undefined],
    [encodeURIComponent("'; DROP TABLE media_assets; --"), undefined],
    [`${asset.id}?public_id=someone-else`, undefined],
    [asset.id, JSON.stringify({ clerk_user_id: "user_other", public_id: "someone-else", resource_type: "video" })],
  ]) {
    const response = await fetch(`${api.base}/uploads/${path}`, {
      method: "DELETE", headers: { Authorization: `Bearer ${token()}`, "Content-Type": "application/json" }, body,
    });
    assert.equal(response.status, 400);
    const json = await response.json();
    assert.equal(json.error.code, "VALIDATION_ERROR");
    assert.equal(json.error.requestId, response.headers.get("x-request-id"));
  }
  assert.equal(api.calls.remove, 0);
  assert.equal(api.assets.size, 1);
});

test("DELETE errors are safe and retries recover Storage/Neon partial failure", async (t) => {
  const api = await start(t);
  const asset = (await api.upload()).json.data;
  const logs = [];
  t.mock.method(console, "error", (message) => logs.push(message));
  const remove = api.storage.remove;
  const deleteById = api.records.deleteById;
  const request = () => fetch(`${api.base}/uploads/${asset.id}`, { method: "DELETE", headers: { Authorization: `Bearer ${token()}` } });
  api.storage.remove = async () => { throw new Error("secret-sentinel provider-secret"); };
  const storageError = await request();
  assert.equal(storageError.status, 502);
  const storageJson = await storageError.json();
  assert.equal(storageJson.error.code, "STORAGE_DELETE_FAILED");
  assert.equal(api.assets.size, 1);
  api.storage.remove = remove;
  api.records.deleteById = async () => { throw new Error("secret-sentinel database connection"); };
  const databaseError = await request();
  assert.equal(databaseError.status, 503);
  const databaseJson = await databaseError.json();
  assert.equal(databaseJson.error.code, "DATABASE_UNAVAILABLE");
  assert.equal(api.objects.size, 0);
  assert.equal(api.assets.size, 1);
  assert.ok(!JSON.stringify([storageJson, databaseJson, logs]).includes("secret-sentinel"));
  api.records.deleteById = deleteById;
  assert.equal((await request()).status, 204);
  assert.equal(api.assets.size, 0);
});

test("DELETE has a per-user rate limit before Storage access", async (t) => {
  const api = await start(t);
  const id = "00000000-0000-4000-8000-000000000000";
  for (let i = 0; i < 20; i++) {
    const response = await fetch(`${api.base}/uploads/${id}`, { method: "DELETE", headers: { Authorization: `Bearer ${token()}` } });
    assert.equal(response.status, 404);
    await response.arrayBuffer();
  }
  const limited = await fetch(`${api.base}/uploads/${id}`, { method: "DELETE", headers: { Authorization: `Bearer ${token()}` } });
  assert.equal(limited.status, 429);
  assert.ok(Number(limited.headers.get("retry-after")) > 0);
  assert.equal(api.calls.remove, 0);
});
