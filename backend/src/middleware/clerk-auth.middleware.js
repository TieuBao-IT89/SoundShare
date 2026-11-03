import { getAuth } from "@clerk/express";

export const requireClerkAuth = (req, res, next) => {
  const { isAuthenticated, userId } = getAuth(req);

  if (!isAuthenticated || !userId) {
    return res.status(401).json({
      success: false,
      error: {
        code: "UNAUTHORIZED",
        message: "Authentication required",
      },
    });
  }

  // Make the verified Clerk user ID available to the controller.
  req.clerkUserId = userId;

  next();
};
