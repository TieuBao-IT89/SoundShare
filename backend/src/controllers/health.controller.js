export const getHealth = (req, res) => {
  return res.status(200).json({
    success: true,
    message: "SoundShare Backend is running",
    data: {
      status: "healthy",
      service: "soundshare-backend",
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    }
  });
};
