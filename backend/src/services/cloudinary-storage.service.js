export const createCloudinaryStorage = (cloudinary) => ({
  upload: ({ buffer, publicId, resourceType, formats }) => new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream({
      public_id: publicId,
      resource_type: resourceType,
      type: "authenticated",
      overwrite: false,
      use_filename: false,
      unique_filename: false,
      allowed_formats: formats,
      timeout: 60000,
    }, (error, result) => error ? reject(error) : resolve(result));
    stream.on("error", reject);
    stream.end(buffer);
  }),
  find: async (publicId, resourceType) => {
    try {
      const asset = await cloudinary.api.resource(publicId, {
        resource_type: resourceType, type: "authenticated", timeout: 15000,
      });
      // Persist an unsigned metadata URL, never a delivery signature.
      return { ...asset, secure_url: cloudinary.url(publicId, {
        resource_type: resourceType, type: "authenticated", format: asset.format,
        version: asset.version, secure: true, sign_url: false, urlAnalytics: false,
      }) };
    } catch (error) {
      if (error.http_code === 404 || error.error?.http_code === 404) return null;
      throw error;
    }
  },
  remove: async (publicId, resourceType) => {
    const result = await cloudinary.uploader.destroy(publicId, {
      resource_type: resourceType, type: "authenticated", invalidate: true, timeout: 15000,
    });
    if (!["ok", "not found"].includes(result.result)) throw new Error("Storage cleanup failed.");
  },
  createAccess: (asset) => {
    const expiresAt = Math.floor(Date.now() / 1000) + 300;
    return {
      url: cloudinary.utils.private_download_url(asset.public_id, asset.format, {
        resource_type: asset.resource_type, type: "authenticated", attachment: false,
        expires_at: expiresAt,
      }),
      expiresAt: new Date(expiresAt * 1000).toISOString(),
    };
  },
});
