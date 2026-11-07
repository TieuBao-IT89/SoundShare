import 'package:flutter/material.dart';

/// Semantic colors and gradients travel with ThemeData, including overlays.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.secondaryBackground,
    required this.surface,
    required this.surfaceLight,
    required this.primary,
    required this.action,
    required this.mystic,
    required this.cyan,
    required this.pink,
    required this.indigo,
    required this.warning,
    required this.text,
    required this.secondaryText,
    required this.subdued,
    required this.success,
    required this.error,
    required this.border,
    required this.divider,
    required this.selected,
    required this.fieldBorder,
  });

  final Brightness brightness;
  final Color background;
  final Color secondaryBackground;
  final Color surface;
  final Color surfaceLight;
  final Color primary;
  final Color action;
  final Color mystic;
  final Color cyan;
  final Color pink;
  final Color indigo;
  final Color warning;
  final Color text;
  final Color secondaryText;
  final Color subdued;
  final Color success;
  final Color error;
  final Color border;
  final Color divider;
  final Color selected;
  final Color fieldBorder;
  bool get isDark => brightness == Brightness.dark;
  Color get violet => mystic;
  Color get mint => cyan;
  Color get muted => secondaryText;
  // Cyan remains the brand swatch; small text on pastel surfaces needs deeper ink.
  Color get accentText => isDark ? cyan : const Color(0xFF006D80);
  Color get shadow => isDark
      ? Colors.black.withValues(alpha: .16)
      : const Color(0xFF26385A).withValues(alpha: .07);
  Color get onAction => Colors.white;

  static const light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF7F8FC),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF0F2FA),
    primary: Color(0xFF633BC9),
    action: Color(0xFF633BC9),
    mystic: Color(0xFF633BC9),
    cyan: Color(0xFF007E91),
    pink: Color(0xFF3D8BEB),
    indigo: Color(0xFF5A32BA),
    warning: Color(0xFF986000),
    text: Color(0xFF172033),
    secondaryText: Color(0xFF526078),
    subdued: Color(0xFF65718B),
    success: Color(0xFF18794E),
    error: Color(0xFFB42342),
    border: Color(0xFFE4E6F2),
    divider: Color(0xFFEDF0F6),
    selected: Color(0xFFEFEAFF),
    fieldBorder: Color(0xFF848CA3),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF080A12),
    secondaryBackground: Color(0xFF10121D),
    surface: Color(0xFF171A29),
    surfaceLight: Color(0xFF23283B),
    primary: Color(0xFF8957F7),
    action: Color(0xFF6742BF),
    mystic: Color(0xFFB9A6F8),
    cyan: Color(0xFF57D6DE),
    pink: Color(0xFF3D8BEB),
    indigo: Color(0xFF6D4DD7),
    warning: Color(0xFFF5BA6A),
    text: Color(0xFFF7F7FA),
    secondaryText: Color(0xFFAAB1C4),
    subdued: Color(0xFF8089A3),
    success: Color(0xFF40CF9A),
    error: Color(0xFFF47187),
    border: Color(0xFF2B2E3D),
    divider: Color(0xFF2B2E3D),
    selected: Color(0xFF23283B),
    fieldBorder: Color(0xFF8089A3),
  );

  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      isDark ? indigo : const Color(0xFF7C5DE0),
      isDark ? cyan : pink,
    ],
  );
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? [background, const Color(0xFF0E1019), secondaryBackground]
        : [background, background],
  );
  // Every stop supports white labels at WCAG AA.
  LinearGradient get buttonGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFF6742BF), Color(0xFF6140B7), Color(0xFF6D4DD7)]
        : const [Color(0xFF633BC9), Color(0xFF5A32BA), Color(0xFF5141AE)],
  );
  LinearGradient get featuredGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? const [Color(0xFF222133), Color(0xFF171B29), Color(0xFF182733)]
        : const [Color(0xFFEEE4FF), Color(0xFFDDEBFF), Color(0xFFD4F5F4)],
  );
  LinearGradient get ambientGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: isDark
        ? [background, secondaryBackground]
        : const [Color(0xFFFFFFFF), Color(0xFFF7F4FF), Color(0xFFEDF8FF)],
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? secondaryBackground,
    Color? surface,
    Color? surfaceLight,
    Color? primary,
    Color? action,
    Color? mystic,
    Color? cyan,
    Color? pink,
    Color? indigo,
    Color? warning,
    Color? text,
    Color? secondaryText,
    Color? subdued,
    Color? success,
    Color? error,
    Color? border,
    Color? divider,
    Color? selected,
    Color? fieldBorder,
  }) => AppPalette(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    secondaryBackground: secondaryBackground ?? this.secondaryBackground,
    surface: surface ?? this.surface,
    surfaceLight: surfaceLight ?? this.surfaceLight,
    primary: primary ?? this.primary,
    action: action ?? this.action,
    mystic: mystic ?? this.mystic,
    cyan: cyan ?? this.cyan,
    pink: pink ?? this.pink,
    indigo: indigo ?? this.indigo,
    warning: warning ?? this.warning,
    text: text ?? this.text,
    secondaryText: secondaryText ?? this.secondaryText,
    subdued: subdued ?? this.subdued,
    success: success ?? this.success,
    error: error ?? this.error,
    border: border ?? this.border,
    divider: divider ?? this.divider,
    selected: selected ?? this.selected,
    fieldBorder: fieldBorder ?? this.fieldBorder,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      brightness: t < .5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      secondaryBackground: Color.lerp(
        secondaryBackground,
        other.secondaryBackground,
        t,
      )!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      action: Color.lerp(action, other.action, t)!,
      mystic: Color.lerp(mystic, other.mystic, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      pink: Color.lerp(pink, other.pink, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      subdued: Color.lerp(subdued, other.subdued, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
    );
  }
}

extension SoundShareThemeContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
