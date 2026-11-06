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
import { createCommunityRepository } from "./src/repositories/community.repository.js";
import { createCommunityService } from "./src/services/community.service.js";
import { createMediaCleanupService } from "./src/services/media-cleanup.service.js";

const storage = createCloudinaryStorage(cloudinary);
const uploadService = createUploadService({
  repository: createMediaRepository(pool),
  storage,
});
const cleanupService = createMediaCleanupService({ pool, uploadService });
const app = createApp({
  checkDatabaseConnection,
  uploadService,
  communityService: createCommunityService({
    repository: createCommunityRepository(pool),
    storage,
    cleanupService,
  }),
  trackService: createTrackService({
    repository: createTrackRepository(pool),
    storage,
    uploadService,
  }),
  webDirectory:
    process.env.SERVE_FLUTTER_WEB === "true"
      ? fileURLToPath(new URL("../build/web/", import.meta.url))
      : undefined,
});

const PORT = process.env.PORT || 3000;
const cleanupTimer = setInterval(() => {
  cleanupService
    .process()
    .catch(() =>
      console.warn(JSON.stringify({ code: "MEDIA_CLEANUP_PENDING" })),
    );
}, 60000);
cleanupTimer.unref();

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
