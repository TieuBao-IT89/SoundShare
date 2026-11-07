# Changelog

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
