import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'app/theme/theme_controller.dart';
import 'core/config/clerk_config.dart';
import 'l10n/clerk_vi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = DeviceThemePreferenceStore();
  final mode = await restoreThemeMode(preferences);
  final app = ProviderScope(
    overrides: [
      initialThemeModeProvider.overrideWithValue(mode),
      themePreferenceStoreProvider.overrideWithValue(preferences),
    ],
    child: const SoundShareApp(),
  );
  final vietnamese = SoundShareClerkLocalizationsVi();
  runApp(
    ClerkConfig.isConfigured && !kIsWeb
        ? ClerkAuth(
            config: ClerkAuthConfig(
              publishableKey: ClerkConfig.publishableKey,
              localizations: {'vi': vietnamese},
              fallbackLocalization: vietnamese,
            ),
            child: app,
          )
        : app,
  );
}
