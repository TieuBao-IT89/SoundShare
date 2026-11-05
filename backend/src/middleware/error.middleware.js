import multer from "multer";
import { HttpError } from "../utils/http-error.js";

export const errorHandler = (err, req, res, next) => {
  if (res.headersSent) return next(err);
  let error = err;
  if (err instanceof multer.MulterError) {
    error = err.code === "LIMIT_FILE_SIZE"
      ? new HttpError(413, "FILE_TOO_LARGE", "The file exceeds the upload size limit.")
      : new HttpError(400, "INVALID_MULTIPART", "Send exactly one file in the file field and no text fields.");
  } else if (err.type === "entity.too.large") {
    error = new HttpError(413, "PAYLOAD_TOO_LARGE", "The request payload is too large.");
  } else if (err.type === "entity.parse.failed") {
    error = new HttpError(400, "INVALID_JSON", "The JSON request is invalid.");
  }
  if (!(error instanceof HttpError)) {
    error = new HttpError(500, "INTERNAL_SERVER_ERROR", "Internal server error.");
  }
  if (error.statusCode >= 500) {
    // Never log driver/provider errors, tokens, request URLs or payloads.
    console.error(JSON.stringify({ requestId: req.requestId, code: error.code }));
  }
  if (error.statusCode === 401) res.set("WWW-Authenticate", "Bearer");
  return res.status(error.statusCode).json({
    success: false,
    error: { code: error.code, message: error.message, requestId: req.requestId },
  });
};
