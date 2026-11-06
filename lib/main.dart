import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'core/config/clerk_config.dart';
import 'l10n/clerk_vi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const app = ProviderScope(child: SoundShareApp());
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
