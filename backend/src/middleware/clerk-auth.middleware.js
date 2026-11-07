import { getAuth } from "@clerk/express";
import { HttpError } from "../utils/http-error.js";

export const createRequireClerkAuth = ({ issuer, audience, onReject }) => (req, res, next) => {
  const authorization = req.get("authorization") || "";
  if (authorization.length > 8192 || !/^Bearer [A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/i.test(authorization)) {
    return next(new HttpError(401, "UNAUTHORIZED", "A valid Clerk Bearer session token is required."));
  }
  // clerkMiddleware has already verified the signature with trusted Clerk keys.
  const auth = getAuth(req, { acceptsToken: "session_token" });
  const claims = auth.sessionClaims;
  const now = Math.floor(Date.now() / 1000);
  const audiences = Array.isArray(claims?.aud) ? claims.aud : [claims?.aud];
  if (!auth.isAuthenticated || !auth.userId || !auth.sessionId || auth.sessionStatus === "pending" ||
      claims?.sub !== auth.userId || claims?.iss !== issuer ||
      !audiences.includes(audience) || !Number.isInteger(claims?.exp) || claims.exp <= now) {
    // Pick only a provider reason code. Never log the debug object or claims.
    const reason = auth.isAuthenticated && !audiences.includes(audience)
      ? (claims?.aud === undefined ? "token-audience-missing" : "token-audience-mismatch") : auth.debug?.().reason;
    onReject?.(/^[a-z0-9-]{1,80}$/.test(reason || "") ? reason : "session-rejected", req.requestId);
    return next(new HttpError(401, "UNAUTHORIZED", "A valid Clerk Bearer session token is required."));
  }
  req.clerkUserId = auth.userId;
  next();
};
