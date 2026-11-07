import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/features/community/presentation/music_components.dart';
import 'package:soundshare/features/home/domain/song.dart';

final songs = List.generate(
  3,
  (i) => Song(
    id: 'featured-$i',
    title: 'Bản thu $i',
    artist: 'Nghệ sĩ mẫu',
    artwork: '',
    duration: '3:00',
  ),
);

Future<void> showFeatured(
  WidgetTester tester, {
  List<Song>? items,
  bool reduced = false,
  bool accessible = false,
  bool visible = true,
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: dark ? AppTheme.dark : ThemeData.light(),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduced,
            accessibleNavigation: accessible,
          ),
          child: TickerMode(
            enabled: visible,
            child: Scaffold(body: FeaturedMusic(songs: items ?? songs)),
          ),
        ),
      ),
    ),
  );
}

int currentPage(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!.page!.round();

Future<void> advanceSlide(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  for (final dark in [false, true]) {
    testWidgets('Featured cycles every five seconds in dark=$dark', (
      tester,
    ) async {
      await showFeatured(tester, dark: dark);
      await tester.pump(const Duration(seconds: 4));
      expect(currentPage(tester), 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(currentPage(tester), 1);
      await advanceSlide(tester);
      expect(currentPage(tester), 2);
      await advanceSlide(tester);
      expect(currentPage(tester), 0);
    });
  }

  testWidgets('Swipe and dot selection restart the interval', (tester) async {
    await showFeatured(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.drag(find.byType(PageView), const Offset(-650, 0));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 1);
    await tester.pump(const Duration(seconds: 2));
    expect(currentPage(tester), 1);
    await tester.tap(find.byTooltip('Nội dung nổi bật 3/3'));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 2);
    await tester.pump(const Duration(seconds: 4));
    expect(currentPage(tester), 2);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 0);
  });

  testWidgets('Holding a pointer and hovering pause automatic slides', (
    tester,
  ) async {
    await showFeatured(tester);
    final pointer = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(currentPage(tester), 0);
    await pointer.up();
    await advanceSlide(tester);
    expect(currentPage(tester), 1);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(790, 590));
    await mouse.moveTo(tester.getCenter(find.byType(PageView)));
    await tester.pump(const Duration(seconds: 10));
    expect(currentPage(tester), 1);
    await mouse.removePointer();
    await advanceSlide(tester);
    expect(currentPage(tester), 2);
  });

  testWidgets('Keyboard focus pauses slides until it leaves the banner', (
    tester,
  ) async {
    await showFeatured(tester);
    Focus.of(tester.element(find.byTooltip('Nội dung nổi bật 2/3')))
        .requestFocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(currentPage(tester), 0);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await advanceSlide(tester);
    expect(currentPage(tester), 1);
  });

  testWidgets(
    'Background and inactive tabs pause and restart a full interval',
    (tester) async {
      await showFeatured(tester);
      await tester.pump(const Duration(seconds: 4));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(currentPage(tester), 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 4));
      expect(currentPage(tester), 0);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(currentPage(tester), 1);

      await showFeatured(tester, visible: false);
      await tester.pump(const Duration(seconds: 10));
      expect(currentPage(tester), 1);
      await showFeatured(tester);
      await advanceSlide(tester);
      expect(currentPage(tester), 2);
    },
  );

  for (final accessible in [false, true]) {
    testWidgets('Accessibility preference stops auto slides: $accessible', (
      tester,
    ) async {
      await showFeatured(tester, reduced: !accessible, accessible: accessible);
      await tester.pump(const Duration(seconds: 15));
      expect(currentPage(tester), 0);
      await tester.tap(find.byTooltip('Nội dung nổi bật 2/3'));
      await tester.pumpAndSettle();
      expect(currentPage(tester), 1);
      await showFeatured(tester);
      await advanceSlide(tester);
      expect(currentPage(tester), 2);
    });
  }

  testWidgets('Shrinking, empty, and single-item lists remain safe', (
    tester,
  ) async {
    await showFeatured(tester);
    await advanceSlide(tester);
    await advanceSlide(tester);
    await showFeatured(tester, items: songs.take(1).toList());
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(currentPage(tester), 0);
    expect(find.byType(IconButton), findsNothing);
    await showFeatured(tester, items: []);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(PageView), findsNothing);
    await showFeatured(tester);
    await advanceSlide(tester);
    expect(currentPage(tester), 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });
}
