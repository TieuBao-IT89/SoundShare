import { Router } from "express";
import { createHealthController } from "../controllers/health.controller.js";

export const createHealthRouter = (checkDatabaseConnection) => {
  const router = Router();
  router.get("/", createHealthController(checkDatabaseConnection));
  return router;
};
