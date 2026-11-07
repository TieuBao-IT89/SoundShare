import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themePreferenceKey = 'soundshare.themeMode';

ThemeMode parseThemeMode(String? value) => switch (value) {
  'dark' => ThemeMode.dark,
  'system' => ThemeMode.system,
  _ => ThemeMode.light,
};

abstract interface class ThemePreferenceStore {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceThemePreferenceStore implements ThemePreferenceStore {
  late final _preferences = SharedPreferencesAsync();
  @override
  Future<String?> read() => _preferences.getString(themePreferenceKey);
  @override
  Future<void> write(String value) =>
      _preferences.setString(themePreferenceKey, value);
}

Future<ThemeMode> restoreThemeMode(ThemePreferenceStore store) async {
  try {
    return parseThemeMode(
      await store.read().timeout(const Duration(seconds: 2)),
    );
  } catch (_) {
    return ThemeMode.light;
  }
}

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);
final themePreferenceStoreProvider = Provider<ThemePreferenceStore>(
  (ref) => DeviceThemePreferenceStore(),
);
final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(
    ref.watch(initialThemeModeProvider),
    ref.watch(themePreferenceStoreProvider),
  ),
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(super.state, this.store);
  final ThemePreferenceStore store;
  Future<void> _pending = Future.value();

  Future<bool> select(ThemeMode mode) {
    state = mode;
    // Serialize writes so rapid choices cannot restore an older mode at restart.
    final result = _pending
        .then((_) => store.write(mode.name))
        .then((_) => true, onError: (Object _) => false);
    _pending = result.then((_) {});
    return result;
  }
}

/// This scope also crosses SessionScope's isolated provider container. It keeps
/// the preference on the device while session-owned audio/data keep their lifecycle.
class ThemePreferenceScope extends InheritedWidget {
  const ThemePreferenceScope({
    super.key,
    required this.mode,
    required this.select,
    required super.child,
  });
  final ThemeMode mode;
  final Future<bool> Function(ThemeMode) select;
  static ThemePreferenceScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemePreferenceScope>();
  @override
  bool updateShouldNotify(ThemePreferenceScope oldWidget) =>
      mode != oldWidget.mode;
}
