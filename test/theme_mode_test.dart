import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/app/theme/theme_controller.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';
import 'package:soundshare/core/widgets/theme_mode_menu.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

class MemoryThemeStore implements ThemePreferenceStore {
  String? value;
  bool fail = false;
  final writes = <String>[];
  Future<void> Function(String)? beforeWrite;
  @override
  Future<String?> read() async {
    if (fail) throw StateError('private storage error');
    return value;
  }

  @override
  Future<void> write(String value) async {
    await beforeWrite?.call(value);
    if (fail) throw StateError('private storage error');
    this.value = value;
    writes.add(value);
  }
}

double contrast(Color first, Color second) {
  final a = first.computeLuminance(), b = second.computeLuminance();
  return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
}

void main() {
  test(
    'Device mode restores after a new controller and fails safely',
    () async {
      final store = MemoryThemeStore();
      expect(await restoreThemeMode(store), ThemeMode.light);
      final controller = ThemeModeController(ThemeMode.light, store);
      for (final mode in [ThemeMode.dark, ThemeMode.system, ThemeMode.light]) {
        expect(await controller.select(mode), isTrue);
        final restarted = ThemeModeController(
          await restoreThemeMode(store),
          store,
        );
        expect(restarted.state, mode);
        restarted.dispose();
      }
      store.value = 'unexpected';
      expect(await restoreThemeMode(store), ThemeMode.light);
      store.fail = true;
      expect(await restoreThemeMode(store), ThemeMode.light);
      expect(await controller.select(ThemeMode.dark), isFalse);
      expect(controller.state, ThemeMode.dark);
      controller.dispose();
    },
  );

  test(
    'Rapid selections persist in order even with a slow first write',
    () async {
      final gate = Completer<void>(), store = MemoryThemeStore();
      store.beforeWrite = (mode) async {
        if (mode == 'dark') await gate.future;
      };
      final controller = ThemeModeController(ThemeMode.light, store);
      final first = controller.select(ThemeMode.dark);
      final last = controller.select(ThemeMode.system);
      expect(controller.state, ThemeMode.system);
      gate.complete();
      expect(await first, isTrue);
      expect(await last, isTrue);
      expect(store.writes, ['dark', 'system']);
      expect(await restoreThemeMode(store), ThemeMode.system);
      controller.dispose();
    },
  );

  test('Actual Pearl text, semantic labels and action stops meet AA', () {
    const p = AppPalette.light;
    final surfaces = [
      p.background,
      p.surface,
      p.surfaceLight,
      p.selected,
      ...p.featuredGradient.colors,
      ...p.ambientGradient.colors,
    ];
    for (final background in surfaces) {
      for (final foreground in [
        p.text,
        p.secondaryText,
        p.mystic,
        p.accentText,
      ]) {
        expect(
          contrast(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: '$foreground on $background',
        );
      }
    }
    for (final color in [p.action, ...p.buttonGradient.colors]) {
      expect(contrast(Colors.white, color), greaterThanOrEqualTo(4.5));
    }
    for (final color in [p.success, p.warning, p.error, p.subdued]) {
      expect(contrast(color, p.surface), greaterThanOrEqualTo(4.5));
    }
    expect(contrast(p.fieldBorder, p.surface), greaterThanOrEqualTo(3));
  });

  testWidgets(
    'Switching retains route, search input, queue, audio and position; system follows OS',
    (tester) async {
      final audio = _PositionedPlayer();
      final store = MemoryThemeStore();
      final container = await showApp(
        tester,
        '/search',
        player: audio,
        themeStore: store,
        size: const Size(1280, 900),
      );
      await tester.pumpAndSettle();
      final field = find.byType(TextField).first;
      await tester.enterText(field, 'Blue');
      await tester.pumpAndSettle();
      await container.read(playbackActionsProvider).playFrom(sampleSongs, 0);
      await tester.pumpAndSettle();
      final queue = container.read(playbackQueueProvider);
      expect(queue, isNotEmpty);
      final song = container.read(currentSongProvider);
      final element = tester.element(find.byType(AppScaffold).first);
      final router = GoRouter.of(element);
      final routeBefore = router.routeInformationProvider.value.uri;
      for (final mode in [ThemeMode.dark, ThemeMode.light, ThemeMode.system]) {
        if (mode == ThemeMode.system) {
          await tester.tap(find.byKey(const ValueKey('theme-system-button')));
        } else {
          await tester.tap(find.byKey(const ValueKey('theme-dark-switch')));
        }
        await tester.pumpAndSettle();
        expect(container.read(themeModeProvider), mode);
        expect(router.routeInformationProvider.value.uri, routeBefore);
        expect(find.text('Blue'), findsWidgets);
        expect(container.read(currentSongProvider), song);
        expect(container.read(playbackQueueProvider), queue);
        expect(identical(container.read(audioPlayerProvider), audio), isTrue);
        expect(audio.position, const Duration(seconds: 65));
        expect(audio.active, isTrue);
        expect(audio.loads, 1);
      }
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      expect(Theme.of(element).brightness, Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(Theme.of(element).brightness, Brightness.light);
      expect(
        tester
            .widget<Switch>(find.byKey(const ValueKey('theme-dark-switch')))
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('theme-system-button')));
      await tester.pumpAndSettle();
      expect(container.read(themeModeProvider), ThemeMode.light);
      await tester.tap(find.byKey(const ValueKey('theme-system-button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(store.value, 'system');
    },
  );

  testWidgets(
    'Switch crosses an isolated session container and preserves entered input',
    (tester) async {
      final store = MemoryThemeStore();
      final root = ThemeModeController(ThemeMode.light, store);
      final sessionContainer = ProviderContainer();
      addTearDown(root.dispose);
      addTearDown(sessionContainer.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: ThemePreferenceScope(
            mode: root.state,
            select: root.select,
            child: UncontrolledProviderScope(
              container: sessionContainer,
              child: const Scaffold(
                body: Column(children: [ThemeModeMenu(), TextField()]),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '@creator');
      await tester.tap(find.byKey(const ValueKey('theme-dark-switch')));
      await tester.pumpAndSettle();
      expect(root.state, ThemeMode.dark);
      expect(store.value, 'dark');
      expect(find.text('@creator'), findsOneWidget);
      expect(sessionContainer.read(themeModeProvider), ThemeMode.light);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PositionedPlayer extends TestPlayer {
  @override
  Duration get position => const Duration(seconds: 65);
}
