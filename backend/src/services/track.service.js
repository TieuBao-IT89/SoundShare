import { HttpError } from "../utils/http-error.js";
import { encodeCursor } from "../validation/track.schema.js";

export const createTrackService = ({ repository, storage, uploadService }) => {
  const safely = async (action) => {
    try { return await action(); }
    catch (error) {
      if (error instanceof HttpError) throw error;
      if (error.code === "55P03") throw new HttpError(409, "MEDIA_BUSY", "An uploaded file is busy. Retry shortly.");
      throw new HttpError(503, "DATABASE_UNAVAILABLE", "Your music library is temporarily unavailable.");
    }
  };
  return {
    currentUser: (owner) => safely(async () => {
      const row = await repository.ensureUser(owner);
      return { id: row.id, clerkUserId: owner };
    }),
    list: (owner, filters) => safely(async () => {
      const rows = await repository.list(owner, filters);
      const hasMore = rows.length > filters.limit;
      const page = rows.slice(0, filters.limit);
      return { items: page.map((row) => ({
        id: row.id, title: row.title, artist: row.artist, genre: row.genre, description: row.description,
        createdAt: row.created_at, liked: row.liked, artwork: row.artwork_public_id ? storage.createAccess({
          public_id: row.artwork_public_id, format: row.artwork_format, resource_type: row.artwork_resource_type,
        }) : null,
      })), nextCursor: hasMore ? encodeCursor(page.at(-1)) : null };
    }),
    create: (owner, input) => safely(async () => {
      await repository.ensureUser(owner);
      const result = await repository.create(owner, input);
      return { created: result.created, id: result.row.id };
    }),
    playback: (owner, id) => safely(async () => {
      const row = await repository.find(id, owner);
      if (!row) throw new HttpError(404, "SONG_NOT_FOUND", "Track not found.");
      const result = await uploadService.getAccess({ id: row.audio_asset_id, userId: owner });
      return result.access;
    }),
    favorite: (owner, id, liked) => safely(() => repository.setFavorite(id, owner, liked)),
  };
};
