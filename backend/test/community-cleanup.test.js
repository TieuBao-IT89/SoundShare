import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import test from "node:test";
import { communityDatabase } from "./helpers/community-fixture.js";
import { createTrackRepository } from "../src/repositories/track.repository.js";
import { createCommunityRepository } from "../src/repositories/community.repository.js";
import { createMediaRepository } from "../src/repositories/media.repository.js";
import { createUploadService } from "../src/services/upload.service.js";
import { createMediaCleanupService } from "../src/services/media-cleanup.service.js";

test("Owned deletion removes the track atomically and retries failed Storage cleanup without losing the job", async (t) => {
  const { db, pool, close } = await communityDatabase();
  t.after(close);
  const tracks = createTrackRepository(pool),
    community = createCommunityRepository(pool);
  await tracks.ensureUser("fixture_owner");
  const asset = async (kind) =>
    (
      await db.query(
        `INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes)
    VALUES ('fixture_owner',$1,$2,'https://fixture.invalid/unsigned',$3,$4,100) RETURNING *`,
        [
          kind,
          randomUUID(),
          kind === "audio" ? "video" : "image",
          kind === "audio" ? "mp3" : "png",
        ],
      )
    ).rows[0];
  const audio = await asset("audio");
  const made = await tracks.create("fixture_owner", {
    audioAssetId: audio.id,
    title: "Fixture recording",
    artist: "Fixture",
    genre: "Indie",
    description: "",
  });
  await community.deleteTrack("fixture_owner", made.row.id);
  assert.equal(await community.track("fixture_owner", made.row.id), null);
  assert.equal(await community.deleteTrack("foreign_owner", made.row.id), null);
  let fail = true;
  const removed = [];
  const storage = {
    remove: async (key) => {
      if (fail) throw new Error("fixture-storage-down");
      removed.push(key);
    },
  };
  const uploads = createUploadService({
    repository: createMediaRepository(pool),
    storage,
    report: () => {},
  });
  const cleanup = createMediaCleanupService({ pool, uploadService: uploads });
  assert.equal(await cleanup.process(), 1);
  assert.equal(
    (await db.query("SELECT attempts,last_error_code FROM media_cleanup_jobs"))
      .rows[0].attempts,
    1,
  );
  assert.equal(
    (
      await db.query(
        "SELECT count(*)::int AS n FROM media_assets WHERE id=$1",
        [audio.id],
      )
    ).rows[0].n,
    1,
  );
  fail = false;
  await db.query(
    "UPDATE media_cleanup_jobs SET last_attempt_at=NOW()-INTERVAL '2 minutes'",
  );
  assert.equal(await cleanup.process(), 0);
  assert.deepEqual(removed, [audio.public_id]);
  assert.equal(
    (
      await db.query(
        "SELECT count(*)::int AS n FROM media_assets WHERE id=$1",
        [audio.id],
      )
    ).rows[0].n,
    0,
  );
  assert.ok(
    await community.deleteTrack("fixture_owner", made.row.id),
    "deletion receipt supports retry after cleanup",
  );

  const shared = await asset("artwork");
  const nextAudio = await asset("audio");
  const next = await tracks.create("fixture_owner", {
    audioAssetId: nextAudio.id,
    artworkAssetId: shared.id,
    title: "Next fixture",
    artist: "Fixture",
    genre: "Indie",
    description: "",
  });
  await community.updateProfile("fixture_owner", {
    username: "fixture_owner",
    displayName: "Fixture",
    bio: "",
    avatarAssetId: shared.id,
  });
  await community.deleteTrack("fixture_owner", next.row.id);
  assert.equal(await cleanup.process(), 0);
  assert.ok(
    !removed.includes(shared.public_id),
    "profile artwork is never removed from Storage",
  );
  assert.equal(
    (
      await db.query(
        "SELECT count(*)::int AS n FROM media_assets WHERE id=$1",
        [shared.id],
      )
    ).rows[0].n,
    1,
  );
  await assert.rejects(
    uploads.remove({ id: shared.id, userId: "fixture_owner" }),
    (error) => error.code === "MEDIA_IN_USE",
  );
});
