import { Router } from "express";
import { z } from "zod";
import { parse } from "../validation/track.schema.js";
import {
  pageSchema,
  searchSchema,
  discoverSchema,
  profileSchema,
  usernameSchema,
  songPatchSchema,
  heartbeatSchema,
  playlistSchema,
  playlistTrackSchema,
  reportSchema,
} from "../validation/community.schema.js";
import { createRateLimit } from "../middleware/upload-limits.middleware.js";
import { communityController as controller } from "../controllers/community.controller.js";

export const createCommunityRouter = ({ service: s, requireAuth }) => {
  const router = Router();
  router.use(requireAuth);
  router.use((req, res, next) => {
    res.set("Cache-Control", "no-store");
    next();
  });
  const none = z.object({}).strict();
  const validate =
    (query = none, body = z.undefined(), params = none) =>
    (req, res, next) => {
      req.validated = {
        ...parse(query, req.query),
        ...parse(body, req.body),
        ...parse(params, req.params),
      };
      next();
    };
  const id = z.object({ id: z.uuid() }).strict();
  const username = z.object({ username: usernameSchema }).strict();
  const limited = createRateLimit({ limit: 60, windowMs: 60000 });
  router.get(
    "/users/me",
    validate(),
    controller((owner) => s.me(owner)),
  );
  router.patch(
    "/users/me",
    createRateLimit({ limit: 20 }),
    validate(none, profileSchema),
    controller((owner, input) => s.updateProfile(owner, input)),
  );
  router.get(
    "/users/search",
    limited,
    validate(searchSchema),
    controller((owner, input) => s.users(owner, input)),
  );
  router.get(
    "/users/:username",
    validate(none, z.undefined(), username),
    controller((owner, input) => s.profile(owner, input.username)),
  );
  router.get(
    "/users/:username/songs",
    validate(pageSchema, z.undefined(), username),
    controller((owner, input) => s.tracks(owner, input)),
  );
  router.get(
    "/users/:username/playlists",
    validate(pageSchema, z.undefined(), username),
    controller((owner, input) => s.playlists(owner, input)),
  );
  for (const [method, enabled] of [
    ["post", true],
    ["delete", false],
  ])
    router[method](
      "/users/:id/follow",
      createRateLimit({ limit: 60 }),
      validate(none, z.undefined(), id),
      controller((owner, input) => s.follow(owner, input.id, enabled), {
        status: 204,
        empty: true,
      }),
    );
  for (const kind of ["followers", "following"])
    router.get(
      `/users/:id/${kind}`,
      validate(pageSchema, z.undefined(), id),
      controller((owner, input) => s.connections(owner, input.id, kind, input)),
    );
  router.get(
    "/discover/home",
    validate(),
    controller((owner) => s.home(owner)),
  );
  router.get(
    "/discover/trending",
    limited,
    validate(discoverSchema),
    controller((owner, input) => s.trending(owner, input)),
  );
  router.get(
    "/discover/featured-creators",
    limited,
    validate(discoverSchema),
    controller((owner, input) => s.creators(owner, input)),
  );
  router.get(
    "/discover/new-releases",
    limited,
    validate(searchSchema),
    controller((owner, input) => s.tracks(owner, input)),
  );
  router.get(
    "/discover/following",
    validate(pageSchema),
    controller((owner, input) => s.tracks(owner, { ...input, feed: true })),
  );
  router.get(
    "/discover/recent",
    validate(pageSchema),
    controller((owner, input) => s.tracks(owner, { ...input, recent: true })),
  );
  router.get(
    "/community/search",
    limited,
    validate(searchSchema),
    controller((owner, input) => s.search(owner, input)),
  );
  router.get(
    "/genres",
    validate(),
    controller((owner) => s.genres(owner)),
  );
  router.get(
    "/community/saved",
    validate(pageSchema),
    controller((owner, input) => s.tracks(owner, { ...input, saved: true })),
  );
  router.get(
    "/community/liked",
    validate(pageSchema),
    controller((owner, input) => s.tracks(owner, { ...input, liked: true })),
  );
  router.get(
    "/community/songs/:id/playback",
    createRateLimit({ limit: 30 }),
    validate(none, z.undefined(), id),
    controller((owner, input) => s.playback(owner, input.id)),
  );
  router.patch(
    "/community/songs/:id",
    validate(none, songPatchSchema, id),
    controller((owner, input) => {
      const { id, ...patch } = input;
      return s.patchTrack(owner, id, patch);
    }),
  );
  router.delete(
    "/community/songs/:id",
    validate(none, z.undefined(), id),
    controller((owner, input) => s.deleteTrack(owner, input.id), {
      status: 202,
    }),
  );
  for (const kind of ["like", "save"])
    for (const [method, enabled] of [
      ["put", true],
      ["delete", false],
    ])
      router[method](
        `/community/songs/:id/${kind}`,
        validate(none, z.undefined(), id),
        controller(
          (owner, input) => s.interact(owner, input.id, kind, enabled),
          { status: 204, empty: true },
        ),
      );
  router.post(
    "/playback-sessions/:id/heartbeat",
    createRateLimit({ limit: 150 }),
    validate(none, heartbeatSchema, id),
    controller((owner, input) => s.heartbeat(owner, input.id, input)),
  );
  router.get(
    "/community/playlists",
    validate(pageSchema),
    controller((owner, input) => s.playlists(owner, input)),
  );
  router.post(
    "/community/playlists",
    createRateLimit({ limit: 20 }),
    validate(none, playlistSchema),
    controller((owner, input) => s.createPlaylist(owner, input), {
      status: 201,
    }),
  );
  router.get(
    "/community/playlists/:id",
    validate(pageSchema, z.undefined(), id),
    controller((owner, input) => s.playlist(owner, input.id, input)),
  );
  router.delete(
    "/community/playlists/:id",
    validate(none, z.undefined(), id),
    controller((owner, input) => s.changePlaylist(owner, input.id), {
      status: 204,
      empty: true,
    }),
  );
  router.post(
    "/community/playlists/:id/tracks",
    validate(none, playlistTrackSchema, id),
    controller(
      (owner, input) => s.changePlaylist(owner, input.id, input, false),
      { status: 204, empty: true },
    ),
  );
  router.delete(
    "/community/playlists/:id/tracks/:trackId",
    validate(none, z.undefined(), id.extend({ trackId: z.uuid() })),
    controller(
      (owner, input) => s.changePlaylist(owner, input.id, input, true),
      { status: 204, empty: true },
    ),
  );
  router.post(
    "/community/reports",
    createRateLimit({ limit: 10 }),
    validate(none, reportSchema),
    controller((owner, input) => s.report(owner, input), { status: 202 }),
  );
  return router;
};
