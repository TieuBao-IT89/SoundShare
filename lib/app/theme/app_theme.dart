import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF080A12);
  static const secondaryBackground = Color(0xFF0F1220);
  static const surface = Color(0xFF181C2C);
  static const surfaceLight = Color(0xFF23283B);
  static const primary = Color(0xFF8B5CF6);
  static const action = Color(0xFF6742BF);
  static const mystic = Color(0xFFB9A6F8);
  static const cyan = Color(0xFF67E8F9);
  static const pink = Color(0xFF38BDF8);
  static const indigo = Color(0xFF4F46E5);
  static const warning = Color(0xFFF5BA6A);
  static const text = Color(0xFFF8FAFC);
  static const secondaryText = Color(0xFFA8B0C4);
  static const subdued = Color(0xFF737D95);
  static const success = Color(0xFF40CF9A);
  static const error = Color(0xFFF47187);
  static const border = Color(0xFF2B2E3D);
  static const violet = mystic;
  static const mint = cyan;
  static const muted = secondaryText;
}

abstract final class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.indigo, AppColors.cyan],
  );
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.background,
      Color(0xFF0E1019),
      AppColors.secondaryBackground,
    ],
  );
  // Darker stops preserve contrast behind white action labels.
  static const button = LinearGradient(
    colors: [Color(0xFF6742BF), Color(0xFF6140B7), AppColors.indigo],
  );
  static const soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF222133), Color(0xFF171B29), Color(0xFF182733)],
  );
}

abstract final class AppSpacing {
  static const xs = 4.0,
      sm = 8.0,
      md = 12.0,
      lg = 16.0,
      xl = 20.0,
      xxl = 24.0,
      section = 32.0,
      page = 48.0;
}

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.mystic,
      onPrimary: Colors.white,
      secondary: AppColors.cyan,
      onSecondary: AppColors.background,
      tertiary: AppColors.pink,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      onSurfaceVariant: AppColors.secondaryText,
      outline: AppColors.border,
      error: AppColors.error,
      onError: AppColors.background,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: 'BeVietnamPro',
    );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      visualDensity: VisualDensity.standard,
      textTheme: base.textTheme
          .copyWith(
            displaySmall: const TextStyle(
              fontSize: 32,
              height: 1.25,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
            headlineMedium: const TextStyle(
              fontSize: 28,
              height: 1.3,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
            headlineSmall: const TextStyle(
              fontSize: 24,
              height: 1.35,
              fontWeight: FontWeight.w700,
              letterSpacing: -.4,
            ),
            titleLarge: const TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: const TextStyle(fontSize: 16, height: 1.6),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.6),
            bodySmall: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.secondaryText,
            ),
            labelLarge: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(
            fontFamily: 'BeVietnamPro',
            bodyColor: AppColors.text,
            displayColor: AppColors.text,
          ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: AppColors.action,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.cyan,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: .6,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          color: AppColors.text,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: .25),
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.cyan
                : AppColors.secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'BeVietnamPro',
            color: states.contains(WidgetState.selected)
                ? AppColors.text
                : AppColors.secondaryText,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: .25),
        checkmarkColor: AppColors.cyan,
        labelStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          color: AppColors.text,
          fontSize: 13,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.mystic,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.cyan,
        trackHeight: 4,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
        floatingLabelStyle: const TextStyle(color: AppColors.cyan),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIconColor: AppColors.secondaryText,
        suffixIconColor: AppColors.secondaryText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.mystic, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
