import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_controller.dart';
import '../../l10n/l10n.dart';

/// Keeps the existing entry point while exposing direct theme controls.
class ThemeModeMenu extends StatelessWidget {
  const ThemeModeMenu({super.key});
  @override
  Widget build(BuildContext context) {
    final preference = ThemePreferenceScope.maybeOf(context);
    if (preference == null) return const SizedBox.shrink();
    final t = context.l10n;
    final labels = {
      ThemeMode.light: t.themeLight,
      ThemeMode.dark: t.themeDark,
      ThemeMode.system: t.themeSystem,
    };
    final dark = Theme.of(context).brightness == Brightness.dark;
    final automatic = preference.mode == ThemeMode.system;
    Future<void> select(ThemeMode mode) async {
      final saved = await preference.select(mode);
      if (!saved && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.themeSaveFailed)));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '${t.themeAppearance}: ${labels[preference.mode]}',
          excludeFromSemantics: true,
          child: Semantics(
            label: t.themeDarkMode,
            child: Switch(
              key: const ValueKey('theme-dark-switch'),
              value: dark,
              onChanged: (value) =>
                  select(value ? ThemeMode.dark : ThemeMode.light),
              activeTrackColor: context.colors.action,
              activeThumbColor: Colors.white,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: context.colors.surfaceLight,
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.transparent
                    : context.colors.fieldBorder,
              ),
              thumbIcon: WidgetStateProperty.resolveWith(
                (states) => Icon(
                  states.contains(WidgetState.selected)
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  size: 16,
                  color: context.colors.action,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('theme-system-button'),
          tooltip: t.themeSystem,
          isSelected: automatic,
          style: IconButton.styleFrom(
            backgroundColor: automatic
                ? context.colors.selected
                : Colors.transparent,
            foregroundColor: automatic
                ? context.colors.mystic
                : context.colors.secondaryText,
          ),
          onPressed: () => select(
            automatic
                ? (dark ? ThemeMode.dark : ThemeMode.light)
                : ThemeMode.system,
          ),
          icon: const Icon(Icons.brightness_auto_outlined, size: 22),
          selectedIcon: const Icon(Icons.brightness_auto_rounded, size: 22),
        ),
      ],
    );
  }
}
