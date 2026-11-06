import assert from "node:assert/strict";
import { once } from "node:events";
import { randomUUID } from "node:crypto";
import test from "node:test";
import { createApp } from "../src/app.js";
import { createCommunityRepository } from "../src/repositories/community.repository.js";
import { createCommunityService } from "../src/services/community.service.js";
import { createModerationService } from "../src/services/moderation.service.js";
import { parse } from "../src/validation/track.schema.js";
import { profileSchema } from "../src/validation/community.schema.js";
import {
  communityDatabase,
  clerkOptions,
  token,
} from "./helpers/community-fixture.js";

test("username policy normalizes handles, preserves Unicode names and rejects reserved/unsafe input", () => {
  const input = {
    username: "@TQD.MUSIC",
    displayName: "Trần Quốc Dũng",
    bio: "",
  };
  assert.equal(parse(profileSchema, input).username, "tqd.music");
  assert.equal(
    parse(profileSchema, { ...input, bio: "Dòng một\nDòng hai" }).bio,
    "Dòng một\nDòng hai",
  );
  assert.throws(() =>
    parse(profileSchema, { ...input, bio: "hidden\u0000value" }),
  );
  for (const username of [
    "ab",
    "admin",
    "Support",
    ".hello",
    "hello.",
    "hêllo",
    "a b",
    "a".repeat(25),
  ])
    assert.throws(() => parse(profileSchema, { ...input, username }));
  assert.throws(() =>
    parse(profileSchema, { ...input, clerkUserId: "foreign" }),
  );
});

