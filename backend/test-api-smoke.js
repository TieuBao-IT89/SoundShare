import "dotenv/config";
import { once } from "node:events";
import { createApp } from "./src/app.js";
import { pool, checkDatabaseConnection } from "./src/config/database.js";
import cloudinary from "./src/config/cloudinary.js";
import { createMediaRepository } from "./src/repositories/media.repository.js";
import { createCloudinaryStorage } from "./src/services/cloudinary-storage.service.js";
import { createUploadService } from "./src/services/upload.service.js";
import { createTrackRepository } from "./src/repositories/track.repository.js";
import { createTrackService } from "./src/services/track.service.js";
import { createCommunityRepository } from "./src/repositories/community.repository.js";
import { createCommunityService } from "./src/services/community.service.js";

if (!["development", "test"].includes(process.env.NODE_ENV)) {
  throw new Error(
    "Run the smoke check only with development or test configuration.",
  );
}

const storage = createCloudinaryStorage(cloudinary);
const uploadService = createUploadService({
  repository: createMediaRepository(pool),
  storage,
});
const communityRepository = createCommunityRepository(pool);
const app = createApp({
  logging: false,
  checkDatabaseConnection,
  uploadService,
  trackService: createTrackService({
    repository: createTrackRepository(pool),
    storage,
    uploadService,
  }),
  communityService: createCommunityService({
    repository: communityRepository,
    storage,
  }),
});
const server = app.listen(0, "127.0.0.1");
let passed = 0;
let failed = 0;
const report = (name, success) => {
  success ? passed++ : failed++;
  console.log(`${success ? "PASS" : "FAIL"}: ${name}`);
};

try {
  await once(server, "listening");
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;
  const id = "00000000-0000-4000-8000-000000000000";
  // Every private request is intentionally unauthenticated: no upload or delete
  // reaches Storage, and no application records are created or changed.
  for (const [method, route, expected] of [
    ["GET", "/health", 200],
    ["GET", "/auth/me", 401],
    ["GET", "/songs", 401],
    ["POST", "/songs", 401],
    ["GET", `/songs/${id}/playback`, 401],
    ["PUT", `/songs/${id}/favorite`, 401],
    ["DELETE", `/songs/${id}/favorite`, 401],
    ["POST", "/uploads/artwork", 401],
    ["POST", "/uploads/audio", 401],
    ["GET", `/uploads/${id}/access`, 401],
    ["DELETE", `/uploads/${id}`, 401],
    ["GET", "/users/me", 401],
    ["PATCH", "/users/me", 401],
    ["GET", "/community/search?q=@listener", 401],
    ["GET", "/discover/trending?period=week", 401],
    ["GET", "/discover/featured-creators", 401],
    ["GET", "/genres", 401],
    ["POST", `/users/${id}/follow`, 401],
    ["GET", `/community/songs/${id}/playback`, 401],
    ["POST", `/playback-sessions/${id}/heartbeat`, 401],
    ["DELETE", `/community/songs/${id}`, 401],
    ["POST", "/community/playlists", 401],
    ["POST", "/community/reports", 401],
  ]) {
    const response = await fetch(`${base}${route}`, {
      method,
      signal: AbortSignal.timeout(15000),
    });
    const body = await response.json();
    report(
      `${method} ${route} -> ${expected}`,
      response.status === expected &&
        (expected === 200 ||
          (body.error?.code === "UNAUTHORIZED" &&
            body.error.requestId === response.headers.get("x-request-id"))),
    );
  }

  const checks = [
    [
      "Cloudinary authenticated ping",
      async () =>
        (await cloudinary.api.ping({ timeout: 10000 })).status === "ok",
    ],
    [
      "Clerk authenticated JWKS",
      async () => {
        const response = await fetch("https://api.clerk.com/v1/jwks", {
          headers: { Authorization: `Bearer ${process.env.CLERK_SECRET_KEY}` },
          signal: AbortSignal.timeout(10000),
        });
        const body = await response.json();
        return response.ok && Array.isArray(body.keys) && body.keys.length > 0;
      },
    ],
    [
      "Neon media_assets and migration 002",
      async () => {
        const table = await pool.query(
          "SELECT to_regclass($1) IS NOT NULL AS exists",
          ["public.media_assets"],
        );
        const migration = await pool.query(
          "SELECT filename FROM schema_migrations WHERE filename = $1",
          ["002_create_media_assets.sql"],
        );
        return table.rows[0].exists && migration.rowCount === 1;
      },
    ],
    [
      "Neon private tracks/favorites and migration 003",
      async () => {
        const tables = await pool.query(
          "SELECT to_regclass($1) IS NOT NULL AND to_regclass($2) IS NOT NULL AS ready",
          ["public.private_tracks", "public.private_track_favorites"],
        );
        const migration = await pool.query(
          "SELECT filename FROM schema_migrations WHERE filename = $1",
          ["003_private_tracks.sql"],
        );
        return tables.rows[0].ready && migration.rowCount === 1;
      },
    ],
    [
      "Neon social schema and migration 004",
      async () => {
        const tables = await pool.query(
          "SELECT count(*)::int AS ready FROM unnest($1::text[]) AS name WHERE to_regclass(name) IS NOT NULL",
          [
            [
              "public.user_follows",
              "public.track_likes",
              "public.saved_tracks",
              "public.playback_sessions",
              "public.valid_play_events",
              "public.playlist_tracks",
              "public.content_reports",
              "public.track_deletions",
              "public.media_cleanup_jobs",
            ],
          ],
        );
        const migration = await pool.query(
          "SELECT filename FROM schema_migrations WHERE filename=$1",
          ["004_social_music.sql"],
        );
        return tables.rows[0].ready === 9 && migration.rowCount === 1;
      },
    ],
    [
      "Neon discovery read queries",
      async () => {
        const filters = {
          limit: 2,
          offset: 0,
          period: "week",
          mode: "featured",
          q: "",
        };
        const results = await Promise.all([
          communityRepository.trending("readonly-smoke-no-user", filters),
          communityRepository.creators("readonly-smoke-no-user", filters),
          communityRepository.searchUsers("readonly-smoke-no-user", filters),
          communityRepository.genres("readonly-smoke-no-user"),
        ]);
        return results.every(Array.isArray);
      },
    ],
    [
      "Existing audio has readable verified duration",
      async () => {
        const assets = await pool.query(
          "SELECT a.public_id,a.resource_type FROM private_tracks t JOIN media_assets a ON a.id=t.audio_asset_id ORDER BY t.created_at DESC LIMIT 2",
        );
        const metadata = await Promise.all(
          assets.rows.map((asset) =>
            storage.find(asset.public_id, asset.resource_type),
          ),
        );
        return metadata.every(
          (asset) =>
            Number.isFinite(asset?.duration) &&
            asset.duration > 0 &&
            asset.duration < 86400,
        );
      },
    ],
  ];
  const results = await Promise.allSettled(checks.map(([, check]) => check()));
  results.forEach((result, index) =>
    report(
      checks[index][0],
      result.status === "fulfilled" && result.value === true,
    ),
  );
} catch {
  // Do not print external errors, response bodies, URLs or configuration values.
  report("Smoke check could not complete; connection details omitted", false);
} finally {
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));
  await pool.end();
}

console.log(
  `Smoke checks: ${passed} passed, ${failed} failed. No application data was written.`,
);
process.exitCode = failed ? 1 : 0;
