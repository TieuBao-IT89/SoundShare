import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { once } from "node:events";
import test from "node:test";
import { createApp } from "../src/app.js";
import { createCommunityRepository } from "../src/repositories/community.repository.js";
import { createCommunityService } from "../src/services/community.service.js";
import {
  communityDatabase,
  clerkOptions,
  token,
} from "./helpers/community-fixture.js";

const REFERENCE = new Date("2026-11-06T16:00:00.000Z");
const ago = (days, hour = 5) => {
  const date = new Date(REFERENCE);
  date.setUTCDate(date.getUTCDate() - days);
  date.setUTCHours(hour, 0, 0, 0);
  return date;
};

const fixture = async (t) => {
  const { db, pool, close } = await communityDatabase();
  t.after(close);
  const repository = createCommunityRepository(pool);
  const storage = {
    createAccess: () => ({
      url: "https://fixture.invalid/artwork",
      expiresAt: new Date(REFERENCE.getTime() + 300000).toISOString(),
    }),
  };
  const serviceAt = (at = REFERENCE) =>
    createCommunityService({ repository, storage, now: () => new Date(at) });
  const user = async (subject, username = subject) =>
    (
      await db.query(
        "INSERT INTO users(clerk_user_id,username,display_name) VALUES ($1,$2,$3) RETURNING *",
        [subject, username, `Fixture ${subject}`],
      )
    ).rows[0];
  const track = async (
    owner,
    genre,
    { visibility = "public", status = "active", createdAt = ago(3) } = {},
  ) => {
    const asset = (
      await db.query(
        `INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes)
         VALUES ($1,'audio',$2,'https://fixture.invalid/audio','video','mp3',100) RETURNING id`,
        [owner.clerk_user_id, randomUUID()],
      )
    ).rows[0];
    return (
      await db.query(
        `INSERT INTO private_tracks(clerk_user_id,audio_asset_id,title,artist,genre,visibility,status,rights_confirmed_at,created_at)
         VALUES ($1,$2,$3,'Fixture creator',$4,$5,$6,CASE WHEN $5::varchar='public' THEN $7::timestamptz ELSE NULL END,$7)
         RETURNING *`,
        [
          owner.clerk_user_id,
          asset.id,
          `Fixture ${genre} ${randomUUID()}`,
          genre,
          visibility,
          status,
          createdAt,
        ],
      )
    ).rows[0];
  };
  const play = async (listener, song, at, { valid = true } = {}) => {
    const session = (
      await db.query(
        `INSERT INTO playback_sessions(user_id,track_id,started_at,last_heartbeat_at,credited_ms,threshold_ms,is_valid)
         VALUES ($1,$2,$3,$3,$4,30000,$5) RETURNING id`,
        [listener.id, song.id, at, valid ? 30000 : 1000, valid],
      )
    ).rows[0];
    if (valid)
      await db.query(
        `INSERT INTO valid_play_events(session_id,user_id,track_id,dedup_bucket,created_at)
         VALUES ($1,$2,$3,$4,$5)`,
        [session.id, listener.id, song.id, Math.floor(at.getTime() / 1800000), at],
      );
    return session;
  };
  const like = (listener, song) =>
    db.query("INSERT INTO track_likes(user_id,track_id) VALUES ($1,$2)", [
      listener.id,
      song.id,
    ]);
  const save = (listener, song) =>
    db.query("INSERT INTO saved_tracks(user_id,track_id) VALUES ($1,$2)", [
      listener.id,
      song.id,
    ]);
  const follow = (listener, creator) =>
    db.query("INSERT INTO user_follows(follower_id,following_id) VALUES ($1,$2)", [
      listener.id,
      creator.id,
    ]);
  const home = (listener, options = {}, at = REFERENCE) =>
    serviceAt(at).home(listener.clerk_user_id, options);
  return { db, repository, user, track, play, like, save, follow, home };
};

