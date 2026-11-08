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
import { createSocialRepository } from "./src/repositories/social.repository.js";
import { createSocialService } from "./src/services/social.service.js";
import { createNotificationDelivery } from "./src/services/notification-delivery.service.js";
import { assertSchemaReady } from "./src/database/schema-readiness.js";
import { createLyricsRepository } from './src/repositories/lyrics.repository.js';
import { createLyricsService } from './src/services/lyrics.service.js';
import { createKeepAliveJob } from './src/config/cron.js';

try {
  await assertSchemaReady(pool);
} catch (error) {
  console.error(error.message);
  await pool.end();
  process.exit(1);
}

const storage = createCloudinaryStorage(cloudinary);
const uploadService = createUploadService({
  repository: createMediaRepository(pool),
  storage,
});
const cleanupService = createMediaCleanupService({ pool, uploadService });
const notificationDelivery = createNotificationDelivery(
  createSocialRepository(pool),
);
let deliveryRunning = false;
const deliverNotifications = async () => {
  if (deliveryRunning) return;
  deliveryRunning = true;
  try {
    await notificationDelivery.process({ batches: 5 });
  } catch {
    console.warn(JSON.stringify({ code: "NOTIFICATION_DELIVERY_PENDING" }));
  } finally {
    deliveryRunning = false;
  }
};
// Fast in-process delivery. The durable outbox and scheduled worker command
// provide recovery across restarts and instances; this timer is only a wakeup.
const notificationTimer = setInterval(deliverNotifications, 15000);
notificationTimer.unref();
void deliverNotifications();
const app = createApp({
  lyricsService: createLyricsService(createLyricsRepository(pool)),
  socialService: createSocialService({
    repository: createSocialRepository(pool),
    communityRepository: createCommunityRepository(pool),
    storage,
  }),
  checkDatabaseConnection,
  trustProxyHops: Number(process.env.TRUST_PROXY_HOPS || 0),
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

const keepAliveJob = createKeepAliveJob();
const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`
====================================
       SoundShare Backend
====================================
Server: http://localhost:${PORT}
Health: http://localhost:${PORT}/api/v1/health
Environment: ${process.env.NODE_ENV || "development"}
====================================
  `);
  keepAliveJob.start();
});
server.once("close", () => keepAliveJob.stop());