test("V3 migrations and community API work against isolated PostgreSQL with verified Clerk identities", async (t) => {
  const { db, pool, close } = await communityDatabase();
  t.after(close);
  const repository = createCommunityRepository(pool);
  const storage = {
    createAccess: (asset) => ({
      url: `https://fixture.invalid/${asset.public_id}`,
      expiresAt: new Date(Date.now() + 300000).toISOString(),
    }),
    find: async () => ({ duration: 60 }),
  };
  const service = createCommunityService({ repository, storage });
  const app = createApp({
    communityService: service,
    clerkOptions,
    logging: false,
  });
  const server = app.listen(0, "127.0.0.1");
  await once(server, "listening");
  t.after(
    () =>
      new Promise((resolve) => {
        server.close(resolve);
        server.closeAllConnections();
      }),
  );
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;
  const request = (path, method = "GET", body, subject = "user_a") =>
    fetch(base + path, {
      method,
      headers: {
        ...(subject ? { Authorization: `Bearer ${token(subject)}` } : {}),
        ...(body ? { "Content-Type": "application/json" } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  const data = async (path) => (await (await request(path)).json()).data;
  for (const path of ["/users/me", "/community/search", "/discover/trending"])
    assert.equal((await request(path, "GET", undefined, null)).status, 401);
  const a = await data("/users/me");
  await request("/users/me", "GET", undefined, "user_b");
  const profile = {
    username: "tqd.music",
    displayName: "Trần Quốc Dũng",
    bio: "Âm nhạc độc lập",
  };
  assert.equal(
    (await request("/users/me", "PATCH", profile, "user_b")).status,
    200,
  );
  assert.equal(
    (await request("/users/me", "PATCH", { ...profile, username: "TQD.MUSIC" }))
      .status,
    409,
  );
  assert.equal(
    (
      await request("/users/me", "PATCH", {
        ...profile,
        username: "listener_a",
        displayName: "Người nghe",
      })
    ).status,
    200,
  );
  const b = await data("/users/tqd.music");
  assert.equal(b.displayName, profile.displayName);
  assert.ok(!JSON.stringify(b).includes("clerk_user_id"));
  assert.ok(!("email" in b));
  assert.equal((await data("/users/search?q=@TQD")).items[0].id, b.id);
  assert.equal((await data("/users/search?q=Tr%E1%BA%A7n")).items[0].id, b.id);
  assert.deepEqual(
    (await data("/users/search?q=%25%27%20OR%201%3D1--")).items,
    [],
  );
  assert.equal((await request("/users/search?limit=51")).status, 400);
  assert.equal((await request(`/users/${a.id}/follow`, "POST")).status, 400);
  const followed = await Promise.all([
    request(`/users/${b.id}/follow`, "POST"),
    request(`/users/${b.id}/follow`, "POST"),
  ]);
  assert.ok(followed.every((r) => r.status === 204));
  assert.equal((await data("/users/tqd.music")).followerCount, 1);
  assert.equal((await data(`/users/${b.id}/followers`)).items[0].id, a.id);
  assert.equal((await data(`/users/${a.id}/following`)).items[0].id, b.id);
  assert.equal((await data("/users/tqd.music")).following, true);

  const makeTrack = async (visibility, title) => {
    const asset = (
      await db.query(
        `INSERT INTO media_assets(clerk_user_id,media_type,public_id,secure_url,resource_type,format,bytes)
      VALUES ('user_b','audio',$1,'https://fixture.invalid/audio','video','mp3',100) RETURNING id`,
        [randomUUID()],
      )
    ).rows[0];
    return (
      await db.query(
        `INSERT INTO private_tracks(clerk_user_id,audio_asset_id,title,artist,genre,visibility,rights_confirmed_at)
      VALUES ('user_b',$1,$2,'Creator','Indie',$3,CASE WHEN $3::varchar='public' THEN NOW() ELSE NULL END) RETURNING id`,
        [asset.id, title, visibility],
      )
    ).rows[0].id;
  };
  const pub = await makeTrack("public", "Bản thu mới");
  const priv = await makeTrack("private", "Private sentinel");
  assert.equal((await data("/discover/new-releases")).items[0].id, pub);
  assert.equal((await data("/discover/following")).items[0].id, pub);
  assert.equal((await data("/genres"))[0].name, "Indie");
  assert.equal((await data("/discover/featured-creators")).items[0].id, b.id);
  assert.equal(
    (await data("/community/search?q=%40tqd")).songs.items.length,
    0,
  );
  assert.ok(
    !JSON.stringify(await data("/discover/home")).includes("Private sentinel"),
  );
  for (const path of [
    `/community/songs/${priv}/playback`,
    `/community/songs/${priv}/like`,
  ])
    assert.equal(
      (await request(path, path.endsWith("like") ? "PUT" : "GET")).status,
      404,
    );
  assert.equal(
    (await request(`/community/songs/${pub}`, "PATCH", { title: "hacked" }))
      .status,
    404,
  );
  assert.equal(
    (await request(`/community/songs/${pub}`, "DELETE")).status,
    404,
  );
  assert.equal(
    (await request(`/community/songs/${pub}/like`, "PUT")).status,
    204,
  );
  assert.equal(
    (await request(`/community/songs/${pub}/save`, "PUT")).status,
    204,
  );
  assert.equal((await data("/community/saved")).items[0].id, pub);
  const playing = await data(`/community/songs/${pub}/playback`);
  assert.equal(playing.thresholdMs, 30000);
  const heartbeat = `/playback-sessions/${playing.playSessionId}/heartbeat`;
  assert.equal(
    (
      await request(
        heartbeat,
        "POST",
        { positionMs: 30000, playing: true },
        "user_b",
      )
    ).status,
    404,
  );
  await request(heartbeat, "POST", { positionMs: 30000, playing: true });
  assert.equal(
    (await data("/discover/trending")).items[0].validPlayCount,
    0,
    "seeking/refresh cannot instantly generate a valid play",
  );
  // Move only fixture server timestamps; no wait and no real data/network.
  for (const position of [45000, 60000]) {
    await db.query(
      "UPDATE playback_sessions SET last_heartbeat_at=NOW()-INTERVAL '16 seconds' WHERE id=$1",
      [playing.playSessionId],
    );
    await request(heartbeat, "POST", { positionMs: position, playing: true });
  }
  const ranked = await data("/discover/trending?period=week");
  assert.equal(ranked.items[0].validPlayCount, 1);
  assert.equal(ranked.items[0].uniqueListeners, 1);
  assert.equal(ranked.items[0].likeCount, 1);
  assert.ok(ranked.items[0].score > 0);
  await request(heartbeat, "POST", { positionMs: 61000, playing: true });
  assert.equal((await data("/discover/trending")).items[0].validPlayCount, 1);
  const repeated = await data(`/community/songs/${pub}/playback`);
  for (const position of [16000, 32000]) {
    await db.query(
      "UPDATE playback_sessions SET last_heartbeat_at=NOW()-INTERVAL '16 seconds' WHERE id=$1",
      [repeated.playSessionId],
    );
    await request(
      `/playback-sessions/${repeated.playSessionId}/heartbeat`,
      "POST",
      { positionMs: position, playing: true },
    );
  }
  assert.equal(
    (await data("/discover/trending")).items[0].validPlayCount,
    1,
    "a replacement session cannot bypass the rolling listener/song deduplication",
  );
  await db.query(
    "UPDATE valid_play_events SET created_at=NOW()-INTERVAL '8 days'",
  );
  assert.equal(
    (await data("/discover/trending?period=week")).items[0].validPlayCount,
    0,
  );
  assert.equal(
    (await data("/discover/trending?period=all")).items[0].validPlayCount,
    1,
  );
  const playlistResult = await request("/community/playlists", "POST", {
    title: "Tuyển chọn",
    visibility: "public",
  });
  const playlistId = (await playlistResult.json()).data.id;
  assert.equal(
    (
      await request(`/community/playlists/${playlistId}/tracks`, "POST", {
        trackId: pub,
      })
    ).status,
    204,
  );
  assert.equal(
    (
      await request(`/community/playlists/${playlistId}/tracks`, "POST", {
        trackId: priv,
      })
    ).status,
    404,
  );
  assert.equal(
    (await data(`/community/playlists/${playlistId}`)).tracks.items[0].id,
    pub,
  );
  assert.equal(
    (
      await request(
        `/community/playlists/${playlistId}`,
        "DELETE",
        undefined,
        "user_b",
      )
    ).status,
    404,
  );
  assert.equal(
    (
      await request("/community/reports", "POST", {
        trackId: pub,
        reason: "copyright",
      })
    ).status,
    202,
  );
  assert.equal(
    (
      await request("/community/reports", "POST", {
        trackId: priv,
        reason: "copyright",
      })
    ).status,
    404,
  );
  const moderation = createModerationService(pool);
  const reportId = (
    await db.query("SELECT id FROM content_reports WHERE track_id=$1", [pub])
  ).rows[0].id;
  await moderation.review(reportId, "hide");
  assert.equal((await data("/discover/trending")).items.length, 0);
  assert.equal((await request(`/community/songs/${pub}/playback`)).status, 404);
  await moderation.review(reportId, "restore");
  assert.equal((await data("/discover/trending")).items.length, 1);
  await request("/community/reports", "POST", {
    profileId: b.id,
    reason: "spam",
  });
  const profileReport = (
    await db.query("SELECT id FROM content_reports WHERE profile_id=$1", [b.id])
  ).rows[0].id;
  await moderation.review(profileReport, "hide");
  assert.equal((await request("/users/tqd.music")).status, 404);
  assert.equal((await data("/discover/new-releases")).items.length, 0);
  assert.equal(
    (await data("/community/playlists")).items[0].songCount,
    0,
    "playlist counts must exclude a hidden creator just like its track list",
  );
  await moderation.review(profileReport, "restore");
  assert.equal((await request("/users/tqd.music")).status, 200);
  await request(
    `/community/songs/${pub}`,
    "PATCH",
    { visibility: "private" },
    "user_b",
  );
  assert.equal((await data("/discover/trending")).items.length, 0);
  assert.equal(
    (await data(`/community/playlists/${playlistId}`)).tracks.items.length,
    0,
  );
  assert.equal((await request(`/community/songs/${pub}/playback`)).status, 404);
  assert.equal(
    (
      await request(
        `/community/songs/${pub}`,
        "PATCH",
        { visibility: "public" },
        "user_b",
      )
    ).status,
    400,
  );
  assert.equal(
    (
      await request(
        `/community/songs/${pub}`,
        "PATCH",
        { visibility: "public", rightsConfirmed: true },
        "user_b",
      )
    ).status,
    200,
  );
  assert.equal(
    (await request(`/community/songs/${pub}`, "DELETE", undefined, "user_b"))
      .status,
    202,
  );
  assert.equal((await data("/discover/new-releases")).items.length, 0);
  assert.equal((await request(`/users/${b.id}/follow`, "DELETE")).status, 204);
  assert.equal((await data("/users/tqd.music")).followerCount, 0);
  for (const [username, name] of [
    ["tqd", "Exact"],
    ["another.tqd", "Contains"],
    ["display_match", "tqd display"],
  ])
    await db.query(
      "INSERT INTO users(clerk_user_id,username,display_name) VALUES ($1,$2,$3)",
      [randomUUID(), username, name],
    );
  assert.deepEqual(
    (await data("/users/search?q=@TQD")).items.map((user) => user.username),
    ["tqd", "tqd.music", "another.tqd", "display_match"],
  );
  const paged = await data("/users/search?q=@TQD&limit=2");
  assert.equal(paged.items.length, 2);
  assert.equal(paged.nextOffset, 2);
  assert.equal(
    (await data("/users/search?q=@TQD&limit=2&offset=2")).items[0].username,
    "another.tqd",
  );
});
