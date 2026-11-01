import "dotenv/config";
import {
  checkDatabaseConnection,
  closeDatabaseConnection,
} from "./src/config/database.js";

try {
  const result = await checkDatabaseConnection();

  console.log("================================");
  console.log("NEON DATABASE CONNECTED!");
  console.log("Database:", result.database_name);
  console.log("Time:", result.current_time);
  console.log("================================");
} catch (error) {
  console.error("DATABASE CONNECTION FAILED!");
  console.error(error.message);
  process.exitCode = 1;
} finally {
  await closeDatabaseConnection();
}
