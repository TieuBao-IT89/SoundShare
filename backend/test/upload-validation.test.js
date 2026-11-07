import assert from "node:assert/strict";
import test from "node:test";
import { validateUpload } from "../src/validation/upload.schema.js";
import { artworkFile, audioFile, mp3 } from "./helpers/upload-fixtures.js";

test("MP3 supports raw frames and ID3 metadata but rejects a forged ID3 signature", () => {
  assert.equal(validateUpload(audioFile(), "audio").format, "mp3");
  const tagged = { ...audioFile(), buffer: Buffer.concat([Buffer.from([73, 68, 51, 4, 0, 0, 0, 0, 0, 0]), mp3]) };
  assert.equal(validateUpload(tagged, "audio").format, "mp3");
  for (const buffer of [Buffer.from("ID3not-real-audio"), mp3.subarray(0, 500)]) {
    assert.throws(() => validateUpload({ ...audioFile(), buffer }, "audio"), { code: "INVALID_FILE_TYPE" });
  }
});

test("size boundaries and filenames are checked again at the service boundary", () => {
  const buffer = Buffer.alloc(20 * 1024 * 1024);
  mp3.copy(buffer);
  assert.equal(validateUpload({ ...audioFile(), buffer }, "audio").format, "mp3");
  assert.throws(() => validateUpload({ ...audioFile(), buffer: Buffer.alloc(buffer.length + 1) }, "audio"), { code: "FILE_TOO_LARGE" });
  for (const originalname of ["../cover.png", "bad\\cover.png", "bad\u0000.png", "x".repeat(256)]) {
    assert.throws(() => validateUpload({ ...artworkFile(), originalname }, "artwork"), { code: "INVALID_FILE" });
  }
});
