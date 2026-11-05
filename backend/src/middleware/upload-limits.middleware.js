import { HttpError } from "../utils/http-error.js";

// Single-process MVP limiter. A multi-instance deployment needs a shared limiter.
export const createRateLimit = ({ limit = 10, windowMs = 15 * 60 * 1000, key = (req) => req.clerkUserId } = {}) => {
  const entries = new Map();
  return (req, res, next) => {
    const now = Date.now();
    for (const [id, entry] of entries) {
      if (entry.expires <= now) entries.delete(id);
    }
    const id = key(req);
    let entry = entries.get(id);
    if (!entry) {
      if (entries.size >= 10000) {
        return next(new HttpError(429, "RATE_LIMITED", "Too many requests. Try again later."));
      }
      entry = { count: 0, expires: now + windowMs };
      entries.set(id, entry);
    }
    if (++entry.count > limit) {
      res.set("Retry-After", String(Math.ceil((entry.expires - now) / 1000)));
      return next(new HttpError(429, "RATE_LIMITED", "Too many requests. Try again later."));
    }
    next();
  };
};

export const createUploadConcurrencyLimit = (maximum = 4) => {
  let active = 0;
  return (req, res, next) => {
    if (active >= maximum) {
      res.set("Retry-After", "5");
      return next(new HttpError(503, "UPLOAD_BUSY", "Upload capacity reached. Try again shortly."));
    }
    active++;
    let released = false;
    const release = () => {
      if (!released) { active--; released = true; }
    };
    req.releaseUploadSlot = release;
    res.once("finish", release);
    res.once("close", () => { if (!req.uploadProcessing) release(); });
    next();
  };
};
