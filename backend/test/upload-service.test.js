import assert from "node:assert/strict";
import test from "node:test";
import { createUploadService } from "../src/services/upload.service.js";
import { artworkFile, createFakes } from "./helpers/upload-fixtures.js";

const setup = () => {
  const fakes = createFakes();
  const service = createUploadService({ ...fakes, report: (event) => fakes.events.push(event) });
  const upload = (userId = "user_fixture") => service.upload({ userId, mediaType: "artwork", file: artworkFile(), requestId: "request_fixture" });
  return { ...fakes, service, upload };
};

test("same content from different owners gets different assets and object keys", async () => {
  const state = setup();
  const a = await state.upload();
  const b = await state.upload("user_other");
  assert.notEqual(a.asset.id, b.asset.id);
  assert.equal(state.objects.size, 2);
  assert.equal((await state.upload()).created, false);
});

test("database insert failure with confirmed absence cleans up a newly created object", async () => {
  const state = setup();
  state.records.insert = async () => { throw new Error("database failure"); };
  await assert.rejects(state.upload(), { code: "DATABASE_UNAVAILABLE" });
  assert.equal(state.calls.remove, 1);
  assert.equal(state.objects.size, 0);
  assert.equal(state.assets.size, 0);
});

test("ambiguous database state retains private objects and same-file retry reconciles them", async () => {
  const state = setup();
  const insert = state.records.insert;
  const find = state.records.findByPublicId;
  let count = 0;
  state.records.findByPublicId = async (...args) => {
    if (++count > 1) throw new Error("database unavailable");
    return find(...args);
  };
  state.records.insert = async () => { throw new Error("connection lost"); };
  await assert.rejects(state.upload(), { code: "DATABASE_UNAVAILABLE" });
  assert.equal(state.calls.remove, 0);
  assert.equal(state.objects.size, 1);
  assert.equal(state.events[0].code, "UPLOAD_RECONCILIATION_REQUIRED");
  state.records.findByPublicId = find;
  state.records.insert = insert;
  assert.equal((await state.upload()).created, true);
  assert.equal(state.calls.upload, 1);
  assert.equal(state.assets.size, 1);
});

test("lost commit acknowledgement does not delete an asset that may have committed", async () => {
  const state = setup();
  const withAssetLock = state.repository.withAssetLock;
  state.repository.withAssetLock = async (...args) => {
    await withAssetLock(...args);
    throw new Error("commit acknowledgement lost");
  };
  await assert.rejects(state.upload(), { code: "DATABASE_UNAVAILABLE" });
  assert.equal(state.calls.remove, 0);
  assert.equal(state.assets.size, 1);
  state.repository.withAssetLock = withAssetLock;
  assert.equal((await state.upload()).created, false);
});

test("mismatched storage metadata is rejected and never recorded", async () => {
  const state = setup();
  const upload = state.storage.upload;
  state.storage.upload = async (args) => { await upload(args); state.objects.get(args.publicId).bytes++; };
  await assert.rejects(state.upload(), { code: "STORAGE_VERIFICATION_FAILED" });
  assert.equal(state.calls.remove, 1);
  assert.equal(state.assets.size, 0);
});

test("failed compensation reports a safe cleanup event", async () => {
  const state = setup();
  state.records.insert = async () => { throw new Error("database unavailable"); };
  state.storage.remove = async () => { throw new Error("provider secret must not be logged"); };
  await assert.rejects(state.upload(), { code: "DATABASE_UNAVAILABLE" });
  assert.deepEqual(state.events, [{ requestId: "request_fixture", code: "UPLOAD_CLEANUP_REQUIRED" }]);
});

test("concurrent duplicate uploads return a retryable conflict and create one record", async () => {
  const state = setup();
  const first = state.upload();
  await assert.rejects(state.upload(), { code: "UPLOAD_IN_PROGRESS" });
  await first;
  assert.equal(state.calls.upload, 1);
  assert.equal((await state.upload()).created, false);
});

test("access signing failure preserves completed metadata for a safe retry", async () => {
  const state = setup();
  const sign = state.storage.createAccess;
  state.storage.createAccess = () => { throw new Error("sign failure"); };
  await assert.rejects(state.upload(), { code: "STORAGE_UNAVAILABLE" });
  assert.equal(state.assets.size, 1);
  state.storage.createAccess = sign;
  assert.equal((await state.upload()).created, false);
  assert.equal(state.calls.upload, 1);
});

test("owner deletion removes Storage before metadata and rejects a second deletion", async () => {
  const state = setup();
  const uploaded = await state.upload();
  const remove = state.storage.remove;
  state.storage.remove = async (...args) => {
    assert.equal(state.assets.size, 1);
    await remove(...args);
  };
  await state.service.remove({ id: uploaded.asset.id, userId: "user_fixture" });
  assert.equal(state.objects.size, 0);
  assert.equal(state.assets.size, 0);
  assert.equal(state.calls.delete, 1);
  await assert.rejects(state.service.remove({ id: uploaded.asset.id, userId: "user_fixture" }), { code: "MEDIA_NOT_FOUND" });
  assert.equal(state.calls.remove, 1);
});

