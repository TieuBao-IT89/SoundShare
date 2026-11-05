-- A private catalog for verified Clerk users. Existing public song tables are retained.
CREATE UNIQUE INDEX IF NOT EXISTS idx_media_assets_id_owner ON media_assets(id, clerk_user_id);
CREATE TABLE IF NOT EXISTS private_tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clerk_user_id TEXT NOT NULL REFERENCES users(clerk_user_id) ON DELETE CASCADE,
    audio_asset_id UUID NOT NULL UNIQUE,
    artwork_asset_id UUID,
    title VARCHAR(120) NOT NULL CHECK (length(trim(title)) > 0),
    artist VARCHAR(120) NOT NULL CHECK (length(trim(artist)) > 0),
    genre VARCHAR(100) NOT NULL CHECK (length(trim(genre)) > 0),
    description VARCHAR(1000) NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (id, clerk_user_id),
    FOREIGN KEY (audio_asset_id, clerk_user_id) REFERENCES media_assets(id, clerk_user_id),
    FOREIGN KEY (artwork_asset_id, clerk_user_id) REFERENCES media_assets(id, clerk_user_id)
);
CREATE INDEX IF NOT EXISTS idx_private_tracks_owner_created ON private_tracks(clerk_user_id, created_at DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_private_tracks_owner_genre ON private_tracks(clerk_user_id, lower(genre));
CREATE TABLE IF NOT EXISTS private_track_favorites (
    clerk_user_id TEXT NOT NULL,
    track_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (clerk_user_id, track_id),
    FOREIGN KEY (track_id, clerk_user_id) REFERENCES private_tracks(id, clerk_user_id) ON DELETE CASCADE
);
