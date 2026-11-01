import { checkDatabaseConnection } from "../config/database.js";

export const getHealth = async (req, res) => {
  try {
    const database = await checkDatabaseConnection();

    return res.status(200).json({
      success: true,
      message: "SoundShare Backend is running",
      data: {
        status: "healthy",
        service: "soundshare-backend",
        database: {
          status: "connected",
          name: database.database_name,
          checkedAt: database.current_time,
        },
        uptime: process.uptime(),
      },
    });
  } catch (error) {
    console.error("Health check failed:", error.message);

    return res.status(503).json({
      success: false,
      message: "SoundShare Backend is running, but database is unavailable",
      data: {
        status: "unhealthy",
        database: {
          status: "disconnected",
        },
      },
    });
  }
};
