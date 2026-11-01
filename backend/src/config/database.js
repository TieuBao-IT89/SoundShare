import pg from "pg";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not configured");
}

// Create PostgreSQL connection pool
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
  },
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

// Handle unexpected connection errors
pool.on("error", (error) => {
  console.error("Unexpected PostgreSQL pool error:", error.message);
});

// Reusable query function
export const query = (text, params) => {
  return pool.query(text, params);
};

// Check database connection
export const checkDatabaseConnection = async () => {
  const result = await query(
    "SELECT NOW() AS current_time, current_database() AS database_name",
  );

  return result.rows[0];
};

// Close all database connections
export const closeDatabaseConnection = async () => {
  await pool.end();
};
