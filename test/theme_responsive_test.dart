import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';

import 'support/test_app.dart';

void main() {
  for (final width in [320.0, 390.0, 430.0, 768.0, 1024.0, 1280.0, 1440.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'All main routes fit $width in ${mode.name} with active player',
        (tester) async {
          final container = await showApp(
            tester,
            '/',
            size: Size(width, 960),
            initialThemeMode: mode,
            textScale: width == 320 || width == 1280 ? 2 : 1,
          );
          container.read(hasSelectedSongProvider.notifier).state = true;
          await tester.pumpAndSettle();
          final router = GoRouter.of(
            tester.element(find.byType(AppScaffold).first),
          );
          for (final route in [
            '/',
            '/explore',
            '/search',
            '/library',
            '/profile',
            '/player',
            '/upload',
          ]) {
            router.go(route);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: route);
            final context = tester.element(find.byType(Scaffold).first);
            expect(context.colors.isDark, mode == ThemeMode.dark);
          }
        },
      );
    }
  }
}
