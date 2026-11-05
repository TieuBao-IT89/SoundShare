import express from "express";

import { getCurrentUser } from "../controllers/auth.controller.js";
export const createAuthRouter = (requireAuth) => {
  const router = express.Router();
  router.get("/me", requireAuth, getCurrentUser);
  return router;
};
