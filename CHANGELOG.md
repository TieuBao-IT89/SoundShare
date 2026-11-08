# Changelog

## 1.2.0 - 2026-11-08

### Added

- Timestamped LRC uploads and owner editing, synchronized line highlighting, tap-to-seek, and fullscreen lyrics using the existing player.
- Music Shorts, comments/replies, likes, and an in-app notification inbox with durable outbox delivery and preferences.
- Android background audio and MediaSession integration in source, with a shared playback engine and lifecycle-aware UI updates.
- Full mobile navigation drawer and a simpler text-only Web sign-in button.
- Combined Flutter Web/Express Docker deployment for Render and an optional production-only 14-minute health ping with timeout, overlap protection, and safe logs.

### Changed

- Rewrite the README around features, selected screenshots, setup, architecture, testing, and contribution guidance.
- Refresh architecture, contribution, and security documentation to match the current Clerk/Express/Neon/Cloudinary stack.
- Keep four documentation screenshots and archive historical QA reports, screenshots, completed task notes, and one-off review scripts in Git history. Preserve the official automated test suites and operational tools.
- Set the Flutter application version to `1.2.0+3` and align the Render Blueprint with `develop`.

Upgrading from v1.1.0 requires migrations **006–007** before starting the new backend. Startup only checks the schema; releases do not migrate or deploy automatically. Self-ping cannot wake a suspended process. Native background playback and Safari iPhone behavior still need device acceptance checks; no signed native binaries are included in this release.

## 1.1.0 - 2026-11-08

- Add Aurora Pearl light mode alongside Obsidian Pulse dark mode, with saved appearance preferences and system theme support across Flutter and Web authentication.
- Refresh search with a shared accessible field, clear action, responsive layouts, and existing API-backed discovery.
- Auto-slide featured music every five seconds, respecting interaction, visibility, lifecycle, and reduced motion.
- Upgrade Now Playing with a layered vinyl surface, larger cover label, animated tonearm, artwork-derived ambient colors, double-tap favorites, and swipe navigation.
- Add a mobile queue sheet with drag reordering, play-now/add/remove actions, and a cancellable 15/30/60-minute sleep timer using the existing audio player.
- Preserve playback and record phase across responsive layout changes; fix queue completion after pause/resume and prevent late playback after a sleep deadline.
- Include the development branch's private music library, creator profiles, discovery, playlists, personalized recommendations, and Clerk/Express/Neon/Cloudinary integrations in the main release.
- Lyrics synchronization remains unavailable until the API supplies real lyrics and timestamps. Native device performance, background audio, and sleep behavior while the OS suspends the app still require device testing.

Upgrade from the initial main branch requires backend configuration and the versioned migrations through `005_recommendation_indexes.sql`. Follow `README.md` and `docs/personalized-recommendations.md`; publishing this release does not execute migrations or deploy services.

## 0.1.0 - 2026-10-31

- Replace the Flutter counter template with the SoundShare MVP foundation.
- Add splash, home, explore, player, upload, library, and profile screens.
- Add sample tracks and streaming playback UI.
- Add initial open source project documentation.
