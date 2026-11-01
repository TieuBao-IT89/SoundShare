import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";

import healthRoutes from "./routes/health.routes.js";
import { notFoundHandler } from "./middleware/not-found.middleware.js";
import { errorHandler } from "./middleware/error.middleware.js";

const app = express();

// Security
app.use(helmet());

// HTTP request logging
app.use(morgan("dev"));

// CORS (open by default during development)
app.use(cors());

// Parse JSON
app.use(express.json({ limit: "1mb" }));

// API routes
app.use("/api/v1/health", healthRoutes);

// Handle unknown routes and errors
app.use(notFoundHandler);
app.use(errorHandler);

export default app;
