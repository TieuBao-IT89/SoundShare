CREATE TABLE IF NOT EXISTS media_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    clerk_user_id TEXT NOT NULL,

    media_type VARCHAR(20) NOT NULL
        CHECK (media_type IN ('artwork', 'audio')),

    public_id TEXT NOT NULL UNIQUE,

    secure_url TEXT NOT NULL,

    resource_type VARCHAR(20) NOT NULL
        CHECK (resource_type IN ('image', 'video')),

    format VARCHAR(20),

    bytes BIGINT NOT NULL
        CHECK (bytes >= 0),

    original_filename TEXT,

    mime_type VARCHAR(100),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_media_assets_clerk_user_id
    ON media_assets(clerk_user_id);

CREATE INDEX IF NOT EXISTS idx_media_assets_media_type
    ON media_assets(media_type);

CREATE INDEX IF NOT EXISTS idx_media_assets_created_at
    ON media_assets(created_at DESC);
