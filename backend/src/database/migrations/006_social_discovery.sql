-- Additive V9. No existing content is published or removed.
CREATE TABLE track_comments (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 track_id UUID NOT NULL REFERENCES private_tracks(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 parent_id UUID,
 content VARCHAR(1000) NOT NULL CHECK (length(btrim(content)) BETWEEN 1 AND 1000),
 status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','hidden','deleted')),
 created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), deleted_at TIMESTAMPTZ,
 UNIQUE (id,track_id),
 FOREIGN KEY (parent_id,track_id) REFERENCES track_comments(id,track_id) ON DELETE CASCADE,
 CHECK (parent_id IS DISTINCT FROM id)
);
CREATE INDEX comments_track_page ON track_comments(track_id,created_at DESC,id DESC);
CREATE INDEX comments_parent_page ON track_comments(parent_id,created_at DESC,id DESC);
CREATE INDEX comments_user_recent ON track_comments(user_id,created_at DESC);
CREATE INDEX track_likes_by_track ON track_likes(track_id);
CREATE TABLE comment_likes (
 comment_id UUID NOT NULL REFERENCES track_comments(id) ON DELETE CASCADE,
 user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), PRIMARY KEY(comment_id,user_id)
);
ALTER TABLE content_reports DROP CONSTRAINT content_reports_check;
ALTER TABLE content_reports ADD COLUMN comment_id UUID REFERENCES track_comments(id) ON DELETE CASCADE;
ALTER TABLE content_reports ADD CONSTRAINT reports_one_target CHECK (
 (track_id IS NOT NULL)::integer+(profile_id IS NOT NULL)::integer+(comment_id IS NOT NULL)::integer=1
);
CREATE UNIQUE INDEX reports_comment_once ON content_reports(reporter_id,comment_id) WHERE comment_id IS NOT NULL;

