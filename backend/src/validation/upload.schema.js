import { z } from "zod";
import { extname } from "node:path";
import { HttpError } from "../utils/http-error.js";

export const uploadPolicies = {
  artwork: { maxBytes: 5 * 1024 * 1024, resourceType: "image", formats: ["jpg", "png", "webp"] },
  audio: { maxBytes: 20 * 1024 * 1024, resourceType: "video", formats: ["mp3"] },
};
const metadataSchema = z.object({
  originalname: z.string().min(1).max(255).regex(/^[^/\\\x00-\x1f\x7f]+$/),
  mimetype: z.string().min(1).max(100),
});

// Require complete consecutive MPEG Layer III frames, not just an ID3 prefix.
const mp3Frame = (buffer, offset) => {
  if (offset + 4 > buffer.length || buffer[offset] !== 0xff || (buffer[offset + 1] & 0xe0) !== 0xe0) return null;
  const version = (buffer[offset + 1] >> 3) & 3;
  const layer = (buffer[offset + 1] >> 1) & 3;
  const bitrateIndex = buffer[offset + 2] >> 4;
  const sampleIndex = (buffer[offset + 2] >> 2) & 3;
  if (version === 1 || layer !== 1 || bitrateIndex === 0 || bitrateIndex === 15 || sampleIndex === 3) return null;
  const rates = version === 3
    ? [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320]
    : [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];
  const sampleRate = [44100, 48000, 32000][sampleIndex] / (version === 3 ? 1 : version === 2 ? 2 : 4);
  const length = Math.floor((version === 3 ? 144000 : 72000) * rates[bitrateIndex] / sampleRate) + ((buffer[offset + 2] >> 1) & 1);
  return offset + length <= buffer.length ? { length, version, sampleRate } : null;
};

const isMp3 = (buffer) => {
  let offset = 0;
  if (buffer.subarray(0, 3).toString("ascii") === "ID3") {
    if (buffer.length < 10 || ![2, 3, 4].includes(buffer[3]) || buffer.subarray(6, 10).some((byte) => byte > 127)) return false;
    offset = 10 + buffer[6] * 2097152 + buffer[7] * 16384 + buffer[8] * 128 + buffer[9];
    if (buffer[3] === 4 && (buffer[5] & 0x10)) offset += 10;
  }
  const first = mp3Frame(buffer, offset);
  const second = first && mp3Frame(buffer, offset + first.length);
  return Boolean(second && first.version === second.version && first.sampleRate === second.sampleRate);
};

const detectType = (buffer) => {
  if (buffer.length >= 12 && buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return "png";
  if (buffer.length >= 4 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return "jpg";
  if (buffer.length >= 16 && buffer.toString("ascii", 0, 4) === "RIFF" && buffer.toString("ascii", 8, 12) === "WEBP") return "webp";
  return isMp3(buffer) ? "mp3" : null;
};

export const validateUpload = (file, mediaType) => {
  const policy = uploadPolicies[mediaType];
  if (!policy) throw new HttpError(400, "VALIDATION_ERROR", "Unsupported media type.");
  if (!file) throw new HttpError(400, "FILE_REQUIRED", "Send a file in the file field.");
  if (!metadataSchema.safeParse(file).success || !Buffer.isBuffer(file.buffer) || file.buffer.length === 0) {
    throw new HttpError(400, "INVALID_FILE", "The file or its filename is invalid.");
  }
  if (file.buffer.length > policy.maxBytes) throw new HttpError(413, "FILE_TOO_LARGE", "The file exceeds the upload size limit.");
  const format = detectType(file.buffer);
  const extensions = { jpg: [".jpg", ".jpeg"], png: [".png"], webp: [".webp"], mp3: [".mp3"] };
  const mimeTypes = { jpg: "image/jpeg", png: "image/png", webp: "image/webp", mp3: "audio/mpeg" };
  if (!policy.formats.includes(format) || !extensions[format]?.includes(extname(file.originalname).toLowerCase()) || mimeTypes[format] !== file.mimetype) {
    throw new HttpError(415, "INVALID_FILE_TYPE", "File content, extension and MIME type must match an allowed format.");
  }
  return { ...policy, format, mimeType: mimeTypes[format] };
};

export const assetIdSchema = z.uuid();
