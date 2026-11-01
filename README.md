# SoundShare

**Share your music. Enjoy every moment.**

SoundShare is an open source Flutter app concept for discovering, playing, and sharing independent music. This repository is the first UI focused MVP and uses sample content while backend services are prepared.

## Features

- Dark, responsive music experience with splash and bottom navigation
- Home feed, mock recommendations, and searchable sample songs
- Player screen with streaming playback, seek, favorite, shuffle, repeat, and track controls
- MP3 file selection and 20 MB validation on the upload screen
- Library and profile views backed by sample data

## Technology

Flutter and Dart · Riverpod · GoRouter · just_audio · Supabase-ready repositories · PostgreSQL · Supabase Auth and Storage planned

## Screenshots

Screenshots will be added after the first device previews are captured.

## Requirements

- Flutter SDK compatible with Dart `^3.13.3`
- Android Studio with an Android SDK and emulator, or a physical Android device
- Visual Studio Code with the Flutter and Dart extensions

## Run on Windows

1. Install Flutter and Android Studio, then create and start an Android Emulator in Android Studio's Device Manager.
2. Open this folder in VS Code and select the running emulator from the device picker.
3. In the integrated terminal, run:

   ```powershell
   flutter pub get
   flutter run
   ```

Alternatively, run `flutter run -d <device-id>` after checking available targets with `flutter devices`.

## Development

The app is organized by feature under `lib/features`; shared theme, services, and widgets live under `lib/app` and `lib/core`. Run these checks before opening a pull request:

```powershell
dart format .
flutter analyze
flutter test
```

To connect Supabase later, add environment based configuration and implement the repository interfaces. Never commit project keys or service secrets.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the local workflow and pull request guidance. All contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Please report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).

## License

SoundShare is released under the MIT License. See [LICENSE](LICENSE).
