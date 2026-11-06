import "dotenv/config";
import { z } from "zod";
import { createModerationService } from "../src/services/moderation.service.js";
const args = Object.fromEntries(
  process.argv.slice(2).map((value) => value.replace(/^--/, "").split("=")),
);
const options = z
  .object({ report: z.uuid(), action: z.enum(["hide", "restore", "dismiss"]) })
  .strict()
  .safeParse(args);
if (!options.success) {
  console.error(
    "Usage: node scripts/moderate-report.mjs --report=<uuid> --action=hide|restore|dismiss",
  );
  process.exitCode = 1;
} else {
  const { pool } = await import("../src/config/database.js");
  try {
    const result = await createModerationService(pool).review(
      options.data.report,
      options.data.action,
    );
    console.log(JSON.stringify(result));
  } catch {
    console.error("Moderation failed; connection and report details omitted.");
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}