test("recommendations learn the listener's time-of-day preferences from valid history", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const nightSource = await f.track(listener, "Lo-Fi", { visibility: "private" });
  const daySource = await f.track(listener, "Pop", { visibility: "private" });
  const lofi = await f.track(creator, "lo-fi");
  const pop = await f.track(creator, "POP");
  for (const days of [2, 3, 4]) {
    await f.play(listener, nightSource, ago(days, 16)); // 23:00 in Vietnam.
    await f.play(listener, daySource, ago(days, 5)); // 12:00 in Vietnam.
  }

  const night = await f.home(listener, { utcOffsetMinutes: 420 });
  assert.equal(night.recommended[0].id, lofi.id);
  assert.equal(night.recommended[0].recommendationReason.code, "listening-time");
  assert.equal(night.recommendationReason, "listening-preferences-v1");
  assert.deepEqual(night.recommendation, {
    version: "taste-v1",
    strategy: "personalized",
    daypart: "night",
    utcOffsetMinutes: 420,
    experimental: true,
  });

  const daytime = await f.home(listener, { utcOffsetMinutes: 420 }, ago(0, 5));
  assert.equal(daytime.recommended[0].id, pop.id);
  assert.equal(daytime.recommendation.daypart, "afternoon");
  assert.ok(
    night.recommended.every((song) => song.visibility === "public"),
    "own private history can inform taste without exposing its tracks",
  );
  assert.ok(!JSON.stringify(night.recommended).includes(nightSource.title));
});

test("hearing one song in morning and night preserves learned evidence for both contexts", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const source = await f.track(listener, "Lo-fi", { visibility: "private" });
  const lofi = await f.track(creator, "Lo-fi", { createdAt: ago(5) });
  await f.track(creator, "Pop", { createdAt: ago(1) });
  for (const days of [2, 3]) {
    await f.play(listener, source, ago(days, 4)); // 11:00 in Vietnam.
    await f.play(listener, source, ago(days, 16)); // 23:00 on the same local day.
  }
  for (const [hour, daypart] of [[4, "morning"], [16, "night"]]) {
    const result = await f.home(listener, { utcOffsetMinutes: 420 }, ago(0, hour));
    assert.equal(result.recommendation.daypart, daypart);
    assert.equal(result.recommended[0].id, lofi.id);
    assert.equal(result.recommended[0].recommendationReason.code, "listening-time");
    assert.equal(result.recommended[0].recommendationReason.daypart, daypart);
  }
});

test("favorites and saves personalize distinct users without sharing their private taste data", async (t) => {
  const f = await fixture(t);
  const a = await f.user("listener_a");
  const b = await f.user("listener_b");
  const creator = await f.user("creator");
  const liked = await f.track(a, " Lo-Fi ", { visibility: "private" });
  const saved = await f.track(b, "Acoustic", { visibility: "private" });
  const lofi = await f.track(creator, "lo-fi", { createdAt: ago(20) });
  const acoustic = await f.track(creator, "ACOUSTIC", { createdAt: ago(20) });
  for (let index = 0; index < 44; index++)
    await f.track(creator, "Pop", { createdAt: ago(1) });
  await f.like(a, liked);
  await f.save(b, saved);

  const aHome = await f.home(a);
  const bHome = await f.home(b);
  assert.equal(aHome.recommended[0].id, lofi.id);
  assert.equal(aHome.recommended[0].recommendationReason.code, "liked-genre");
  assert.equal(bHome.recommended[0].id, acoustic.id);
  assert.equal(bHome.recommended[0].recommendationReason.code, "saved-genre");
  assert.equal(aHome.recommended.length, 8);
  assert.equal(new Set(aHome.recommended.map((song) => song.id)).size, 8);
  const serialized = JSON.stringify([aHome, bHome]);
  assert.ok(!serialized.includes(liked.title));
  assert.ok(!serialized.includes(saved.title));
  assert.ok(!serialized.includes("clerk_user_id"));
  assert.ok(!serialized.includes("listener_a"));
  assert.ok(!serialized.includes("listener_b"));
});

