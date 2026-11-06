import { HttpError } from "../utils/http-error.js";

export const createCommunityService = ({
  repository: r,
  storage,
  cleanupService,
}) => {
  const missing = () =>
    new HttpError(404, "RESOURCE_NOT_FOUND", "Content is unavailable.");
  const access = (row, prefix) =>
    row[`${prefix}_public_id`]
      ? storage.createAccess({
          public_id: row[`${prefix}_public_id`],
          format: row[`${prefix}_format`],
          resource_type: row[`${prefix}_resource_type`],
        })
      : null;
  const profile = (row) => ({
    id: row.id,
    username: row.username,
    displayName: row.display_name || row.username || "",
    bio: row.bio || "",
    avatar: access(row, "avatar"),
    cover: access(row, "cover"),
    followerCount: Number(row.follower_count || 0),
    followingCount: Number(row.following_count || 0),
    songCount: Number(row.song_count || 0),
    following: !!row.following,
    isSelf: !!row.is_self,
    createdAt: row.created_at,
  });
  const song = (row) => ({
    id: row.id,
    title: row.title,
    artist: row.artist,
    genre: row.genre,
    description: row.description,
    createdAt: row.created_at,
    visibility: row.visibility,
    artwork: access(row, "artwork"),
    liked: !!row.liked,
    saved: !!row.saved,
    community: true,
    durationSeconds: row.duration_seconds,
    resumePositionMs: row.resume_position_ms || 0,
    uploader: {
      id: row.uploader_id,
      username: row.username,
      displayName: row.display_name || row.username || "",
    },
    validPlayCount: Number(row.valid_plays || 0),
    uniqueListeners: Number(row.unique_listeners || 0),
    totalPlayCount: Number(row.total_plays || 0),
    likeCount: Number(row.like_count || 0),
    saveCount: Number(row.save_count || 0),
    score: Number(row.score || 0),
  });
  const playlist = (row) => ({
    id: row.id,
    title: row.title,
    description: row.description,
    visibility: row.is_public ? "public" : "private",
    username: row.username,
    isSelf: !!row.is_self,
    songCount: Number(row.song_count || 0),
  });
  const page = (rows, filters, map) => ({
    items: rows.slice(0, filters.limit).map(map),
    nextOffset:
      rows.length > filters.limit ? filters.offset + filters.limit : null,
  });
  const safe =
    (action) =>
    async (...args) => {
      try {
        return await action(...args);
      } catch (error) {
        if (error instanceof HttpError) throw error;
        if (
          error.code === "23505" &&
          ["users_username_key", "users_username_lower_unique"].includes(
            error.constraint,
          )
        )
          throw new HttpError(
            409,
            "USERNAME_TAKEN",
            "That username is already in use.",
          );
        if (error.code === "55P03" || error.code === "40P01")
          throw new HttpError(
            409,
            "RESOURCE_BUSY",
            "Content is being updated. Retry shortly.",
          );
        throw new HttpError(
          503,
          "COMMUNITY_UNAVAILABLE",
          "Community is temporarily unavailable.",
        );
      }
    };
  return Object.fromEntries(
    Object.entries({
      me: async (owner) => profile(await r.me(owner)),
      profile: async (owner, username) => {
        const row = await r.profile(owner, username);
        if (!row) throw missing();
        return profile(row);
      },
      updateProfile: async (owner, input) => {
        await r.user(owner);
        await r.updateProfile(owner, input);
        return profile(await r.me(owner));
      },
      users: async (owner, filters) =>
        page(await r.searchUsers(owner, filters), filters, profile),
      follow: async (owner, id, enabled) => {
        await r.user(owner);
        await r.follow(owner, id, enabled);
      },
      connections: async (owner, id, kind, filters) =>
        page(await r.connections(owner, id, kind, filters), filters, profile),
      creators: async (owner, filters) =>
        page(await r.creators(owner, filters), filters, profile),
      tracks: async (owner, filters) =>
        page(await r.tracks(owner, filters), filters, song),
      trending: async (owner, filters) => ({
        ...page(await r.trending(owner, filters), filters, song),
        period: filters.period,
        experimental: true,
        formula:
          "0.45 valid plays + 0.25 unique listeners + 0.20 likes + 0.10 saves (max-normalized within period)",
      }),
      genres: async (owner) =>
        (await r.genres(owner)).map((row) => ({
          name: row.genre,
          songCount: Number(row.song_count),
        })),
      home: async (owner) => {
        const filters = { limit: 8, offset: 0 };
        const [fresh, following, recommended, recent, popular] =
          await Promise.all([
            r.tracks(owner, filters),
            r.tracks(owner, { ...filters, feed: true }),
            r.tracks(owner, { ...filters, recommended: true }),
            r.tracks(owner, { ...filters, recent: true }),
            r.trending(owner, { ...filters, period: "week" }),
          ]);
        return {
          newReleases: fresh.slice(0, 8).map(song),
          following: following.slice(0, 8).map(song),
          recommended: recommended.slice(0, 8).map(song),
          recent: recent.slice(0, 8).map(song),
          popular: popular.slice(0, 8).map(song),
          recommendationReason: "liked-genres-then-newest",
        };
      },
      search: async (owner, filters) => {
        const forUsers = filters.type === "all" || filters.type === "users";
        const forSongs =
          !filters.q.startsWith("@") &&
          (filters.type === "all" || filters.type === "songs");
        const forPlaylists =
          !filters.q.startsWith("@") &&
          (filters.type === "all" || filters.type === "playlists");
        const [users, songs, playlists] = await Promise.all([
          forUsers ? r.searchUsers(owner, filters) : [],
          forSongs ? r.tracks(owner, { ...filters, q: filters.q }) : [],
          forPlaylists ? r.searchPlaylists(owner, filters) : [],
        ]);
        return {
          users: page(users, filters, profile),
          songs: page(songs, filters, song),
          playlists: page(playlists, filters, playlist),
        };
      },
      patchTrack: (owner, id, input) => r.patchTrack(owner, id, input),
      deleteTrack: async (owner, id) => {
        if (!(await r.deleteTrack(owner, id))) throw missing();
        return {
          id,
          status: "removed",
          cleanupPending: cleanupService
            ? (await cleanupService.process({ owner, trackId: id })) > 0
            : true,
        };
      },
      interact: async (owner, id, kind, enabled) => {
        await r.user(owner);
        await r.interact(owner, id, kind, enabled);
      },
      playback: async (owner, id) => {
        await r.user(owner);
        const row = await r.track(owner, id);
        if (!row) throw missing();
        let duration = row.duration_seconds;
        if (!duration) {
          let stored;
          try {
            stored = await storage.find(
              row.audio_public_id,
              row.audio_resource_type,
            );
          } catch {
            throw new HttpError(
              502,
              "STORAGE_UNAVAILABLE",
              "Audio is temporarily unavailable.",
            );
          }
          duration = stored?.duration;
          if (!Number.isFinite(duration) || duration <= 0 || duration >= 86400)
            throw new HttpError(
              502,
              "AUDIO_DURATION_UNAVAILABLE",
              "Audio metadata is temporarily unavailable.",
            );
          await r.duration(id, duration);
        }
        const session = await r.startPlayback(owner, id, duration);
        return {
          ...access(row, "audio"),
          playSessionId: session.id,
          thresholdMs: session.threshold_ms,
          durationSeconds: duration,
        };
      },
      heartbeat: (owner, id, input) => r.heartbeat(owner, id, input),
      playlists: async (owner, filters) =>
        page(await r.playlists(owner, filters), filters, playlist),
      createPlaylist: (owner, input) => r.createPlaylist(owner, input),
      playlist: async (owner, id, filters) => {
        const row = await r.playlist(owner, id);
        if (!row) throw missing();
        return {
          ...playlist(row),
          tracks: page(
            await r.playlistTracks(owner, id, filters),
            filters,
            song,
          ),
        };
      },
      changePlaylist: (owner, id, input, remove) =>
        r.changePlaylist(owner, id, input, remove),
      report: async (owner, input) => {
        await r.user(owner);
        await r.report(owner, input);
        return { status: "pending" };
      },
    }).map(([name, action]) => [name, safe(action)]),
  );
};
