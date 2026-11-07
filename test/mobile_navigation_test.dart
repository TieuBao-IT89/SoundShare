import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/upload/presentation/upload_screen.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

Future<void> captureMenu(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  RenderObject? boundary = tester.renderObject(find.byType(AppScaffold).first);
  while (boundary != null && boundary is! RenderRepaintBoundary) {
    boundary = boundary.parent;
  }
  await tester.runAsync(() async {
    final image = await (boundary! as RenderRepaintBoundary).toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.local/ui/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final (size, scale, mode) in [
    (const Size(320, 568), 2.0, ThemeMode.dark),
    (const Size(390, 844), 1.0, ThemeMode.light),
    (const Size(640, 360), 2.0, ThemeMode.dark),
  ]) {
    testWidgets(
      'Every menu destination stays reachable at $size, text $scale',
      (tester) async {
        final player = TestPlayer();
        final container = await showApp(
          tester,
          '/library',
          player: player,
          size: size,
          textScale: scale,
          initialThemeMode: mode,
          repository: TestRepository(
            () async => const [
              Song(
                title: 'Bản thu thử',
                artist: 'Người sáng tạo mẫu',
                artwork: '',
                duration: '3:00',
                audioUrl: 'https://example.invalid/audio.mp3',
              ),
            ],
          ),
        );
        await container.read(playbackActionsProvider).play(0);
        await container.read(playbackActionsProvider).pause();
        await pumpPlaybackUi(tester);
        final song = container.read(currentSongIndexProvider);
        final source = player.source;
        await captureMenu(tester, 'mobile-menu-entry-${size.width.toInt()}');
        await tester.tap(find.byKey(const ValueKey('mobile-navigation-menu')));
        await pumpPlaybackUi(tester);
        final drawer = find.byKey(const ValueKey('mobile-navigation-drawer'));
        final scrollable = find.descendant(
          of: drawer,
          matching: find.byType(Scrollable),
        );
        await captureMenu(tester, 'mobile-menu-${size.width.toInt()}');
        for (final label in [
          appCopy.home,
          appCopy.explore,
          appCopy.search,
          appCopy.library,
          appCopy.profile,
          appCopy.v9Shorts,
          appCopy.v9Notifications,
          appCopy.likedTracks,
          appCopy.v3Playlists,
          appCopy.uploadMusic,
        ]) {
          final target = find.descendant(
            of: drawer,
            matching: find.text(label),
          );
          await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
          await tester.ensureVisible(target);
          await pumpPlaybackUi(tester);
          expect(target.hitTestable(), findsOneWidget, reason: label);
          expect(tester.takeException(), isNull, reason: label);
        }
        await captureMenu(tester, 'mobile-menu-bottom-${size.width.toInt()}');
        await tester.tap(
          find.descendant(of: drawer, matching: find.text(appCopy.uploadMusic)),
        );
        await pumpPlaybackUi(tester);
        expect(find.byType(UploadScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('mobile-navigation-drawer')),
          findsNothing,
        );
        expect(container.read(currentSongIndexProvider), song);
        expect(player.source, same(source));
        expect(player.loads, 1);
        expect(player.active, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Menu closes on a tab selection, reopens and closes with back', (
    tester,
  ) async {
    await showApp(tester, '/');
    await tester.tap(find.byKey(const ValueKey('mobile-navigation-menu')));
    await pumpPlaybackUi(tester);
    final drawer = find.byKey(const ValueKey('mobile-navigation-drawer'));
    await tester.tap(
      find.descendant(of: drawer, matching: find.text(appCopy.search)),
    );
    await pumpPlaybackUi(tester);
    expect(find.byType(SoundShareBottomNavigation), findsOneWidget);
    expect(drawer, findsNothing);
    final router = GoRouter.of(tester.element(find.byType(AppScaffold).first));
    expect(router.routeInformationProvider.value.uri.path, '/search');
    await tester.tap(find.byKey(const ValueKey('mobile-navigation-menu')));
    await pumpPlaybackUi(tester);
    await tester.binding.handlePopRoute();
    await pumpPlaybackUi(tester);
    expect(drawer, findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/search');
    expect(tester.takeException(), isNull);
  });
}
