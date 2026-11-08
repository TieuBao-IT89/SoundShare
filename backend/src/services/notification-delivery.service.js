import { notificationVisible } from "../repositories/social.repository.js";
// A durable outbox, claimed with SKIP LOCKED. Each transaction performs at most
// one 100-recipient batch. Safe to run concurrently or restart after a crash.
export const createNotificationDelivery = (repository) => ({
  async process({ batches = 10 } = {}) {
    let processed = 0;
    for (let i = 0; i < Math.min(batches, 50); i++) {
      const result = await repository.tx(async (c) => {
        const e = (
          await c.query(
            "SELECT * FROM social_outbox WHERE completed_at IS NULL AND available_at<=clock_timestamp() ORDER BY id LIMIT 1 FOR UPDATE SKIP LOCKED",
          )
        ).rows[0];
        if (!e) return false;
        await c.query("SAVEPOINT delivery");
        try {
          const recipients =
            e.type === "new_track"
              ? (
                  await c.query(
                    `SELECT follower_id AS id FROM user_follows WHERE following_id=$1 AND created_at<=$2 AND ($3::uuid IS NULL OR follower_id>$3::uuid) ORDER BY follower_id LIMIT 101`,
                    [e.actor_id, e.created_at, e.after_user],
                  )
                ).rows
              : [{ id: e.recipient_id }];
          const ids = recipients
            .slice(0, 100)
            .map((v) => v.id)
            .filter(Boolean);
          const preference = {
            follower: "followers",
            comment: "comments",
            reply: "replies",
            song_like: "likes",
            comment_like: "likes",
            new_track: "new_tracks",
          }[e.type];
          // Reuse the same privacy predicate for delivery, inbox and unread counts.
          await c.query(
            `INSERT INTO notifications(recipient_id,actor_id,type,track_id,comment_id,event_key,created_at)
      SELECT target.id,$1,$2,$3,$4,$5,$6 FROM users target LEFT JOIN notification_preferences pref ON pref.user_id=target.id
      CROSS JOIN (SELECT $1::uuid AS actor_id,$2::text AS type,$3::uuid AS track_id,$4::uuid AS comment_id) n
      JOIN users actor ON actor.id=n.actor_id LEFT JOIN private_tracks t ON t.id=n.track_id LEFT JOIN users u ON u.clerk_user_id=t.clerk_user_id
      WHERE target.id=ANY($7::uuid[]) AND target.id<>$1 AND target.profile_status='active' AND COALESCE(pref.${preference},TRUE)
      AND ${notificationVisible.replaceAll("n.recipient_id", "target.id")} ON CONFLICT(recipient_id,event_key) DO NOTHING`,
            [
              e.actor_id,
              e.type,
              e.track_id,
              e.comment_id,
              e.event_key,
              e.created_at,
              ids,
            ],
          );
          await c.query(
            "UPDATE social_outbox SET after_user=$2,completed_at=CASE WHEN $3 THEN clock_timestamp() ELSE NULL END,attempts=attempts+1 WHERE id=$1",
            [e.id, ids.at(-1) ?? e.after_user, recipients.length <= 100],
          );
          await c.query("RELEASE SAVEPOINT delivery");
        } catch {
          await c.query("ROLLBACK TO SAVEPOINT delivery");
          await c.query(
            "UPDATE social_outbox SET attempts=attempts+1,available_at=clock_timestamp()+LEAST(3600,5*power(2,LEAST(attempts,9))) * INTERVAL '1 second' WHERE id=$1",
            [e.id],
          );
        }
        return true;
      });
      if (!result) break;
      processed++;
    }
    return processed;
  },
});
