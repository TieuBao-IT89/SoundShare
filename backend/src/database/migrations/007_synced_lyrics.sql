-- Bounded lyric text and timing metadata, never audio/artwork bytes or URLs.
-- Retain a revision tombstone on removal to prevent stale editor overwrites.
CREATE TABLE track_lyrics (
    track_id UUID PRIMARY KEY REFERENCES private_tracks(id) ON DELETE CASCADE,
    lrc TEXT CHECK (lrc IS NULL OR octet_length(lrc) BETWEEN 1 AND 65536),
    revision INTEGER NOT NULL DEFAULT 1 CHECK (revision > 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