test("following boosts a creator and cold start uses real newest releases with an honest label", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const other = await f.user("other_creator");
  const older = await f.track(creator, "Indie", { createdAt: ago(5) });
  const newest = await f.track(other, "Electronic", { createdAt: ago(1) });
  const initial = await f.home(listener);
  assert.equal(initial.recommended[0].id, newest.id);
  assert.equal(initial.recommendation.strategy, "new-releases");
  assert.equal(initial.recommendationReason, "new-releases");
  assert.equal(initial.recommended[0].recommendationReason.code, "new-release");
  await f.follow(listener, creator);
  const followed = await f.home(listener);
  assert.equal(followed.recommended[0].id, older.id);
  assert.equal(followed.recommended[0].recommendationReason.code, "following");
  assert.equal(followed.recommendation.strategy, "personalized");
  await f.db.query("DELETE FROM user_follows WHERE follower_id=$1", [listener.id]);
  assert.equal((await f.home(listener)).recommended[0].id, newest.id);
});

test("unheard sessions and history older than the learning window do not create personalized evidence", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const source = await f.track(listener, "Lo-fi", { visibility: "private" });
  await f.track(creator, "Lo-fi", { createdAt: ago(5) });
  const newest = await f.track(creator, "Pop", { createdAt: ago(1) });
  await f.play(listener, source, ago(1), { valid: false });
  await f.play(listener, source, ago(100));
  const result = await f.home(listener);
  assert.equal(result.recommended[0].id, newest.id);
  assert.equal(result.recommendation.strategy, "new-releases");
  assert.equal(result.recommendationReason, "new-releases");
});

test("recent valid history outweighs older plays and one observation does not establish a time habit", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const olderSource = await f.track(listener, "Lo-fi", { visibility: "private" });
  const recentSource = await f.track(listener, "Acoustic", { visibility: "private" });
  const olderGenre = await f.track(creator, "Lo-fi");
  const recentGenre = await f.track(creator, "Acoustic");
  await f.play(listener, recentSource, ago(2, 5));

  const singleObservation = await f.home(listener, { utcOffsetMinutes: 420 }, ago(0, 5));
  assert.equal(singleObservation.recommendation.daypart, "afternoon");
  assert.equal(singleObservation.recommended[0].id, recentGenre.id);
  assert.equal(singleObservation.recommended[0].recommendationReason.code, "listening-history");

  for (const days of [70, 71, 72])
    await f.play(listener, olderSource, ago(days, 5));
  const result = await f.home(listener, { utcOffsetMinutes: 420 });
  assert.equal(result.recommendation.daypart, "night");
  assert.equal(result.recommended[0].id, recentGenre.id);
  assert.equal(result.recommended[0].recommendationReason.code, "listening-history");
  assert.ok(result.recommended.some((song) => song.id === olderGenre.id));
  assert.ok(result.recommended.every((song) => song.recommendationReason.code !== "listening-time"));
});

test("repeat plays in one local day cannot overwhelm evidence from distinct listening days", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const repeated = await f.track(listener, "Lo-fi", { visibility: "private" });
  const regular = await f.track(listener, "Acoustic", { visibility: "private" });
  await f.track(creator, "Lo-fi", { createdAt: ago(1) });
  const acoustic = await f.track(creator, "Acoustic", { createdAt: ago(2) });
  for (const hour of [3, 4, 5, 6, 7])
    await f.play(listener, repeated, ago(1, hour));
  await f.play(listener, regular, ago(1, 4));
  await f.play(listener, regular, ago(2, 4));
  const result = await f.home(listener);
  assert.equal(result.recommended[0].id, acoustic.id);
  assert.equal(result.recommended[0].recommendationReason.code, "listening-history");
});

