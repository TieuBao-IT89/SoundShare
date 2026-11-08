import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/catalog_widgets.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/upload/presentation/upload_screen.dart';
import 'package:soundshare/l10n/l10n.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';

import 'support/test_app.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final route in [
      '/',
      '/explore',
      '/player',
      '/upload',
      '/library',
      '/profile',
    ]) {
      testWidgets('$route lays out at ${size.width.toInt()} with large text', (
        tester,
      ) async {
        final container = await showApp(
          tester,
          route,
          size: size,
          textScale: 2,
        );
        if (route != '/player' && route != '/upload') {
          container.read(hasSelectedSongProvider.notifier).state = true;
          await tester.pump();
        }
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -1600),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      });
    }
  }

  testWidgets(
    'Explore selects the matching track and preserves paused playback across tabs',
    (tester) async {
      final player = TestPlayer();
      final container = await showApp(tester, '/explore', player: player);
      await tester.enterText(find.byType(TextField), 'nIA');
      await tester.pumpAndSettle();
      expect(find.text('Blue Again'), findsOneWidget);
      expect(find.text('Golden Hour'), findsNothing);
      await tapVisible(tester, find.byTooltip(appCopy.playSong('Blue Again')));
      expect(container.read(currentSongIndexProvider), 3);
      expect(player.active, isTrue);
      await tapVisible(tester, find.byTooltip(appCopy.pauseTrack));
      expect(player.active, isFalse);
      await tapVisible(tester, find.byTooltip(appCopy.likeSong));
      await tapVisible(tester, find.byTooltip(appCopy.backToBrowsing));
      await tester.tap(
        find.descendant(
          of: find.byType(SoundShareBottomNavigation),
          matching: find.text(appCopy.library),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mini-player')), findsOneWidget);
      expect(find.text(appCopy.likedCount(1)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(SongTile),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Blue Again'), findsNWidgets(2));
      await tester.tap(find.byTooltip(appCopy.resumeTrack));
      await tester.pumpAndSettle();
      expect(player.active, isTrue);
      expect(player.loads, 1, reason: 'Resume should keep the loaded source.');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Search empty state can clear the query', (tester) async {
    await showApp(tester, '/explore');
    await tester.enterText(find.byType(TextField), 'no such song');
    await tester.pumpAndSettle();
    expect(find.text(appCopy.noResults), findsOneWidget);
    await tapVisible(tester, find.text(appCopy.clearSearch));
    expect(find.text('Slow Motion'), findsOneWidget);
  });

  testWidgets('Catalog exposes loading, safe failure, retry and empty state', (
    tester,
  ) async {
    final pending = Completer<List<Song>>();
    var calls = 0;
    await showApp(
      tester,
      '/',
      repository: TestRepository(() {
        calls++;
        return calls == 1 ? pending.future : Future.value([]);
      }),
    );
    expect(find.byType(CatalogLoading), findsOneWidget);
    pending.completeError(StateError('internal database details'));
    await tester.pumpAndSettle();
    expect(find.text(appCopy.catalogLoadFailed), findsOneWidget);
    expect(find.textContaining('internal database details'), findsNothing);
    await tapVisible(tester, find.text(appCopy.tryAgain));
    expect(calls, 2);
    expect(find.text(appCopy.homeEmptyTitle), findsOneWidget);
  });

  testWidgets('Player handles load and asynchronous play failures with retry', (
    tester,
  ) async {
    final player = TestPlayer()..failLoad = true;
    await showApp(tester, '/player', player: player);
    await tapVisible(tester, find.byTooltip(appCopy.playTrack));
    expect(find.text(appCopy.audioLoadFailed), findsOneWidget);
    expect(find.textContaining('private provider details'), findsNothing);
    player.failLoad = false;
    player.failPlay = true;
    await tapVisible(tester, find.text(appCopy.tryAgain));
    expect(find.text(appCopy.audioLoadFailed), findsOneWidget);
    player.failPlay = false;
    await tapVisible(tester, find.text(appCopy.tryAgain));
    expect(find.text(appCopy.audioLoadFailed), findsNothing);
    expect(player.active, isTrue);
  });

  testWidgets(
    'Previous and next wrap; repeat and shuffle change playback settings',
    (tester) async {
      final player = TestPlayer();
      final container = await showApp(tester, '/player', player: player);
      await tapVisible(tester, find.byTooltip(appCopy.previousTrack));
      expect(container.read(currentSongIndexProvider), 3);
      await tapVisible(tester, find.byTooltip(appCopy.nextTrack));
      expect(container.read(currentSongIndexProvider), 0);
      await tapVisible(tester, find.byTooltip(appCopy.repeat));
      expect(player.loop, LoopMode.one);
      await tapVisible(tester, find.byTooltip(appCopy.shuffle));
      expect(player.shuffleOn, isTrue);
      await tapVisible(tester, find.byTooltip(appCopy.nextTrack));
      expect(container.read(currentSongIndexProvider), isNot(0));
    },
  );

  testWidgets('Profile guest mode has no fabricated identity or statistics', (
    tester,
  ) async {
    await showApp(tester, '/profile');
    expect(find.text(appCopy.guestName), findsOneWidget);
    expect(find.text('Alex Morgan'), findsNothing);
    expect(find.text('240'), findsNothing);
    await tapVisible(tester, find.text(appCopy.libraryTitle));
    await tester.scrollUntilVisible(
      find.text(appCopy.favoritesEmptyTitle),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(appCopy.favoritesEmptyTitle), findsOneWidget);
  });

  testWidgets(
    'Upload validates selection, handles picker failure and prepares only a local preview',
    (tester) async {
      final picker = TestPicker();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: UploadScreen(filePicker: picker),
        ),
      );
      Future<void> select(PlatformFile selected) async {
        picker.choose = () async => FilePickerResult([selected]);
        await tapVisible(tester, find.text(appCopy.chooseMp3));
      }

      await select(PlatformFile(name: 'song.wav', size: 100));
      expect(find.text(appCopy.mp3Invalid), findsOneWidget);
      await select(PlatformFile(name: 'song.mp3', size: 20 * 1024 * 1024 + 1));
      expect(find.text(appCopy.mp3Invalid), findsOneWidget);
      picker.choose = () async => throw StateError('private filesystem');
      await tapVisible(tester, find.text(appCopy.chooseMp3));
      expect(find.text(appCopy.fileOpenError), findsOneWidget);
      await select(PlatformFile(name: 'my-track.mp3', size: 100));
      await tapVisible(tester, find.text(appCopy.previewButton));
      expect(find.text(appCopy.titleRequired), findsOneWidget);
      expect(find.text(appCopy.artistRequired), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'A new song');
      await tester.enterText(find.byType(TextFormField).at(1), 'An artist');
      await tapVisible(tester, find.text(appCopy.previewButton));
      expect(find.text(appCopy.previewReady), findsOneWidget);
      expect(find.text(appCopy.previewNotice), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'Changed');
      await tester.pump();
      expect(find.text(appCopy.previewReady), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Upload ignores a picker result after leaving the screen', (
    tester,
  ) async {
    final pending = Completer<FilePickerResult?>();
    final picker = TestPicker()..choose = () => pending.future;
    await tester.pumpWidget(
      MaterialApp(home: UploadScreen(filePicker: picker)),
    );
    await tester.tap(find.text(appCopy.chooseMp3));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(
      FilePickerResult([PlatformFile(name: 'song.mp3', size: 20)]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Long catalog text and the mini-player fit a narrow phone', (
    tester,
  ) async {
    final container = await showApp(
      tester,
      '/explore',
      size: const Size(320, 640),
      textScale: 2,
      repository: TestRepository(
        () async => [
          Song(
            title: List.filled(8, 'Long song title').join(' '),
            artist: List.filled(8, 'Independent artist').join(' '),
            artwork: sampleSongs.first.artwork,
            duration: '3:00',
          ),
        ],
      ),
    );
    container.read(hasSelectedSongProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.byType(SongTile));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Explore touch targets have accessible labels and size', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await showApp(tester, '/explore');
      await tester.pumpAndSettle();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Search remains usable above a phone keyboard', (tester) async {
    await showApp(tester, '/explore', size: const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'Electronic');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip(appCopy.playSong('Blue Again')));
    expect(find.text('Blue Again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
