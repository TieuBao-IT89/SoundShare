import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import test from "node:test";
import { v2 as cloudinary } from "cloudinary";
import { createCloudinaryStorage } from "../src/services/cloudinary-storage.service.js";

test("Cloudinary uploads are authenticated, cannot overwrite and stream only the validated bytes", async () => {
  const buffer = Buffer.from("synthetic fixture");
  let options;
  const storage = createCloudinaryStorage({ uploader: {
    upload_stream: (input, callback) => {
      options = input;
      const stream = new EventEmitter();
      stream.end = (received) => { assert.deepEqual(received, buffer); callback(null, { public_id: "fixture" }); };
      return stream;
    },
  } });
  await storage.upload({ buffer, publicId: "fixture", resourceType: "video", formats: ["mp3"] });
  assert.equal(options.type, "authenticated");
  assert.equal(options.resource_type, "video");
  assert.equal(options.public_id, "fixture");
  assert.equal(options.overwrite, false);
  assert.deepEqual(options.allowed_formats, ["mp3"]);
});

test("Cloudinary storage distinguishes missing objects from provider failures", async () => {
  const sdk = { api: { resource: async () => { throw { error: { http_code: 404 } }; } } };
  const storage = createCloudinaryStorage(sdk);
  assert.equal(await storage.find("fixture", "image"), null);
  sdk.api.resource = async () => { throw new Error("provider unavailable"); };
  await assert.rejects(storage.find("fixture", "image"), /provider unavailable/);
});

test("SDK generates unsigned stored metadata and expiring signed access separately", async () => {
  cloudinary.config({ cloud_name: "fixture", api_key: "fixture-key", api_secret: "fixture-secret", secure: true });
  const sdk = {
    url: cloudinary.url,
    utils: cloudinary.utils,
    api: { resource: async () => ({ format: "mp3", version: 1, secure_url: "https://example.com/?signature=must-not-persist" }) },
  };
  const storage = createCloudinaryStorage(sdk);
  const metadata = await storage.find("fixture/audio", "video");
  const storedUrl = new URL(metadata.secure_url);
  assert.equal(storedUrl.search, "");
  assert.ok(storedUrl.pathname.includes("/video/authenticated/"));
  assert.ok(!storedUrl.pathname.includes("/s--"));
  const access = storage.createAccess({ public_id: "fixture/audio", format: "mp3", resource_type: "video" });
  const url = new URL(access.url);
  assert.equal(url.protocol, "https:");
  assert.equal(url.searchParams.get("type"), "authenticated");
  assert.ok(url.searchParams.get("signature"));
  assert.equal(Number(url.searchParams.get("expires_at")) * 1000, Date.parse(access.expiresAt));
  assert.ok(Date.parse(access.expiresAt) - Date.now() <= 300000);
});

test("Cloudinary deletion uses the stored image/video type, authenticated delivery and invalidation", async () => {
  for (const resourceType of ["image", "video"]) {
    for (const result of ["ok", "not found"]) {
      let received;
      const storage = createCloudinaryStorage({ uploader: {
        destroy: async (id, options) => { received = { id, options }; return { result }; },
      } });
      await storage.remove("soundshare/fixture", resourceType);
      assert.equal(received.id, "soundshare/fixture");
      assert.equal(received.options.resource_type, resourceType);
      assert.equal(received.options.type, "authenticated");
      assert.equal(received.options.invalidate, true);
    }
  }
});

test("Cloudinary deletion rejects failures and unconfirmed provider responses", async () => {
  const sdk = { uploader: { destroy: async () => ({ result: "pending" }) } };
  const storage = createCloudinaryStorage(sdk);
  await assert.rejects(storage.remove("fixture", "image"));
  sdk.uploader.destroy = async () => { throw new Error("provider unavailable"); };
  await assert.rejects(storage.remove("fixture", "video"), /provider unavailable/);
});
