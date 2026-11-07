import { z } from 'zod';
import { HttpError } from '../utils/http-error.js';

export const MAX_LRC_BYTES = 65536;
export const lyricsIdSchema = z.uuid();
export const lyricsWriteSchema = z.object({
  lrc: z.string().min(1).max(MAX_LRC_BYTES),
  revision: z.number().int().min(0).max(2147483646),
}).strict();
export const lyricsDeleteSchema = lyricsWriteSchema.omit({ lrc: true });

export function parseLrc(input) {
  const invalid = () => { throw new HttpError(400, 'INVALID_LRC', 'Use valid timestamped UTF-8 LRC lyrics within the supported limits.'); };
  if (typeof input !== 'string' || !input.length || Buffer.byteLength(input, 'utf8') > MAX_LRC_BYTES || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f\ud800-\udfff]/u.test(input)) invalid();
  const source = input.replace(/^\uFEFF/, '').replace(/\r\n?/g, '\n').trim();
  const rows = source.split('\n');
  if (rows.length > 2000) invalid();
  const cues = [];
  let offset = 0, seenOffset = false;
  for (const row of rows) {
    let rest = row.trim();
    if (!rest) continue;
    const header = /^\[([a-z][a-z0-9_-]{0,20}):(.*)\]$/i.exec(rest);
    if (header) {
      if (rest.length > 600) invalid();
      if (header[1].toLowerCase() === 'offset') {
        if (seenOffset || !/^[+-]?\d{1,5}$/.test(header[2]) || Math.abs(Number(header[2])) > 30000) invalid();
        offset = Number(header[2]); seenOffset = true;
      }
      continue;
    }
    const times = [];
    let stamp;
    while ((stamp = /^\[(\d{1,3}):([0-5]\d)(?:\.(\d{1,3}))?\]/.exec(rest))) {
      const at = Number(stamp[1]) * 60000 + Number(stamp[2]) * 1000 + Number((stamp[3] || '').padEnd(3, '0'));
      if (at > 21600000 || times.length >= 1000) invalid();
      times.push(at); rest = rest.slice(stamp[0].length).trimStart();
    }
    const text = rest.trim();
    if (!times.length || text.length > 500 || /^\[\d/.test(text) || /<\d{1,3}:\d{2}(?:\.\d{1,3})?>/.test(text) || cues.length + times.length > 1000) invalid();
    for (const at of times) cues.push({ atMs: at, text });
  }
  if (!cues.some(cue => cue.text.length)) invalid();
  for (const cue of cues) cue.atMs = Math.max(0, cue.atMs - offset);
  cues.sort((a, b) => a.atMs - b.atMs);
  const merged = [];
  for (const cue of cues) {
    const last = merged.at(-1);
    if (last?.atMs === cue.atMs) {
      if (cue.text && !last.text.split('\n').includes(cue.text)) last.text = [last.text, cue.text].filter(Boolean).join('\n');
      if (last.text.length > 2000) invalid();
    } else merged.push({ ...cue });
  }
  return { source, cues: merged };
}
