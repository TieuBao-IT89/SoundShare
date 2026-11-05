import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0D0D12);
  static const surface = Color(0xFF17171F);
  static const surfaceLight = Color(0xFF22222D);
  static const violet = Color(0xFF9B7BFF);
  static const mint = Color(0xFFB8F28B);
  static const muted = Color(0xFF92919E);
  static const error = Color(0xFFFF9A9A);
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.violet,
      onPrimary: Color(0xFF171220),
      secondary: AppColors.mint,
      onSecondary: Color(0xFF17210F),
      surface: AppColors.surface,
      onSurface: Color(0xFFF5F3FA),
      onSurfaceVariant: AppColors.muted,
      error: AppColors.error,
      onError: Color(0xFF2A1010),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          foregroundColor: AppColors.violet,
          side: const BorderSide(color: AppColors.surfaceLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.violet,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.violet.withValues(alpha: 0.2),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.violet
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.violet : AppColors.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.violet.withValues(alpha: 0.2),
        checkmarkColor: AppColors.violet,
        labelStyle: const TextStyle(color: Color(0xFFF5F3FA)),
        side: const BorderSide(color: AppColors.surfaceLight),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.violet,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.violet,
        overlayColor: AppColors.violet.withValues(alpha: 0.16),
        trackHeight: 3,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
        ),
      ),
    );
  }
}
