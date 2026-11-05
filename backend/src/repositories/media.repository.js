import { HttpError } from "../utils/http-error.js";

export const createMediaRepository = (pool) => {
  const queries = (client) => ({
    isReferencedByTrack: async (id, owner) => (await client.query(
      "SELECT EXISTS(SELECT 1 FROM private_tracks WHERE clerk_user_id = $2 AND (audio_asset_id = $1 OR artwork_asset_id = $1)) AS used", [id, owner],
    )).rows[0].used,
    findById: async (id, userId) => {
      const result = await client.query(
        "SELECT * FROM media_assets WHERE id = $1 AND clerk_user_id = $2",
        [id, userId],
      );
      return result.rows[0] || null;
    },
    deleteById: async (id, userId) => {
      await client.query(
        "DELETE FROM media_assets WHERE id = $1 AND clerk_user_id = $2",
        [id, userId],
      );
    },
    findByPublicId: async (publicId, userId) => {
      const result = await client.query(
        "SELECT * FROM media_assets WHERE public_id = $1 AND clerk_user_id = $2",
        [publicId, userId],
      );
      return result.rows[0] || null;
    },
    insert: async (asset) => {
      await client.query("SAVEPOINT insert_media_asset");
      try {
        const result = await client.query(
          `INSERT INTO media_assets
            (clerk_user_id, media_type, public_id, secure_url, resource_type,
             format, bytes, original_filename, mime_type)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
          [asset.clerk_user_id, asset.media_type, asset.public_id, asset.secure_url,
            asset.resource_type, asset.format, asset.bytes, asset.original_filename, asset.mime_type],
        );
        await client.query("RELEASE SAVEPOINT insert_media_asset");
        return result.rows[0];
      } catch (error) {
        await client.query("ROLLBACK TO SAVEPOINT insert_media_asset");
        await client.query("RELEASE SAVEPOINT insert_media_asset");
        throw error;
      }
    },
  });
  return {
    withAssetLock: async (publicId, action) => {
      const client = await pool.connect();
      let transactionOpen = false;
      let destroyConnection = false;
      try {
        await client.query("BEGIN");
        transactionOpen = true;
        // Transaction locks remain valid through Neon's transaction-mode pooler.
        const result = await client.query("SELECT pg_try_advisory_xact_lock(hashtextextended($1, 0)) AS locked", [publicId]);
        if (!result.rows[0].locked) throw new HttpError(409, "UPLOAD_IN_PROGRESS", "This upload is already in progress. Retry shortly.");
        const value = await action(queries(client));
        await client.query("COMMIT");
        transactionOpen = false;
        return value;
      } finally {
        if (transactionOpen) {
          try {
            await client.query("ROLLBACK");
          } catch {
            destroyConnection = true;
          }
        }
        client.release(destroyConnection);
      }
    },
    findById: queries(pool).findById,
  };
};
