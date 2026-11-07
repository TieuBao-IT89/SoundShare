export const getCurrentUser = (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Authenticated successfully",
    data: {
      clerkUserId: req.clerkUserId,
    },
  });
};
