import "dotenv/config";

import app from "./src/app.js";

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
====================================
       SoundShare Backend
====================================
Server: http://localhost:${PORT}
Health: http://localhost:${PORT}/api/v1/health
Environment: ${process.env.NODE_ENV || "development"}
====================================
  `);
});
