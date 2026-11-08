import "dotenv/config";
import { pool } from "../config/database.js";
import { assertSchemaReady } from "./schema-readiness.js";
try {
  await assertSchemaReady(pool);
  console.log("Database schema is ready.");
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
