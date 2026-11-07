// Every attempt uses the existing media lock, reference check and Storage-first
// deletion. Jobs survive provider failures and process restarts.
export const createMediaCleanupService = ({ pool, uploadService }) => ({
  async process({ owner, trackId, limit = 20 } = {}) {
    const jobs = (
      await pool.query(
        `SELECT * FROM media_cleanup_jobs WHERE ($1::text IS NULL OR clerk_user_id=$1)
      AND ($2::uuid IS NULL OR track_id=$2) AND (last_attempt_at IS NULL OR last_attempt_at<NOW()-INTERVAL '1 minute')
      ORDER BY created_at LIMIT $3`,
        [owner || null, trackId || null, limit],
      )
    ).rows;
    for (const job of jobs) {
      try {
        await uploadService.remove({
          id: job.asset_id,
          userId: job.clerk_user_id,
          requestId: "media-cleanup",
        });
        await pool.query("DELETE FROM media_cleanup_jobs WHERE asset_id=$1", [
          job.asset_id,
        ]);
      } catch (error) {
        if (["MEDIA_NOT_FOUND", "MEDIA_IN_USE"].includes(error.code))
          await pool.query("DELETE FROM media_cleanup_jobs WHERE asset_id=$1", [
            job.asset_id,
          ]);
        else
          await pool.query(
            "UPDATE media_cleanup_jobs SET attempts=attempts+1,last_attempt_at=NOW(),last_error_code=$2 WHERE asset_id=$1",
            [
              job.asset_id,
              [
                "STORAGE_DELETE_FAILED",
                "DATABASE_UNAVAILABLE",
                "MEDIA_BUSY",
              ].includes(error.code)
                ? error.code
                : "CLEANUP_PENDING",
            ],
          );
      }
    }
    return Number(
      (
        await pool.query(
          "SELECT count(*) AS pending FROM media_cleanup_jobs WHERE ($1::text IS NULL OR clerk_user_id=$1) AND ($2::uuid IS NULL OR track_id=$2)",
          [owner || null, trackId || null],
        )
      ).rows[0].pending,
    );
  },
});
