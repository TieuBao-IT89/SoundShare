import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'core/config/clerk_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const app = ProviderScope(child: SoundShareApp());
  runApp(
    ClerkConfig.isConfigured && !kIsWeb
        ? ClerkAuth(
            config: ClerkAuthConfig(publishableKey: ClerkConfig.publishableKey),
            child: app,
          )
        : app,
  );
}
