export const getClerkOptions = (env = process.env) => {
  const publishableKey = env.CLERK_PUBLISHABLE_KEY;
  if (!publishableKey || !env.CLERK_SECRET_KEY) {
    throw new Error("Configure CLERK_PUBLISHABLE_KEY and CLERK_SECRET_KEY.");
  }
  // Decode trusted server configuration, never an unverified token.
  const host = Buffer.from(publishableKey.replace(/^pk_(test|live)_/, ""), "base64")
    .toString("utf8").replace(/\$$/, "");
  if (!/^[a-z0-9.-]+$/i.test(host)) {
    throw new Error("Invalid Clerk publishable key configuration.");
  }
  return {
    publishableKey,
    secretKey: env.CLERK_SECRET_KEY,
    issuer: `https://${host}`,
    audience: env.CLERK_AUDIENCE || "soundshare-api",
    authorizedParties: env.CLERK_AUTHORIZED_PARTIES
      ?.split(",").map((origin) => origin.trim()).filter(Boolean),
    jwtKey: env.CLERK_JWT_KEY?.replaceAll("\\n", "\n"),
    debug: false,
  };
};