test("foreign users cannot delete another user's asset", async () => {
  const state = setup();
  const uploaded = await state.upload();
  await assert.rejects(state.service.remove({ id: uploaded.asset.id, userId: "user_other" }), { code: "MEDIA_NOT_FOUND" });
  assert.equal(state.calls.remove, 0);
  assert.equal(state.calls.delete, 0);
  assert.equal(state.assets.size, 1);
});

test("Storage deletion failure preserves metadata for retry", async () => {
  const state = setup();
  const uploaded = await state.upload();
  state.storage.remove = async () => { throw new Error("provider secret must not escape"); };
  await assert.rejects(state.service.remove({ id: uploaded.asset.id, userId: "user_fixture" }), { code: "STORAGE_DELETE_FAILED" });
  assert.equal(state.calls.delete, 0);
  assert.equal(state.assets.size, 1);
  assert.equal(state.objects.size, 1);
});

test("database failure before deletion never contacts Storage", async () => {
  const state = setup();
  state.repository.findById = async () => { throw new Error("database unavailable"); };
  await assert.rejects(state.service.remove({ id: "fixture", userId: "user_fixture" }), { code: "DATABASE_UNAVAILABLE" });
  assert.equal(state.calls.remove, 0);
});

test("retry completes metadata deletion when Storage already removed the file", async () => {
  const state = setup();
  const uploaded = await state.upload();
  const deleteById = state.records.deleteById;
  state.records.deleteById = async () => { throw new Error("database unavailable"); };
  const request = { id: uploaded.asset.id, userId: "user_fixture", requestId: "request_delete" };
  await assert.rejects(state.service.remove(request), { code: "DATABASE_UNAVAILABLE" });
  assert.equal(state.objects.size, 0);
  assert.equal(state.assets.size, 1);
  assert.deepEqual(state.events, [{ requestId: "request_delete", code: "MEDIA_DELETE_RECONCILIATION_REQUIRED" }]);
  state.records.deleteById = deleteById;
  await state.service.remove(request);
  assert.equal(state.assets.size, 0);
  assert.equal(state.calls.remove, 2);
});

test("retry recovers a lost Storage deletion acknowledgement", async () => {
  const state = setup();
  const uploaded = await state.upload();
  const remove = state.storage.remove;
  state.storage.remove = async (...args) => { await remove(...args); throw new Error("acknowledgement lost"); };
  const request = { id: uploaded.asset.id, userId: "user_fixture" };
  await assert.rejects(state.service.remove(request), { code: "STORAGE_DELETE_FAILED" });
  assert.equal(state.assets.size, 1);
  assert.equal(state.objects.size, 0);
  state.storage.remove = remove;
  await state.service.remove(request);
  assert.equal(state.assets.size, 0);
});

test("lost deletion commit acknowledgement is reported and retry reveals no asset", async () => {
  const state = setup();
  const uploaded = await state.upload();
  const withAssetLock = state.repository.withAssetLock;
  state.repository.withAssetLock = async (...args) => {
    await withAssetLock(...args);
    throw new Error("commit acknowledgement lost");
  };
  const request = { id: uploaded.asset.id, userId: "user_fixture", requestId: "request_delete" };
  await assert.rejects(state.service.remove(request), { code: "DATABASE_UNAVAILABLE" });
  assert.equal(state.assets.size, 0);
  assert.equal(state.objects.size, 0);
  assert.equal(state.events[0].code, "MEDIA_DELETE_RECONCILIATION_REQUIRED");
  state.repository.withAssetLock = withAssetLock;
  await assert.rejects(state.service.remove(request), { code: "MEDIA_NOT_FOUND" });
  assert.equal(state.calls.remove, 1);
});

test("deletion and upload share a lock and duplicate concurrent deletion is retryable", async (t) => {
  const state = setup();
  const uploaded = await state.upload();
  let started;
  let release;
  const pending = new Promise((resolve) => { started = resolve; });
  const gate = new Promise((resolve) => { release = resolve; });
  t.after(() => release());
  const remove = state.storage.remove;
  state.storage.remove = async (...args) => { started(); await gate; await remove(...args); };
  const request = { id: uploaded.asset.id, userId: "user_fixture" };
  const deletion = state.service.remove(request);
  await pending;
  await assert.rejects(state.upload(), { code: "UPLOAD_IN_PROGRESS" });
  await assert.rejects(state.service.remove(request), { code: "MEDIA_BUSY" });
  release();
  await deletion;
  assert.equal(state.calls.remove, 1);
  assert.equal(state.assets.size, 0);
});

test("a stale deletion UUID never removes a re-upload that reused the public ID", async () => {
  const state = setup();
  const original = await state.upload();
  const withAssetLock = state.repository.withAssetLock;
  let replacement;
  let raced = false;
  state.repository.withAssetLock = async (...args) => {
    if (!raced) {
      raced = true;
      state.assets.clear();
      state.objects.clear();
      replacement = await state.upload();
    }
    return withAssetLock(...args);
  };
  await assert.rejects(state.service.remove({ id: original.asset.id, userId: "user_fixture" }), { code: "MEDIA_NOT_FOUND" });
  assert.notEqual(replacement.asset.id, original.asset.id);
  assert.equal(state.calls.remove, 0);
  assert.equal(state.assets.size, 1);
  assert.equal(state.objects.size, 1);
});
