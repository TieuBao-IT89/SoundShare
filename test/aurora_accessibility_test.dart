import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';
import 'package:soundshare/core/widgets/aurora_widgets.dart';
import 'package:soundshare/core/widgets/catalog_widgets.dart';
import 'package:soundshare/features/explore/presentation/explore_screen.dart';
import 'package:soundshare/features/home/application/catalog_provider.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/upload/presentation/upload_screen.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

Finder _navigationLabel(String label) => find.descendant(
  of: find.byType(SoundShareBottomNavigation),
  matching: find.bySemanticsLabel(label),
);

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets(
      'Search stays reachable above the keyboard at $size while audio continues',
      (tester) async {
        final audio = TestPlayer();
        final container = await showApp(
          tester,
          '/explore',
          player: audio,
          size: size,
          textScale: 2,
        );
        await container.read(playbackActionsProvider).play(0);
        await tester.pumpAndSettle();
        final field = find.byType(TextField);
        await tapVisible(tester, field);
        await tester.enterText(field, 'Blue');
        final keyboardHeight = size.height > 400 ? 280.0 : 180.0;
        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        final editable = find.byType(EditableText);
        expect(tester.getRect(editable).top, greaterThanOrEqualTo(0));
        expect(
          tester.getRect(editable).bottom,
          lessThanOrEqualTo(size.height - keyboardHeight),
        );
        expect(audio.active, isTrue);
        expect(audio.loads, 1);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('mini-player')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Upload keeps long Vietnamese input visible with the keyboard and dismisses on drag',
    (tester) async {
      await showApp(
        tester,
        '/upload',
        size: const Size(320, 640),
        textScale: 2,
      );
      final title = find.widgetWithText(TextFormField, appCopy.songTitle);
      await tapVisible(tester, title);
      await tester.enterText(
        title,
        'Bài hát của tôi – những giai điệu đầu tiên',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      final editable = find.descendant(
        of: title,
        matching: find.byType(EditableText),
      );
      expect(tester.getRect(editable).bottom, lessThanOrEqualTo(360));
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isTrue);
      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isFalse);
      expect(find.byType(UploadScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bottom navigation can be activated through semantic tap actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await showApp(tester, '/');
        await tester.pumpAndSettle();

        final labels = [
          appCopy.home,
          appCopy.explore,
          appCopy.library,
          appCopy.profile,
        ];
        for (final label in labels) {
          expect(
            tester.getSemantics(_navigationLabel(label)),
            isSemantics(
              label: label,
              isButton: true,
              hasSelectedState: true,
              isSelected: label == appCopy.home,
              hasTapAction: true,
            ),
          );
        }

        final explore = tester.getSemantics(_navigationLabel(appCopy.explore));
        // Dispatch the action exposed to screen readers, without a pointer tap.
        tester.semantics.performAction(
          find.semantics.byPredicate((node) => node.id == explore.id),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();

        expect(find.byType(ExploreScreen), findsOneWidget);
        expect(
          tester.getSemantics(_navigationLabel(appCopy.explore)),
          isSemantics(isButton: true, isSelected: true, hasTapAction: true),
        );
        expect(
          tester.getSemantics(_navigationLabel(appCopy.home)),
          isSemantics(isSelected: false, hasTapAction: true),
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final route in ['/', '/explore', '/library', '/upload', '/profile']) {
    testWidgets('$route fits a desktop with 2x text and a persistent player', (
      tester,
    ) async {
      final container = await showApp(
        tester,
        route,
        size: const Size(1280, 900),
        textScale: 2,
      );
      container.read(likedSongIndicesProvider.notifier).state = {0, 3};
      container.read(hasSelectedSongProvider.notifier).state = true;
      await tester.pumpAndSettle();

      expect(find.byType(SoundShareBottomNavigation), findsNothing);
      if (route != '/upload') {
        expect(find.byKey(const ValueKey('mini-player')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      // Exclude the rail and the editable fields' internal scroll views.
      final pageScrollable = find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(pageScrollable, const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('An empty desktop Home remains readable with 2x text', (
    tester,
  ) async {
    await showApp(
      tester,
      '/',
      size: const Size(1280, 900),
      textScale: 2,
      repository: TestRepository(() async => []),
    );
    await tester.pumpAndSettle();

    expect(find.text(appCopy.homeEmptyTitle), findsOneWidget);
    expect(find.text(appCopy.homeEmptyDemo), findsOneWidget);
    expect(find.text(appCopy.exploreMusic), findsOneWidget);
    expect(find.byType(SongTile), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Desktop search failure is safe and retry preserves the filter', (
    tester,
  ) async {
    var calls = 0;
    await showApp(
      tester,
      '/explore?genre=Electronic',
      size: const Size(1280, 900),
      textScale: 2,
      repository: TestRepository(() async {
        if (++calls == 1) throw StateError('private provider details');
        return sampleSongs;
      }),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CatalogError), findsOneWidget);
    expect(find.text(appCopy.catalogLoadFailed), findsOneWidget);
    expect(find.textContaining('private provider details'), findsNothing);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.text(appCopy.tryAgain));

    expect(calls, 2);
    expect(
      tester.widget<ExploreScreen>(find.byType(ExploreScreen)).filters.genre,
      'Electronic',
    );
    expect(find.byType(SongTile), findsOneWidget);
    expect(find.text('Blue Again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Reduced motion keeps library loading static and able to settle',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: CatalogLoading()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoadingSkeleton), findsOneWidget);
        expect(find.bySemanticsLabel(appCopy.loadingLibrary), findsOneWidget);
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
