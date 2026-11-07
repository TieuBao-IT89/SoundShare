import 'package:flutter_riverpod/flutter_riverpod.dart';

final demoModeProvider = Provider<bool>(
  (ref) => const bool.fromEnvironment('DEMO_MODE'),
);
