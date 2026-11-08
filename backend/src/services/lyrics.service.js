import { HttpError } from '../utils/http-error.js';
import { parseLrc } from '../validation/lyrics.schema.js';

export const createLyricsService = repository => {
  const result = (row, owner) => ({
    format: 'lrc', revision: row.revision, updatedAt: row.updated_at ?? null,
    canEdit: row.clerk_user_id === owner, lrc: row.lrc ?? null,
    cues: row.lrc ? parseLrc(row.lrc).cues : [],
  });
  const safely = async action => {
    try { return await action(); } catch (error) {
      if (error instanceof HttpError) throw error;
      throw new HttpError(503, 'LYRICS_UNAVAILABLE', 'Lyrics are temporarily unavailable.');
    }
  };
  return {
    read: (owner, id) => safely(async () => result(await repository.read(owner, id), owner)),
    save: (owner, id, input) => safely(async () => result(await repository.write(owner, id, parseLrc(input.lrc).source, input.revision), owner)),
    remove: (owner, id, input) => safely(async () => result(await repository.write(owner, id, null, input.revision), owner)),
  };
};
