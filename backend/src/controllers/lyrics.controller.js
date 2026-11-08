import { parse } from '../validation/track.schema.js';
import { lyricsIdSchema, lyricsWriteSchema, lyricsDeleteSchema } from '../validation/lyrics.schema.js';
import { HttpError } from '../utils/http-error.js';

export const createLyricsController = service => {
  const validate = req => {
    const id = parse(lyricsIdSchema, req.params.songId);
    if (Object.keys(req.query).length) throw new HttpError(400, 'VALIDATION_ERROR', 'Query parameters are not accepted.');
    return id;
  };
  return {
    read: async (req, res) => {
      const id = validate(req);
      if (req.body !== undefined || Number(req.get('content-length') || 0) > 0 || req.get('transfer-encoding')) throw new HttpError(400, 'VALIDATION_ERROR', 'A request body is not accepted.');
      res.json({ success: true, data: await service.read(req.clerkUserId, id) });
    },
    save: async (req, res) => res.json({ success: true, data: await service.save(req.clerkUserId, validate(req), parse(lyricsWriteSchema, req.body)) }),
    remove: async (req, res) => res.json({ success: true, data: await service.remove(req.clerkUserId, validate(req), parse(lyricsDeleteSchema, req.body)) }),
  };
};
