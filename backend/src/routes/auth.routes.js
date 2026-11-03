import express from "express";

import { getCurrentUser } from "../controllers/auth.controller.js";
import { requireClerkAuth } from "../middleware/clerk-auth.middleware.js";

const router = express.Router();

// Get current authenticated user
router.get("/me", requireClerkAuth, getCurrentUser);

export default router;
