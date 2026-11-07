import 'package:flutter/material.dart';
import 'package:clerk_flutter/clerk_flutter.dart';

import 'app_palette.dart';
export 'app_palette.dart';

abstract final class AppColors {
  static const background = Color(0xFF080A12);
  static const secondaryBackground = Color(0xFF10121D);
  static const surface = Color(0xFF171A29);
  static const surfaceLight = Color(0xFF23283B);
  static const primary = Color(0xFF8957F7);
  static const action = Color(0xFF6742BF);
  static const mystic = Color(0xFFB9A6F8);
  static const cyan = Color(0xFF57D6DE);
  static const pink = Color(0xFF3D8BEB);
  static const indigo = Color(0xFF6D4DD7);
  static const warning = Color(0xFFF5BA6A);
  static const text = Color(0xFFF7F7FA);
  static const secondaryText = Color(0xFFAAB1C4);
  static const subdued = Color(0xFF8089A3);
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
  static final light = _build(AppPalette.light);
  static final dark = _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.mystic,
      onPrimary: p.isDark ? p.background : Colors.white,
      secondary: p.cyan,
      onSecondary: p.isDark ? p.background : Colors.white,
      tertiary: p.pink,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.secondaryText,
      outline: p.border,
      error: p.error,
      onError: p.isDark ? p.background : Colors.white,
      outlineVariant: p.border,
      surfaceContainerHighest: p.surfaceLight,
      primaryContainer: p.selected,
      onPrimaryContainer: p.text,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      fontFamily: 'BeVietnamPro',
    );
    return base.copyWith(
      extensions: [
        p,
        ClerkThemeExtension(
          colors: ClerkThemeColors(
            background: p.secondaryBackground,
            altBackground: p.surface,
            borderSide: p.border,
            text: p.text,
            icon: p.secondaryText,
            lightweightText: p.secondaryText,
            error: p.error,
            accent: p.mystic,
          ),
        ),
      ],
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: .35),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: p.isDark ? 8 : 3,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.secondaryText,
        textColor: p.text,
        selectedColor: p.mystic,
        selectedTileColor: p.selected,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.mystic,
        unselectedLabelColor: p.secondaryText,
        indicatorColor: p.mystic,
        dividerColor: p.divider,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.mystic,
        linearTrackColor: p.surfaceLight,
      ),
      focusColor: p.primary.withValues(alpha: .16),
      hoverColor: p.primary.withValues(alpha: .05),
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
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
            bodySmall: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: p.secondaryText,
            ),
            labelLarge: const TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          )
          .apply(
            fontFamily: 'BeVietnamPro',
            bodyColor: p.text,
            displayColor: p.text,
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
          backgroundColor: p.action,
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
          foregroundColor: p.text,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: p.accentText,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: .6),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceLight,
        contentTextStyle: TextStyle(fontFamily: 'BeVietnamPro', color: p.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.secondaryBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: .25),
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? p.cyan
                : p.secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'BeVietnamPro',
            color: states.contains(WidgetState.selected)
                ? p.text
                : p.secondaryText,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.isDark ? p.primary.withValues(alpha: .25) : p.selected,
        checkmarkColor: p.cyan,
        labelStyle: TextStyle(
          fontFamily: 'BeVietnamPro',
          color: p.text,
          fontSize: 13,
        ),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.mystic,
        inactiveTrackColor: p.surfaceLight,
        thumbColor: p.cyan,
        trackHeight: 4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: p.text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: TextStyle(color: p.secondaryText, fontSize: 14),
        labelStyle: TextStyle(color: p.secondaryText),
        floatingLabelStyle: TextStyle(color: p.accentText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIconColor: p.secondaryText,
        suffixIconColor: p.secondaryText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.mystic, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.error),
        ),
      ),
    );
  }
}
