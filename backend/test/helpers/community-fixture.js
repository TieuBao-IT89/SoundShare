import { PGlite } from "@electric-sql/pglite";
import { readdir, readFile } from "node:fs/promises";
import { generateKeyPairSync, sign } from "node:crypto";
export const communityDatabase = async () => {
  const db = new PGlite();
  const migrations = new URL("../../src/database/migrations/", import.meta.url);
  for (const file of (await readdir(migrations))
    .filter((v) => v.endsWith(".sql"))
    .sort())
    await db.exec(await readFile(new URL(file, migrations), "utf8"));
  let queue = Promise.resolve();
  const acquire = async () => {
    const previous = queue;
    let release;
    queue = new Promise((resolve) => {
      release = resolve;
    });
    await previous;
    return release;
  };
  const query = (...args) =>
    db
      .query(...args)
      .then((result) => ({
        ...result,
        rowCount: result.affectedRows ?? result.rows.length,
      }));
  const pool = {
    query: async (...args) => {
      const release = await acquire();
      try {
        return await query(...args);
      } finally {
        release();
      }
    },
    connect: async () => {
      const release = await acquire();
      return { query, release };
    },
  };
  return { db, pool, close: () => db.close() };
};
const keys = generateKeyPairSync("rsa", { modulusLength: 2048 });
const issuer = "https://fixture.clerk.accounts.dev";
export const clerkOptions = {
  publishableKey: `pk_test_${Buffer.from("fixture.clerk.accounts.dev$").toString("base64")}`,
  secretKey: "sk_test_fixture",
  jwtKey: keys.publicKey.export({ type: "spki", format: "pem" }),
  issuer,
  audience: "soundshare-api",
};
export const token = (sub = "user_a", claims = {}) => {
  const now = Math.floor(Date.now() / 1000);
  const input = [
    { alg: "RS256", kid: "fixture" },
    {
      sub,
      sid: "sess_fixture",
      sts: "active",
      v: 2,
      iss: issuer,
      aud: "soundshare-api",
      iat: now,
      nbf: now - 5,
      exp: now + 120,
      ...claims,
    },
  ]
    .map((value) => Buffer.from(JSON.stringify(value)).toString("base64url"))
    .join(".");
  return `${input}.${sign("RSA-SHA256", Buffer.from(input), keys.privateKey).toString("base64url")}`;
};
