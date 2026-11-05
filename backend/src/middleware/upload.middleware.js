import multer from "multer";
import { uploadPolicies } from "../validation/upload.schema.js";
import { HttpError } from "../utils/http-error.js";

export const createUploadMiddleware = (mediaType) => {
  const policy = uploadPolicies[mediaType];
  const parse = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: policy.maxBytes, files: 1, fields: 0, parts: 2, headerPairs: 50 },
    fileFilter: (req, file, callback) => {
      const allowed = mediaType === "audio" ? ["audio/mpeg"] : ["image/jpeg", "image/png", "image/webp"];
      callback(allowed.includes(file.mimetype) ? null : new HttpError(415, "INVALID_FILE_TYPE", "Unsupported file MIME type."), true);
    },
  }).single("file");
  return (req, res, next) => {
    if (Object.keys(req.query).length || !req.is("multipart/form-data")) {
      return next(new HttpError(400, "INVALID_MULTIPART", "Use multipart/form-data with no query parameters."));
    }
    const contentLength = req.get("content-length");
    if (contentLength && Number(contentLength) > policy.maxBytes + 64 * 1024) {
      return next(new HttpError(413, "FILE_TOO_LARGE", "The request exceeds the upload size limit."));
    }
    parse(req, res, (error) => {
      if (error && !(error instanceof multer.MulterError) && !(error instanceof HttpError)) {
        return next(new HttpError(400, "INVALID_MULTIPART", "The multipart request is invalid."));
      }
      next(error);
    });
  };
};

export const uploadArtwork = createUploadMiddleware("artwork");
export const uploadAudio = createUploadMiddleware("audio");
