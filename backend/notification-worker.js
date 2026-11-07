import "dotenv/config";
import { pool } from "./src/config/database.js";
import { createSocialRepository } from "./src/repositories/social.repository.js";
import { createNotificationDelivery } from "./src/services/notification-delivery.service.js";
// Invoke from a scheduler every minute. Database state is the retry guarantee;
// no process-local timer or HTTP request is required for delivery.
try {
  await createNotificationDelivery(createSocialRepository(pool)).process({
    batches: 50,
  });
  await pool.query(
    "DELETE FROM shorts_snapshots WHERE id IN (SELECT id FROM shorts_snapshots WHERE expires_at<NOW() LIMIT 500)",
  );
} catch {
  console.error(JSON.stringify({ code: "NOTIFICATION_DELIVERY_PENDING" }));
  process.exitCode = 1;
} finally {
  await pool.end();
}
