import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/app/theme/theme_controller.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';
import 'package:soundshare/core/widgets/soundshare_search_field.dart';
import 'package:soundshare/features/community/application/community_providers.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'community_test.dart' show CommunityFixture, showCommunity;

const captureReview = bool.fromEnvironment('CAPTURE_SEARCH_REVIEW');

Future<void> capture(WidgetTester tester, String name) async {
  if (!captureReview) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/search-review/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> searchShortcut(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    if (!captureReview) return;
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('Clear reacts to typing and controller updates and keeps focus', (
    tester,
  ) async {
    final controller = TextEditingController();
    final changes = <String>[];
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SoundShareSearchField(
            controller: controller,
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Bản thu');
    await tester.pumpAndSettle();
    expect(find.byTooltip(appCopy.clearSearch), findsOneWidget);
    await tester.tap(find.byTooltip(appCopy.clearSearch));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(changes.last, '');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    controller.text = '@nghesi';
    await tester.pumpAndSettle();
    expect(find.byTooltip(appCopy.clearSearch), findsOneWidget);
    controller.clear();
    await tester.pumpAndSettle();
    expect(find.byTooltip(appCopy.clearSearch), findsNothing);
  });

  testWidgets(
    'Enter flushes debounce and remembers the current input exactly once',
    (tester) async {
      final fixture = CommunityFixture();
      final container = await showCommunity(
        tester,
        '/search',
        fixture: fixture,
      );
      await tester.enterText(find.byType(TextField), '  @TQD  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final searches = fixture.requests
          .where((r) => r.url.path.endsWith('/community/search'))
          .toList();
      expect(searches, hasLength(1));
      expect(searches.single.url.queryParameters['q'], '@TQD');
      expect(container.read(recentCommunitySearchesProvider), ['@TQD']);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/community/search')),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'Recent chips replay the query and can be cleared for the session',
    (tester) async {
      final container = await showCommunity(tester, '/search');
      container.read(recentCommunitySearchesProvider.notifier).state = [
        '@tqd.music',
        'Bản thu',
      ];
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(InputChip, '@tqd.music'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '@tqd.music',
      );
      await tester.tap(find.byTooltip(appCopy.clearSearch));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextButton, appCopy.clearSearchHistory),
      );
      await tester.pumpAndSettle();
      expect(container.read(recentCommunitySearchesProvider), isEmpty);
      expect(find.byType(InputChip), findsNothing);
    },
  );

  testWidgets(
    'Desktop shortcut focuses only the visible field across tabs; Escape releases it',
    (tester) async {
      await showCommunity(tester, '/search', size: const Size(1280, 900));
      expect(find.byType(TextField), findsOneWidget);
      await searchShortcut(tester, LogicalKeyboardKey.controlLeft);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
      final router = GoRouter.of(
        tester.element(find.byType(AppScaffold).first),
      );
      router.go('/profile');
      await tester.pumpAndSettle();
      await searchShortcut(tester, LogicalKeyboardKey.metaLeft);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.byKey(const ValueKey('global-search')), findsOneWidget);
    },
  );

  testWidgets(
    'Deep link replaces a pending query without the old debounce overwriting it',
    (tester) async {
      final fixture = CommunityFixture();
      await showCommunity(tester, '/search', fixture: fixture);
      await tester.enterText(find.byType(TextField), 'stale');
      final router = GoRouter.of(
        tester.element(find.byType(AppScaffold).first),
      );
      router.go('/search?q=%40tqd.music');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '@tqd.music',
      );
      expect(
        fixture.requests
            .where((r) => r.url.path.endsWith('/community/search'))
            .every((r) => r.url.queryParameters['q'] == '@tqd.music'),
        isTrue,
      );
    },
  );

  testWidgets('Shortcut brings the search back after scrolling away', (
    tester,
  ) async {
    await showCommunity(tester, '/search', size: const Size(390, 640));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1600));
    await tester.pumpAndSettle();
    await searchShortcut(tester, LogicalKeyboardKey.controlLeft);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    final field = tester.getRect(find.byType(TextField));
    expect(field.top, greaterThanOrEqualTo(0));
    expect(field.bottom, lessThan(640));
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'Search fits $width ${mode.name} including large text and keyboard',
        (tester) async {
          final container = await showCommunity(
            tester,
            '/search',
            size: Size(width, 900),
            scale: width == 320 ? 2 : 1,
          );
          await container.read(themeModeProvider.notifier).select(mode);
          await tester.pumpAndSettle();
          container.read(recentCommunitySearchesProvider.notifier).state = [
            '@tqd.music',
            'Những giai điệu trong phòng thu',
          ];
          await tester.pumpAndSettle();
          await capture(tester, 'search-${width.toInt()}-${mode.name}');
          await searchShortcut(tester, LogicalKeyboardKey.controlLeft);
          await tester.ensureVisible(find.byType(TextField));
          await tester.pumpAndSettle();
          await capture(tester, 'search-${width.toInt()}-${mode.name}-focused');
          await tester.enterText(find.byType(TextField), '@TQD');
          if (width == 320) {
            tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          }
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(TextField));
          await tester.pumpAndSettle();
          expect(
            tester.getSize(find.byTooltip(appCopy.clearSearch)).width,
            greaterThanOrEqualTo(48),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
