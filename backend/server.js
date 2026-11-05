import "dotenv/config";
import { fileURLToPath } from "node:url";

import { createApp } from "./src/app.js";
import { pool, checkDatabaseConnection } from "./src/config/database.js";
import cloudinary from "./src/config/cloudinary.js";
import { createMediaRepository } from "./src/repositories/media.repository.js";
import { createCloudinaryStorage } from "./src/services/cloudinary-storage.service.js";
import { createUploadService } from "./src/services/upload.service.js";
import { createTrackRepository } from "./src/repositories/track.repository.js";
import { createTrackService } from "./src/services/track.service.js";

const storage = createCloudinaryStorage(cloudinary);
const uploadService = createUploadService({ repository: createMediaRepository(pool), storage });
const app = createApp({
  checkDatabaseConnection,
  uploadService,
  trackService: createTrackService({ repository: createTrackRepository(pool), storage, uploadService }),
  webDirectory: process.env.SERVE_FLUTTER_WEB === "true" ? fileURLToPath(new URL("../build/web/", import.meta.url)) : undefined,
});

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
