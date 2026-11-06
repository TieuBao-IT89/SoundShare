-- Additive V3 migration. Existing tracks remain private; no content is published.
ALTER TABLE users ADD COLUMN bio VARCHAR(500) NOT NULL DEFAULT '';
ALTER TABLE users ADD COLUMN profile_status VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (profile_status IN ('active','hidden'));
ALTER TABLE users ADD COLUMN avatar_asset_id UUID;
ALTER TABLE users ADD COLUMN cover_asset_id UUID;
ALTER TABLE users ADD CONSTRAINT users_avatar_owner_fk FOREIGN KEY (avatar_asset_id, clerk_user_id) REFERENCES media_assets(id, clerk_user_id);
ALTER TABLE users ADD CONSTRAINT users_cover_owner_fk FOREIGN KEY (cover_asset_id, clerk_user_id) REFERENCES media_assets(id, clerk_user_id);
ALTER TABLE users ADD CONSTRAINT users_public_username_check CHECK (username IS NULL OR (
  username = lower(username) AND length(username) BETWEEN 3 AND 24
  AND username ~ '^[a-z0-9_][a-z0-9._]*[a-z0-9_]$'
  AND username NOT IN ('admin','support','soundshare','system','official','search')));
CREATE UNIQUE INDEX users_username_lower_unique ON users(lower(username)) WHERE username IS NOT NULL;
CREATE INDEX users_username_prefix ON users(lower(username) text_pattern_ops);
CREATE INDEX users_display_name_lower ON users(lower(display_name));

ALTER TABLE private_tracks ADD COLUMN visibility VARCHAR(10) NOT NULL DEFAULT 'private' CHECK (visibility IN ('private','public'));
ALTER TABLE private_tracks ADD COLUMN status VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active','hidden','deleted'));
ALTER TABLE private_tracks ADD COLUMN duration_seconds DOUBLE PRECISION CHECK (duration_seconds > 0 AND duration_seconds < 86400);
ALTER TABLE private_tracks ADD COLUMN rights_confirmed_at TIMESTAMPTZ;
ALTER TABLE private_tracks ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE private_tracks ADD CONSTRAINT tracks_public_rights_check CHECK (visibility <> 'public' OR rights_confirmed_at IS NOT NULL);
CREATE INDEX tracks_public_created ON private_tracks(created_at DESC, id DESC) WHERE visibility = 'public' AND status = 'active';
CREATE INDEX tracks_public_genre ON private_tracks(lower(genre), created_at DESC) WHERE visibility = 'public' AND status = 'active';

CREATE TABLE user_follows (
  follower_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id), CHECK (follower_id <> following_id)
);
CREATE INDEX follows_target_created ON user_follows(following_id, created_at DESC, follower_id);
CREATE TABLE track_likes (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES private_tracks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), PRIMARY KEY (user_id, track_id)
);
CREATE INDEX track_likes_recent ON track_likes(created_at DESC, track_id);
INSERT INTO track_likes(user_id,track_id,created_at)
  SELECT u.id,f.track_id,f.created_at FROM private_track_favorites f JOIN users u ON u.clerk_user_id=f.clerk_user_id ON CONFLICT DO NOTHING;
CREATE TABLE saved_tracks (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES private_tracks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), PRIMARY KEY (user_id, track_id)
);
CREATE INDEX saved_tracks_recent ON saved_tracks(created_at DESC, track_id);

CREATE TABLE playback_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES private_tracks(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_heartbeat_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  credited_ms INTEGER NOT NULL DEFAULT 0 CHECK (credited_ms >= 0),
  last_position_ms INTEGER NOT NULL DEFAULT 0 CHECK (last_position_ms >= 0),
  threshold_ms INTEGER NOT NULL CHECK (threshold_ms > 0 AND threshold_ms <= 30000),
  is_valid BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX playback_sessions_user_recent ON playback_sessions(user_id, started_at DESC);
CREATE INDEX playback_sessions_track_recent ON playback_sessions(track_id, started_at DESC);
CREATE TABLE valid_play_events (
  session_id UUID PRIMARY KEY REFERENCES playback_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES private_tracks(id) ON DELETE CASCADE,
  dedup_bucket BIGINT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, track_id, dedup_bucket)
);
CREATE INDEX valid_plays_recent ON valid_play_events(created_at DESC, track_id, user_id);

-- Reuse legacy playlist metadata; this relation targets the active media catalog.
CREATE TABLE playlist_tracks (
  playlist_id UUID NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES private_tracks(id) ON DELETE CASCADE,
  position INTEGER NOT NULL CHECK (position >= 0),
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (playlist_id, track_id), UNIQUE (playlist_id, position)
);
CREATE TABLE content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  track_id UUID REFERENCES private_tracks(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES users(id) ON DELETE CASCADE,
  reason VARCHAR(30) NOT NULL CHECK (reason IN ('copyright','abuse','spam','other')),
  details VARCHAR(1000) NOT NULL DEFAULT '',
  status VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','reviewed','dismissed')),
  resolution VARCHAR(10) CHECK (resolution IN ('hide','restore','dismiss')),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK ((track_id IS NOT NULL)::integer + (profile_id IS NOT NULL)::integer = 1)
);
CREATE UNIQUE INDEX reports_track_once ON content_reports(reporter_id, track_id) WHERE track_id IS NOT NULL;
CREATE UNIQUE INDEX reports_profile_once ON content_reports(reporter_id, profile_id) WHERE profile_id IS NOT NULL;

-- A receipt makes repeated owned deletions idempotent; cleanup is retryable.
CREATE TABLE track_deletions (
  track_id UUID PRIMARY KEY,
  clerk_user_id TEXT NOT NULL REFERENCES users(clerk_user_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE media_cleanup_jobs (
  asset_id UUID PRIMARY KEY REFERENCES media_assets(id) ON DELETE CASCADE,
  track_id UUID NOT NULL REFERENCES track_deletions(track_id) ON DELETE CASCADE,
  clerk_user_id TEXT NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  last_error_code VARCHAR(40),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