CREATE TABLE notification_preferences (
 user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
 followers BOOLEAN NOT NULL DEFAULT TRUE, comments BOOLEAN NOT NULL DEFAULT TRUE,
 replies BOOLEAN NOT NULL DEFAULT TRUE, likes BOOLEAN NOT NULL DEFAULT TRUE,
 new_tracks BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE social_outbox (
 id BIGSERIAL PRIMARY KEY, event_key TEXT NOT NULL UNIQUE,
 type TEXT NOT NULL CHECK (type IN ('follower','comment','reply','song_like','new_track','comment_like')),
 actor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
 track_id UUID REFERENCES private_tracks(id) ON DELETE CASCADE,
 comment_id UUID REFERENCES track_comments(id) ON DELETE CASCADE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 after_user UUID, completed_at TIMESTAMPTZ,
 attempts INTEGER NOT NULL DEFAULT 0, available_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX outbox_pending ON social_outbox(available_at,id) WHERE completed_at IS NULL;
CREATE TABLE notifications (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
 recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 actor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 type TEXT NOT NULL CHECK (type IN ('follower','comment','reply','song_like','new_track','comment_like')),
 track_id UUID REFERENCES private_tracks(id) ON DELETE CASCADE,
 comment_id UUID REFERENCES track_comments(id) ON DELETE CASCADE,
 event_key TEXT NOT NULL, read_at TIMESTAMPTZ,
 created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
 UNIQUE(recipient_id,event_key), CHECK(recipient_id<>actor_id),
 CHECK ((type='follower' AND track_id IS NULL AND comment_id IS NULL) OR (type<>'follower' AND track_id IS NOT NULL)),
 CHECK (type NOT IN ('comment','reply','comment_like') OR comment_id IS NOT NULL)
);
CREATE INDEX notifications_recipient_page ON notifications(recipient_id,created_at DESC,id DESC);
CREATE INDEX notifications_unread ON notifications(recipient_id,created_at DESC,id DESC) WHERE read_at IS NULL;
CREATE TABLE shorts_snapshots (
 id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
 mode TEXT NOT NULL CHECK (mode IN ('for-you','following','trending')),
 track_ids UUID[] NOT NULL CHECK (cardinality(track_ids)<=200),
 expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW()+INTERVAL '30 minutes'
);
CREATE INDEX shorts_snapshot_expiry ON shorts_snapshots(expires_at);
CREATE INDEX shorts_snapshot_owner ON shorts_snapshots(user_id,expires_at);

-- Capture events in the SAME transaction as existing V3/V7 actions. Publishing
-- fanout is deferred; the trigger never scans a creator's followers.
CREATE FUNCTION capture_social_event() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE actor UUID; recipient UUID; parent_recipient UUID; track UUID; comment UUID; kind TEXT; key TEXT;
BEGIN
 IF TG_TABLE_NAME='user_follows' THEN
  actor:=NEW.follower_id; recipient:=NEW.following_id; kind:='follower'; key:='follow:'||actor||':'||recipient;
 ELSIF TG_TABLE_NAME='track_likes' THEN
  actor:=NEW.user_id; track:=NEW.track_id; kind:='song_like'; key:='song-like:'||actor||':'||track;
  SELECT id INTO recipient FROM users WHERE clerk_user_id=(SELECT clerk_user_id FROM private_tracks WHERE id=track);
 ELSIF TG_TABLE_NAME='private_tracks' THEN
  IF NEW.visibility<>'public' OR NEW.status<>'active' THEN RETURN NEW; END IF;
  IF TG_OP='UPDATE' THEN IF OLD.visibility='public' THEN RETURN NEW; END IF; END IF;
  SELECT id INTO actor FROM users WHERE clerk_user_id=NEW.clerk_user_id;
  track:=NEW.id; kind:='new_track'; key:='publish:'||track;
 ELSIF TG_TABLE_NAME='track_comments' THEN
  actor:=NEW.user_id; track:=NEW.track_id; comment:=NEW.id; kind:='comment'; key:='comment:'||comment;
  SELECT id INTO recipient FROM users WHERE clerk_user_id=(SELECT clerk_user_id FROM private_tracks WHERE id=track);
  IF NEW.parent_id IS NOT NULL THEN SELECT user_id INTO parent_recipient FROM track_comments WHERE id=NEW.parent_id; END IF;
  INSERT INTO social_outbox(event_key,type,actor_id,recipient_id,track_id,comment_id)
   SELECT key,kind,actor,recipient,track,comment WHERE recipient<>actor AND recipient IS DISTINCT FROM parent_recipient ON CONFLICT DO NOTHING;
  IF NEW.parent_id IS NULL THEN RETURN NEW; END IF;
  recipient:=parent_recipient;
  kind:='reply'; key:='reply:'||comment;
 ELSE
  actor:=NEW.user_id; comment:=NEW.comment_id; kind:='comment_like'; key:='comment-like:'||actor||':'||comment;
  SELECT c.user_id,c.track_id INTO recipient,track FROM track_comments c WHERE c.id=comment;
 END IF;
 IF actor IS NOT NULL AND (recipient IS DISTINCT FROM actor) THEN
  INSERT INTO social_outbox(event_key,type,actor_id,recipient_id,track_id,comment_id)
   VALUES(key,kind,actor,recipient,track,comment) ON CONFLICT DO NOTHING;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER follow_event AFTER INSERT ON user_follows FOR EACH ROW EXECUTE FUNCTION capture_social_event();
CREATE TRIGGER song_like_event AFTER INSERT ON track_likes FOR EACH ROW EXECUTE FUNCTION capture_social_event();
CREATE TRIGGER publish_event AFTER INSERT OR UPDATE OF visibility ON private_tracks FOR EACH ROW EXECUTE FUNCTION capture_social_event();
CREATE TRIGGER comment_event AFTER INSERT ON track_comments FOR EACH ROW EXECUTE FUNCTION capture_social_event();
CREATE TRIGGER comment_like_event AFTER INSERT ON comment_likes FOR EACH ROW EXECUTE FUNCTION capture_social_event();
