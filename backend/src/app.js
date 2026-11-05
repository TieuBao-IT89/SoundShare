import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { clerkMiddleware } from "@clerk/express";

import { createHealthRouter } from "./routes/health.routes.js";
import { createAuthRouter } from "./routes/auth.routes.js";
import { createUploadRouter } from "./routes/upload.routes.js";
import { createRequireClerkAuth } from "./middleware/clerk-auth.middleware.js";
import { getClerkOptions } from "./config/clerk.js";
import { requestContext } from "./middleware/request-context.middleware.js";
import { createRateLimit } from "./middleware/upload-limits.middleware.js";
import { HttpError } from "./utils/http-error.js";
import { notFoundHandler } from "./middleware/not-found.middleware.js";
import { errorHandler } from "./middleware/error.middleware.js";

export const createApp = ({ uploadService, checkDatabaseConnection, clerkOptions = getClerkOptions(), logging = true, uploadRateLimit } = {}) => {
  const app = express();
  app.disable("x-powered-by");
  app.use(requestContext);
  app.use(helmet());
  app.use(cors({ exposedHeaders: ["X-Request-Id", "Retry-After"] }));
  if (logging) {
    // Route templates exclude query strings, user IDs, filenames and signed URLs.
    app.use(morgan((tokens, req, res) => JSON.stringify({
      requestId: req.requestId, method: req.method, route: req.route?.path || "unmatched",
      status: res.statusCode, durationMs: tokens["response-time"](req, res),
    })));
  }
  app.use("/api/v1/health", createHealthRouter(checkDatabaseConnection));

  const authenticate = clerkMiddleware(clerkOptions);
  const requireAuth = createRequireClerkAuth(clerkOptions);
  app.use("/api/v1", createRateLimit({ limit: 120, key: (req) => req.ip }));
  app.use("/api/v1", (req, res, next) => {
    // APIs accept Bearer tokens only and do not use cookie handshake redirects.
    if (!req.get("authorization")) return next();
    const authorization = req.get("authorization");
    if (authorization.length > 8192 || !/^Bearer [A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/i.test(authorization)) {
      return next(new HttpError(401, "UNAUTHORIZED", "A valid Clerk Bearer session token is required."));
    }
    authenticate(req, res, (error) => next(error
      ? new HttpError(401, "UNAUTHORIZED", "A valid Clerk Bearer session token is required.")
      : undefined));
  });
  app.use(express.json({ limit: "1mb" }));
  app.use("/api/v1/auth", createAuthRouter(requireAuth));
  app.use("/api/v1/uploads", createUploadRouter({ service: uploadService, requireAuth, rateLimit: uploadRateLimit }));
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
};
