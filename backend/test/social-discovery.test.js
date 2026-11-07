import test from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { once } from "node:events";
import {
  communityDatabase,
  clerkOptions,
  token,
} from "./helpers/community-fixture.js";
import { createCommunityRepository } from "../src/repositories/community.repository.js";
import { createSocialRepository } from "../src/repositories/social.repository.js";
import { createSocialService } from "../src/services/social.service.js";
import { createNotificationDelivery } from "../src/services/notification-delivery.service.js";
import { createModerationService } from "../src/services/moderation.service.js";
import { createApp } from "../src/app.js";
test("hidden root author hides the thread, counts and linked notifications", async (t) => {
  const f = await fixture(t);
  const root = await f.service.addComment("listener", f.song.id, {
    content: "Fixture root",
  });
  const reply = await f.service.reply("another", root.id, {
    content: "Fixture reply",
  });
  await f.worker.process();
  await f.db.query("UPDATE users SET profile_status='hidden' WHERE id=$1", [
    f.b.id,
  ]);
  assert.equal(
    (await f.service.comments("creator", f.song.id, { limit: 15 })).total,
    0,
  );
  await assert.rejects(
    () =>
      f.service.comments("creator", f.song.id, {
        limit: 15,
        parentId: root.id,
      }),
    { statusCode: 404 },
  );
  await assert.rejects(() => f.service.commentContext("creator", reply.id), {
    statusCode: 404,
  });
  assert.equal(
    (await f.service.notifications("creator", { limit: 15, unread: "false" }))
      .items.length,
    0,
  );
});
test("delivery failures roll back, persist retry and deliver once after recovery", async (t) => {
  const f = await fixture(t);
  await f.db.query("DELETE FROM social_outbox");
  await f.community.follow("listener", f.a.id, true);
  let fail = true;
  const failing = createNotificationDelivery({
    tx: (fn) =>
      f.repository.tx((c) =>
        fn({
          query: (sql, params) => {
            if (fail && sql.startsWith("INSERT INTO notifications")) {
              fail = false;
              throw new Error("Fixture failure");
            }
            return c.query(sql, params);
          },
        }),
      ),
  });
  await failing.process({ batches: 1 });
  let job = (await f.db.query("SELECT * FROM social_outbox")).rows[0];
  assert.equal(job.attempts, 1);
  assert.equal(job.completed_at, null);
  assert.equal((await f.service.unread("creator")).count, 0);
  await f.db.query(
    "UPDATE social_outbox SET available_at=NOW()-INTERVAL '1 minute'",
  );
  await f.worker.process();
  await f.worker.process();
  assert.equal((await f.service.unread("creator")).count, 1);
  job = (await f.db.query("SELECT * FROM social_outbox")).rows[0];
  assert.ok(job.completed_at);
  assert.equal(job.attempts, 2);
});
test("comment cursor pages are stable; notification reply links resolve an authorized thread", async (t) => {
  const f = await fixture(t);
  const comments = [];
  for (let i = 0; i < 6; i++)
    comments.push(
      await f.service.addComment(i % 2 ? "listener" : "another", f.song.id, {
        content: `Fixture comment ${i}`,
      }),
    );
  // pg Date truncates microseconds; cursors must retain database precision.
  await f.db.query(
    "UPDATE track_comments SET created_at='2026-11-08T12:00:00.123456Z'",
  );
  const page = await f.service.comments("creator", f.song.id, { limit: 2 });
  assert.equal(page.items.length, 2);
  assert.ok(page.nextCursor);
  const next = await f.service.comments("creator", f.song.id, {
    limit: 2,
    cursor: page.nextCursor,
  });
  assert.ok(next.items.every((v) => !page.items.some((p) => p.id === v.id)));
  assert.equal(next.items.length, 2);
  const last = await f.service.comments("creator", f.song.id, {
    limit: 2,
    cursor: next.nextCursor,
  });
  assert.equal(
    new Set([...page.items, ...next.items, ...last.items].map((v) => v.id))
      .size,
    6,
  );
  await assert.rejects(
    () =>
      f.service.comments("creator", randomUUID(), {
        limit: 2,
        cursor: page.nextCursor,
      }),
    { statusCode: 400 },
  );
  const reply = await f.service.reply("creator", comments[0].id, {
    content: "Fixture response",
  });
  const context = await f.service.commentContext("listener", reply.id);
  assert.equal(context.rootId, comments[0].id);
  assert.equal(context.trackId, f.song.id);
  await f.worker.process();
  const inbox = await f.service.notifications("another", {
    limit: 15,
    unread: "false",
  });
  assert.ok(
    inbox.items.some((n) => n.type === "reply" && n.commentId === reply.id),
  );
  await f.db.query(
    "UPDATE private_tracks SET visibility='private' WHERE id=$1",
    [f.song.id],
  );
  await assert.rejects(() => f.service.commentContext("listener", reply.id), {
    statusCode: 404,
  });
  assert.equal(
    (await f.service.notifications("another", { limit: 15, unread: "false" }))
      .items.length,
    0,
  );
});
const fixture = async (t) => {
  const { db, pool, close } = await communityDatabase();
  t.after(close);
  const community = createCommunityRepository(pool),
    repository = createSocialRepository(pool);
  const service = createSocialService({
    repository,
    communityRepository: community,
    storage: {
      createAccess: () => ({ url: "https://fixture.invalid/artwork" }),
    },
  });
  const worker = createNotificationDelivery(repository);
  const user = async (name) =>
    (
      await db.query(
        "INSERT INTO users(clerk_user_id,username,display_name) VALUES($1,$2,$3) RETURNING *",
        [name, name, name],
      )
    ).rows[0];
  const a = await user("creator"),
    b = await user("listener"),
    other = await user("another");
  const track = async (owner = a, visibility = "public") => {
    const asset = (
      await db.query(
        "INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes) VALUES($1,'audio',$2,'https://fixture.invalid/audio','video','mp3',100) RETURNING id",
        [owner.clerk_user_id, randomUUID()],
      )
    ).rows[0];
    return (
      await db.query(
        "INSERT INTO private_tracks(clerk_user_id,audio_asset_id,title,artist,genre,visibility,rights_confirmed_at,duration_seconds) VALUES($1,$2,'Fixture song','Fixture creator','Indie',$3,CASE WHEN $3::varchar='public' THEN NOW() END,60) RETURNING *",
        [owner.clerk_user_id, asset.id, visibility],
      )
    ).rows[0];
  };
  const song = await track();
  return {
    db,
    pool,
    community,
    repository,
    service,
    worker,
    user,
    track,
    song,
    a,
    b,
    other,
  };
};
const opts = { limit: 15, mode: "for-you" };
test("Shorts stable snapshot, strict following, refreshed visibility and no playback side effects", async (t) => {
  const f = await fixture(t);
  await f.track();
  await f.track(f.a, "private");
  await f.track(f.other);
  assert.equal(
    (await f.service.feed("listener", { ...opts, mode: "following" })).items
      .length,
    0,
  );
  await f.community.follow("listener", f.a.id, true);
  const page = await f.service.feed("listener", {
    ...opts,
    mode: "following",
    limit: 1,
  });
  assert.equal(page.items.length, 1);
  assert.ok(page.nextCursor);
  const inserted = await f.track();
  const next = await f.service.feed("listener", {
    ...opts,
    mode: "following",
    cursor: page.nextCursor,
  });
  assert.ok(
    next.items.every(
      (v) =>
        v.id !== page.items[0].id &&
        v.id !== inserted.id &&
        v.uploader.id === f.a.id,
    ),
  );
  assert.ok(next.items.every((v) => !("audioUrl" in v) && !("url" in v)));
  await assert.rejects(
    () =>
      f.service.feed("another", {
        ...opts,
        mode: "following",
        cursor: page.nextCursor,
      }),
    { statusCode: 410 },
  );
  await f.community.follow("listener", f.a.id, false);
  assert.equal(
    (
      await f.service.feed("listener", {
        ...opts,
        mode: "following",
        cursor: page.nextCursor,
      })
    ).items.length,
    0,
  );
  const feed = await f.service.feed("listener", opts);
  assert.ok(feed.items.every((v) => v.visibility === "public"));
  assert.equal(
    (await f.db.query("SELECT count(*) AS n FROM playback_sessions")).rows[0].n,
    0,
  );
  await f.db.query(
    "UPDATE private_tracks SET visibility='private' WHERE id=$1",
    [f.song.id],
  );
  await assert.rejects(() => f.service.song("creator", f.song.id), {
    statusCode: 404,
  });
});
test("comments: one reply level, owner deletion, tombstone children, spam, privacy and moderation", async (t) => {
  const f = await fixture(t);
  const c = await f.service.addComment("listener", f.song.id, {
    content: "A real comment",
  });
  const reply = await f.service.reply("another", c.id, { content: "A reply" });
  await assert.rejects(
    () => f.service.reply("creator", reply.id, { content: "Too deep" }),
    { statusCode: 400 },
  );
  await assert.rejects(
    () =>
      f.service.addComment("listener", f.song.id, {
        content: "A real comment",
      }),
    { statusCode: 429 },
  );
  await assert.rejects(() => f.service.deleteComment("another", c.id), {
    statusCode: 404,
  });
  await f.service.likeComment("creator", reply.id, true);
  await f.service.likeComment("creator", reply.id, true);
  const result = await f.service.comments("creator", f.song.id, {
    limit: 15,
    parentId: c.id,
  });
  assert.equal(result.items[0].likeCount, 1);
  assert.equal(result.total, 2);
  await f.service.deleteComment("listener", c.id);
  const list = await f.service.comments("creator", f.song.id, { limit: 15 });
  assert.equal(list.items[0].deleted, true);
  assert.equal(list.items[0].content, "");
  assert.equal(list.total, 1);
  await assert.rejects(
    () => f.service.reply("creator", c.id, { content: "Deleted parent" }),
    { statusCode: 404 },
  );
  await f.service.reportComment("creator", reply.id, {
    reason: "spam",
    details: "",
  });
  const report = (
    await f.db.query("SELECT id FROM content_reports WHERE comment_id=$1", [
      reply.id,
    ])
  ).rows[0];
  await createModerationService(f.pool).review(report.id, "hide");
  assert.equal(
    (
      await f.service.comments("creator", f.song.id, {
        limit: 15,
        parentId: c.id,
      })
    ).items.length,
    0,
  );
  await f.db.query(
    "UPDATE private_tracks SET visibility='private' WHERE id=$1",
    [f.song.id],
  );
  await assert.rejects(
    () => f.service.comments("listener", f.song.id, { limit: 15 }),
    { statusCode: 404 },
  );
  await assert.rejects(
    () => f.service.likeComment("listener", reply.id, true),
    { statusCode: 404 },
  );
});
test("outbox: transactional events, idempotent follows/likes, preferences, read status, cross-account and hidden suppression", async (t) => {
  const f = await fixture(t);
  await f.community.follow("listener", f.a.id, true);
  await f.community.follow("listener", f.a.id, true);
  await f.community.follow("listener", f.a.id, false);
  await f.community.follow("listener", f.a.id, true);
  await f.community.interact("listener", f.song.id, "like", true);
  await f.community.interact("listener", f.song.id, "like", false);
  await f.community.interact("listener", f.song.id, "like", true);
  await f.service.addComment("listener", f.song.id, {
    content: "Hello creator",
  });
  await f.worker.process();
  await f.worker.process();
  const pending = (
    await f.db.query("SELECT * FROM social_outbox WHERE completed_at IS NULL")
  ).rows;
  assert.equal(pending.length, 0, JSON.stringify(pending));
  const inbox = await f.service.notifications("creator", {
    limit: 20,
    unread: "false",
  });
  assert.equal(inbox.items.length, 3);
  assert.equal((await f.service.unread("creator")).count, 3);
  await assert.rejects(() => f.service.read("listener", inbox.items[0].id), {
    statusCode: 404,
  });
  await f.service.read("creator", inbox.items[0].id);
  assert.equal((await f.service.unread("creator")).count, 2);
  await f.service.preferences("creator", { likes: false });
  await f.community.interact("another", f.song.id, "like", true);
  await f.worker.process();
  assert.equal(
    (await f.service.notifications("creator", { limit: 20, unread: "false" }))
      .items.length,
    3,
  );
  await f.db.query(
    "UPDATE private_tracks SET visibility='private' WHERE id=$1",
    [f.song.id],
  );
  assert.equal(
    (await f.service.notifications("creator", { limit: 20, unread: "false" }))
      .items.length,
    1,
  );
  await f.service.read("creator");
  assert.equal((await f.service.unread("creator")).count, 0);
});
test("publish fanout is bounded, durable, first transition only; private upload and metadata edits do not notify", async (t) => {
  const f = await fixture(t);
  for (let i = 0; i < 102; i++) {
    const u = await f.user(`fan${i}`);
    await f.community.follow(u.clerk_user_id, f.a.id, true);
  }
  const song = await f.track(f.a, "private");
  await f.service.preferences("fan0", { newTracks: false });
  await f.db.query(
    "UPDATE private_tracks SET visibility='public',rights_confirmed_at=NOW() WHERE id=$1",
    [song.id],
  );
  await f.db.query(
    "UPDATE private_tracks SET title='Edited title' WHERE id=$1",
    [song.id],
  );
  // Process earlier follow events, then only one publication batch.
  await f.worker.process({ batches: 50 });
  await f.worker.process({ batches: 50 });
  await f.worker.process({ batches: 5 });
  const job = (
    await f.db.query("SELECT * FROM social_outbox WHERE event_key=$1", [
      `publish:${song.id}`,
    ])
  ).rows[0];
  assert.ok(job.completed_at);
  assert.equal(job.attempts, 2);
  assert.equal(
    (
      await f.db.query(
        "SELECT count(*) AS n FROM notifications WHERE track_id=$1 AND type='new_track'",
        [song.id],
      )
    ).rows[0].n,
    101,
  );
  await f.db.query(
    "UPDATE private_tracks SET visibility='private' WHERE id=$1",
    [song.id],
  );
  await f.db.query(
    "UPDATE private_tracks SET visibility='public' WHERE id=$1",
    [song.id],
  );
  await f.worker.process();
  assert.equal(
    (
      await f.db.query(
        "SELECT count(*) AS n FROM social_outbox WHERE event_key=$1",
        [`publish:${song.id}`],
      )
    ).rows[0].n,
    1,
  );
});
test("HTTP contracts enforce Clerk, reject untrusted recipient and unsafe text, persist read-all", async (t) => {
  const f = await fixture(t);
  const app = createApp({
    socialService: f.service,
    clerkOptions,
    logging: false,
  });
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(() => server.close());
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;
  const request = (path, { method = "GET", body, auth = true } = {}) =>
    fetch(base + path, {
      method,
      headers: {
        ...(auth ? { Authorization: `Bearer ${token("listener")}` } : {}),
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  assert.equal((await request("/shorts/feed", { auth: false })).status, 401);
  assert.equal((await request("/notifications?userId=" + f.a.id)).status, 400);
  for (const content of [" ", "a".repeat(1001), "bad\u0000text"])
    assert.equal(
      (
        await request(`/community/songs/${f.song.id}/comments`, {
          method: "POST",
          body: { content },
        })
      ).status,
      400,
    );
  const response = await request(`/community/songs/${f.song.id}/comments`, {
    method: "POST",
    body: { content: "<script>plain text only</script>" },
  });
  assert.equal(response.status, 201);
  assert.equal((await request("/shorts/feed?cursor=broken")).status, 400);
  assert.equal(
    (await request("/notifications/read-all", { method: "PATCH" })).status,
    204,
  );
});
