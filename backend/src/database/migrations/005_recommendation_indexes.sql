-- Additive indexes for bounded per-listener signals and recommendation seeds.
-- No user data is changed. Apply with the existing migration runner.
CREATE INDEX valid_plays_user_recent
  ON valid_play_events(user_id, created_at DESC, track_id);
CREATE INDEX tracks_public_genre_recent
  ON private_tracks(lower(btrim(genre)), created_at DESC, id DESC)
  WHERE visibility='public' AND status='active';
CREATE INDEX track_likes_user_recent
  ON track_likes(user_id, created_at DESC, track_id);
CREATE INDEX saved_tracks_user_recent
  ON saved_tracks(user_id, created_at DESC, track_id);
CREATE INDEX follows_user_recent
  ON user_follows(follower_id, created_at DESC, following_id);
