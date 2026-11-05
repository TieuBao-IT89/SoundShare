import "dotenv/config";

import { createApp } from "./src/app.js";
import { pool, checkDatabaseConnection } from "./src/config/database.js";
import cloudinary from "./src/config/cloudinary.js";
import { createMediaRepository } from "./src/repositories/media.repository.js";
import { createCloudinaryStorage } from "./src/services/cloudinary-storage.service.js";
import { createUploadService } from "./src/services/upload.service.js";

const app = createApp({
  checkDatabaseConnection,
  uploadService: createUploadService({
    repository: createMediaRepository(pool),
    storage: createCloudinaryStorage(cloudinary),
  }),
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
