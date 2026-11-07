import { HttpError } from "../utils/http-error.js";
// This service is intentionally not mounted on a client REST route. Only the
// trusted server operator CLI can invoke it; client claims cannot grant access.
export const createModerationService = (pool) => ({
  async review(reportId, action) {
    if (!["hide", "restore", "dismiss"].includes(action))
      throw new HttpError(
        400,
        "VALIDATION_ERROR",
        "Invalid moderation action.",
      );
    const client = await pool.connect();
    let open = false,
      broken = false;
    try {
      await client.query("BEGIN");
      open = true;
      const row = (
        await client.query(
          "SELECT * FROM content_reports WHERE id=$1 FOR UPDATE",
          [reportId],
        )
      ).rows[0];
      if (!row)
        throw new HttpError(404, "REPORT_NOT_FOUND", "Report not found.");
      if (action === "hide" || action === "restore") {
        if (row.track_id)
          await client.query(
            "UPDATE private_tracks SET status=$2,updated_at=NOW() WHERE id=$1",
            [row.track_id, action === "hide" ? "hidden" : "active"],
          );
        else
          await client.query(
            "UPDATE users SET profile_status=$2,updated_at=NOW() WHERE id=$1",
            [row.profile_id, action === "hide" ? "hidden" : "active"],
          );
      }
      await client.query(
        "UPDATE content_reports SET status=$2,resolution=$3,reviewed_at=NOW() WHERE id=$1",
        [reportId, action === "hide" ? "reviewed" : "dismissed", action],
      );
      await client.query("COMMIT");
      open = false;
      return { status: action === "hide" ? "reviewed" : "dismissed" };
    } finally {
      if (open)
        try {
          await client.query("ROLLBACK");
        } catch {
          broken = true;
        }
      client.release(broken);
    }
  },
});
