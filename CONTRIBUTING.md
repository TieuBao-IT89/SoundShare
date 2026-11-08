# Contributing to SoundShare

Contributions to code, documentation, accessibility, and translations are welcome. For a substantial feature or API change, open an issue first to discuss scope. Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Development workflow

1. Fork the repository and create a focused branch from `develop`.
2. Follow the setup in [README.md](README.md#getting-started). Use your own development services or demo mode.
3. Read [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](ARCHITECTURE.md), [DESIGN.md](DESIGN.md), and the relevant [API contract](PRD.md) before changing behavior.
4. Add or update meaningful tests for behavior changes. Keep shared fixtures small, synthetic, and free of copyrighted music or personal data.
5. Open a pull request against `develop` explaining the problem, resulting behavior, and validation. Include screenshots for visual changes and migration notes for schema changes.

`main` contains releases. Changes normally land on `develop` before a release PR promotes them to `main`.

## Checks

Format the Dart files you change, then run the appropriate checks:

```sh
dart format lib test
flutter analyze
flutter test
npm --prefix backend ci
npm --prefix backend test
node --test test/web/*.cjs
```

Backend tests use isolated databases and mocked external providers. The optional TCP PostgreSQL test requires a separate `TEST_DATABASE_URL`; never use a production database. Do not run provider smoke checks unless you have intentionally configured the target development environment.

If changing copy in `lib/l10n/app_vi.arb`, regenerate localization with `flutter gen-l10n`. Include versioned migrations and update `PRD.md` for API/schema changes; update `DESIGN.md` when a UI flow changes.

## Security and repository hygiene

- Keep Neon, Clerk, and Cloudinary secrets in backend environment variables. Only public client settings belong in Flutter builds.
- Never commit `.env`, tokens, connection strings, real user data, generated builds, raw logs, or browser profiles.
- Keep temporary screenshots and review output in ignored `build/` or `.local/`. Publish only selected, sanitized documentation images under `docs/images/`.
- Keep operational scripts separate from tests; preserve regression coverage when removing obsolete development tools.
- Report vulnerabilities privately through the process in [SECURITY.md](SECURITY.md).

Historical QA reports and one-off generators are available through [the development archive](docs/archive.md); they are not part of the current setup workflow.