test("recommendations exclude unavailable songs, creators and inaccessible foreign taste signals", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const creator = await f.user("creator");
  const foreign = await f.user("foreign_creator");
  const hiddenCreator = await f.user("hidden_creator");
  const unpublishedCreator = await f.user("unpublished_creator", null);
  const source = await f.track(foreign, "Lo-fi");
  await f.like(listener, source);
  await f.save(listener, source);
  await f.play(listener, source, ago(1));
  await f.db.query("UPDATE private_tracks SET visibility='private' WHERE id=$1", [source.id]);
  const older = await f.track(creator, "Lo-fi", { createdAt: ago(5) });
  const newest = await f.track(creator, "Pop", { createdAt: ago(1) });
  for (const options of [
    { visibility: "private" },
    { status: "hidden" },
    { status: "deleted" },
  ])
    await f.track(foreign, "Unavailable sentinel", options);
  await f.track(hiddenCreator, "Hidden profile sentinel");
  await f.track(unpublishedCreator, "Unpublished profile sentinel");
  await f.db.query("UPDATE users SET profile_status='hidden' WHERE id=$1", [hiddenCreator.id]);

  const result = await f.home(listener);
  assert.equal(result.recommended[0].id, newest.id);
  assert.deepEqual(new Set(result.recommended.map((song) => song.id)), new Set([newest.id, older.id]));
  assert.equal(result.recommendation.strategy, "new-releases");
  assert.ok(!JSON.stringify(result.recommended).includes("sentinel"));
  const repeated = await f.home(listener);
  assert.deepEqual(repeated.recommended.map((song) => song.id), result.recommended.map((song) => song.id));
});

test("an empty public catalog stays empty even when the listener has private favorites", async (t) => {
  const f = await fixture(t);
  const listener = await f.user("listener");
  const source = await f.track(listener, "Lo-fi", { visibility: "private" });
  await f.like(listener, source);
  const result = await f.home(listener);
  assert.deepEqual(result.recommended, []);
  assert.equal(result.recommendation.strategy, "new-releases");
  assert.equal(result.recommendationReason, "new-releases");
});

test("personalized home validates timezone context, authenticates requests, prevents caching and rate limits", async (t) => {
  const calls = [];
  const app = createApp({
    communityService: {
      home: async (owner, options) => {
        calls.push({ owner, options });
        return { recommended: [] };
      },
    },
    clerkOptions,
    logging: false,
  });
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(() => new Promise((resolve) => {
    server.close(resolve);
    server.closeAllConnections();
  }));
  const request = (query = "", subject = "listener") => fetch(
    `http://127.0.0.1:${server.address().port}/api/v1/discover/home${query}`,
    { headers: subject ? { Authorization: `Bearer ${token(subject)}` } : {} },
  );
  assert.equal((await request("", null)).status, 401);
  const response = await request();
  assert.equal(response.status, 200);
  assert.equal(response.headers.get("cache-control"), "no-store");
  assert.deepEqual(calls.at(-1), { owner: "listener", options: { utcOffsetMinutes: 420 } });
  for (const offset of [-720, 0, 840]) {
    assert.equal((await request(`?utcOffsetMinutes=${offset}`)).status, 200);
    assert.equal(calls.at(-1).options.utcOffsetMinutes, offset);
  }
  for (const query of [
    "?utcOffsetMinutes=-721", "?utcOffsetMinutes=841", "?utcOffsetMinutes=1.5",
    "?utcOffsetMinutes=abc", "?utcOffsetMinutes=0&utcOffsetMinutes=1",
    "?utcOffsetMinutes=", "?utcOffsetMinutes=%20", "?utcOffsetMinutes=1e2",
    "?userId=foreign", "?timezone=Asia%2FHo_Chi_Minh",
  ])
    assert.equal((await request(query)).status, 400, query);
  for (let index = 0; index < 60; index++)
    assert.equal((await request("", "limited_listener")).status, 200);
  const blocked = await request("", "limited_listener");
  assert.equal(blocked.status, 429);
  assert.ok(Number(blocked.headers.get("retry-after")) > 0);
});

test("recommendation failures expose a safe service error instead of database details", async () => {
  const secret = "postgres://private-user:private-password@internal.example/database";
  const service = createCommunityService({
    repository: {
      tracks: async () => [],
      trending: async () => [],
      recommendations: async () => { throw new Error(secret); },
    },
    storage: {},
    now: () => REFERENCE,
  });
  await assert.rejects(service.home("listener"), (error) => {
    assert.equal(error.statusCode, 503);
    assert.equal(error.code, "COMMUNITY_UNAVAILABLE");
    assert.ok(!JSON.stringify(error).includes(secret));
    assert.ok(!error.message.includes(secret));
    return true;
  });
});
