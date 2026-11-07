import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/services/sleep_timer_service.dart';
import 'package:soundshare/core/services/song_favorite_service.dart';
import 'package:soundshare/core/widgets/listening_panel.dart';
import 'package:soundshare/features/home/application/catalog_provider.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/player/presentation/player_record.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'community_test.dart'
    show CommunityFixture, showCommunity, CompletingPlayer;
import 'support/test_app.dart';
import 'vinyl_record_artwork_test.dart'
    show rotation, cachePreviewCover, previewSong, capture, captureReview;

class _Favorites extends TestRepository {
  _Favorites() : super(() async => sampleSongs);
  final writes = <(String, bool)>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> favorite(Song song, bool liked) async {
    writes.add((song.identity, liked));
    await pending?.future;
    if (fail) throw StateError('private provider details');
  }
}

class _LoadingRepository extends TestRepository {
  _LoadingRepository() : super(() async => sampleSongs);
  final url = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> playbackInfo(Song song) => url.future;
}

class _ReplayPlayer extends CompletingPlayer {
  Duration? sought;
  @override
  Future<void> seek(Duration? position, {int? index}) async {
    sought = position;
    completed = false;
  }
}

Future<void> _doubleTap(WidgetTester tester) async {
  await tester.tap(find.byType(PlayerRecord));
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(find.byType(PlayerRecord));
  await pumpPlaybackUi(tester);
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

  testWidgets('Double tap and button share saved favorite state', (
    tester,
  ) async {
    final repository = _Favorites();
    final container = await showApp(tester, '/player', repository: repository);
    await tester.pumpAndSettle();
    await _doubleTap(tester);
    expect(repository.writes, [(sampleSongs.first.identity, true)]);
    expect(container.read(likedSongIndicesProvider), {0});
    expect(find.byTooltip(appCopy.unlikeSong), findsOneWidget);
    await tester.tap(find.byTooltip(appCopy.unlikeSong));
    await pumpPlaybackUi(tester);
    expect(repository.writes.last, (sampleSongs.first.identity, false));
    expect(container.read(likedSongIndicesProvider), isEmpty);
  });

  testWidgets('Favorite failure and repeated gestures never fake success', (
    tester,
  ) async {
    final repository = _Favorites()..pending = Completer<void>();
    final container = await showApp(tester, '/player', repository: repository);
    await tester.pumpAndSettle();
    await _doubleTap(tester);
    await _doubleTap(tester);
    expect(repository.writes, hasLength(1));
    expect(container.read(favoriteBusyProvider), {sampleSongs.first.identity});
    repository.fail = true;
    repository.pending!.complete();
    await pumpPlaybackUi(tester);
    expect(container.read(likedSongIndicesProvider), isEmpty);
    expect(container.read(favoriteBusyProvider), isEmpty);
    expect(find.text(appCopy.likeSaveFailed), findsOneWidget);
    expect(find.textContaining('private provider'), findsNothing);
  });

  testWidgets('Late favorite response keeps its song after a queue switch', (
    tester,
  ) async {
    final repository = _Favorites()..pending = Completer<void>();
    final container = await showApp(tester, '/player', repository: repository);
    await tester.pumpAndSettle();
    await _doubleTap(tester);
    await container.read(playbackActionsProvider).playFrom([
      sampleSongs[2],
      sampleSongs[0],
    ], 0);
    repository.pending!.complete();
    await pumpPlaybackUi(tester);
    expect(container.read(likedSongIndicesProvider), {0});
    expect(container.read(songLikedProvider(sampleSongs[2])), isFalse);
    expect(container.read(songLikedProvider(sampleSongs[0])), isTrue);
    expect(find.byTooltip(appCopy.likeSong), findsOneWidget);
  });

  testWidgets('Record swipes change tracks and preserve the one audio player', (
    tester,
  ) async {
    final audio = TestPlayer();
    final container = await showApp(tester, '/player', player: audio);
    await tester.pumpAndSettle();
    await container.read(playbackActionsProvider).play(0);
    await pumpPlaybackUi(tester);
    final phase = rotation(tester);
    await tester.drag(find.byType(PlayerRecord), const Offset(-110, 0));
    await pumpPlaybackUi(tester);
    expect(
      container.read(currentSongProvider)?.identity,
      sampleSongs[1].identity,
    );
    expect(identical(phase, rotation(tester)), isTrue);
    await tester.drag(find.byType(PlayerRecord), const Offset(110, 0));
    await pumpPlaybackUi(tester);
    expect(
      container.read(currentSongProvider)?.identity,
      sampleSongs.first.identity,
    );
    expect(audio.loads, 3);
    expect(identical(container.read(audioPlayerProvider), audio), isTrue);
  });

  testWidgets(
    'Reorder preserves current entry, duplicate tracks and playback',
    (tester) async {
      final audio = TestPlayer();
      final container = await showApp(tester, '/player', player: audio);
      final actions = container.read(playbackActionsProvider);
      await actions.playFrom([
        sampleSongs[0],
        sampleSongs[1],
        sampleSongs[0],
        sampleSongs[2],
      ], 2);
      await pumpPlaybackUi(tester);
      actions.reorderQueue(2, 0);
      expect(container.read(currentSongIndexProvider), 0);
      actions.reorderQueue(3, 0);
      expect(container.read(currentSongIndexProvider), 1);
      actions.reorderQueue(0, 3);
      expect(container.read(currentSongIndexProvider), 0);
      expect(container.read(playbackQueueProvider), [
        sampleSongs[0],
        sampleSongs[0],
        sampleSongs[1],
        sampleSongs[2],
      ]);
      expect(
        container.read(currentSongProvider)?.identity,
        sampleSongs[0].identity,
      );
      expect(audio.loads, 1);
      expect(audio.playing, isTrue);
      actions.removeFromQueue(0); // Current entry stays protected.
      expect(container.read(playbackQueueProvider), hasLength(4));
      await actions.skip(1);
      expect(container.read(currentSongIndexProvider), 1);
      expect(audio.loads, 1); // Same track, different queue occurrence.
    },
  );

  testWidgets('Completion advances a reordered queue after pause and resume', (
    tester,
  ) async {
    final audio = CompletingPlayer();
    final container = await showApp(tester, '/player', player: audio);
    final actions = container.read(playbackActionsProvider);
    await actions.playFrom(sampleSongs, 0);
    await actions.pause();
    await actions.togglePlayback();
    actions.reorderQueue(2, 1);
    audio.complete();
    await pumpPlaybackUi(tester);
    expect(
      container.read(currentSongProvider)?.identity,
      sampleSongs[2].identity,
    );
    expect(audio.loads, 2);
    expect(audio.playing, isTrue);
  });

  testWidgets('Play at the end of the queue restarts with one tap', (
    tester,
  ) async {
    final audio = _ReplayPlayer();
    final container = await showApp(tester, '/player', player: audio);
    await container.read(playbackActionsProvider).playFrom([sampleSongs[0]], 0);
    audio.complete();
    await pumpPlaybackUi(tester);
    expect(find.byTooltip(appCopy.playTrack), findsOneWidget);
    await tester.tap(find.byTooltip(appCopy.playTrack));
    await pumpPlaybackUi(tester);
    expect(audio.playing, isTrue);
    expect(audio.sought, Duration.zero);
    expect(find.byTooltip(appCopy.pauseTrack), findsOneWidget);
  });

  testWidgets('Mobile queue opens a sheet, supports drag, play now and add', (
    tester,
  ) async {
    final container = await showApp(tester, '/player');
    await container.read(playbackActionsProvider).playFrom(sampleSongs, 0);
    await pumpPlaybackUi(tester);
    await tester.tap(find.byTooltip(appCopy.v3AddToQueue));
    await pumpPlaybackUi(tester);
    expect(container.read(playbackQueueProvider), hasLength(5));
    await tester.tap(find.byTooltip(appCopy.v3Queue));
    await pumpPlaybackUi(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(ListeningPanel), findsOneWidget);
    final list = find.byType(ReorderableListView);
    final handle = find.descendant(
      of: list,
      matching: find.byIcon(Icons.drag_handle_rounded),
    );
    await tester.drag(handle.at(1), const Offset(0, 145));
    await pumpPlaybackUi(tester);
    expect(
      container.read(playbackQueueProvider)!.indexOf(sampleSongs[1]),
      greaterThan(1),
    );
    await tester.tap(
      find.descendant(of: list, matching: find.text(sampleSongs[2].title)),
    );
    await pumpPlaybackUi(tester);
    expect(
      container.read(currentSongProvider)?.identity,
      sampleSongs[2].identity,
    );
    await tester.tap(find.byTooltip(appCopy.v4CloseQueue));
    await pumpPlaybackUi(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(PlayerRecord), findsOneWidget);
  });

  testWidgets('Creator name opens the real public profile route', (
    tester,
  ) async {
    final fixture = CommunityFixture();
    final container = await showCommunity(tester, '/player', fixture: fixture);
    await tester.pumpAndSettle();
    // Discovery and private catalog are separate; select the real fixture song.
    await container.read(playbackActionsProvider).playFrom([
      Song.fromJson(fixture.song),
    ], 0);
    await pumpPlaybackUi(tester);
    await tester.tap(find.text('Người sáng tạo'));
    await pumpPlaybackUi(tester);
    expect(find.text('Trần Quốc Dũng'), findsWidgets);
    expect(
      fixture.requests.any(
        (request) => request.url.path.endsWith('/users/tqd.music'),
      ),
      isTrue,
    );
  });

  testWidgets('Missing lyrics has a Vietnamese empty state at large text', (
    tester,
  ) async {
    await showApp(tester, '/player', size: const Size(320, 640), textScale: 2);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip(appCopy.playerLyrics));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(appCopy.playerLyricsUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Sleep timer replaces and cancels deadlines, then pauses current track',
    (tester) async {
      final audio = TestPlayer();
      final container = await showApp(tester, '/player', player: audio);
      final actions = container.read(playbackActionsProvider);
      await actions.play(0);
      await pumpPlaybackUi(tester);
      final timer = container.read(sleepTimerProvider.notifier);
      timer.start(const Duration(seconds: 2));
      timer.start(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 3));
      expect(audio.playing, isTrue);
      timer.cancel();
      await tester.pump(const Duration(seconds: 5));
      expect(audio.playing, isTrue);
      timer.start(const Duration(seconds: 3));
      await actions.skip(1);
      await tester.pump(const Duration(seconds: 4));
      await pumpPlaybackUi(tester);
      expect(audio.playing, isFalse);
      expect(container.read(sleepTimerProvider), isNull);
      expect(
        container.read(currentSongProvider)?.identity,
        sampleSongs[1].identity,
      );
    },
  );

  testWidgets('Sleep deadline during loading prevents a late audio start', (
    tester,
  ) async {
    final audio = TestPlayer();
    final repository = _LoadingRepository();
    final container = await showApp(
      tester,
      '/player',
      player: audio,
      repository: repository,
    );
    final loading = container.read(playbackActionsProvider).play(0);
    container
        .read(sleepTimerProvider.notifier)
        .start(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    repository.url.complete({'url': sampleSongs.first.audioUrl});
    await loading;
    await pumpPlaybackUi(tester);
    expect(audio.playing, isFalse);
    expect(container.read(playbackLoadingProvider), isFalse);
    await container.read(playbackActionsProvider).togglePlayback();
    await pumpPlaybackUi(tester);
    expect(audio.playing, isTrue);
  });

  testWidgets(
    'A late completed event cannot restart the queue after a sleep deadline',
    (tester) async {
      final audio = CompletingPlayer();
      final container = await showApp(tester, '/player', player: audio);
      await container.read(playbackActionsProvider).playFrom(sampleSongs, 0);
      container
          .read(sleepTimerProvider.notifier)
          .start(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      audio.complete();
      await pumpPlaybackUi(tester);
      expect(audio.playing, isFalse);
      expect(audio.loads, 1);
      expect(container.read(currentSongIndexProvider), 0);
    },
  );

  testWidgets('Sleep timer sheet starts and cancels the actual timer', (
    tester,
  ) async {
    final container = await showApp(tester, '/player');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(appCopy.playerSleepTimer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(appCopy.playerMinutes(15)));
    await tester.pumpAndSettle();
    expect(container.read(sleepTimerProvider), isNotNull);
    await tester.tap(find.byIcon(Icons.bedtime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(appCopy.playerCancelTimer));
    await tester.pumpAndSettle();
    expect(container.read(sleepTimerProvider), isNull);
  });

  testWidgets(
    'Responsive tree changes preserve paused angle and loaded audio',
    (tester) async {
      final audio = TestPlayer();
      final container = await showApp(tester, '/player', player: audio);
      await container.read(playbackActionsProvider).play(0);
      await pumpPlaybackUi(tester);
      await tester.pump(const Duration(seconds: 3));
      await audio.pause();
      await tester.pumpAndSettle();
      final angle = rotation(tester).value;
      for (final size in [
        const Size(1440, 900),
        const Size(768, 1024),
        const Size(360, 740),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(rotation(tester).value, closeTo(angle, .0001));
        expect(audio.loads, 1);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(360, 740),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Play is reachable without scroll at $size in ${mode.name}', (
        tester,
      ) async {
        await cachePreviewCover(tester);
        tester.view.padding = FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPadding);
        final container = await showApp(
          tester,
          '/player',
          size: size,
          initialThemeMode: mode,
          repository: TestRepository(() async => [previewSong]),
        );
        await tester.pumpAndSettle();
        final play = find.byTooltip(appCopy.playTrack);
        expect(play.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(play);
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 24));
        expect(bounds.top, greaterThan(24));
        await capture(tester, 'v2-player-${size.width.toInt()}-${mode.name}');
        if (captureReview && size.width == 390) {
          final next = Song(
            id: 'preview-next',
            title: 'Bản thu tiếp theo (mẫu)',
            artist: 'SoundShare',
            artwork: previewSong.artwork,
            duration: '3:00',
          );
          await container.read(playbackActionsProvider).playFrom([
            previewSong,
            next,
          ], 0);
          await pumpPlaybackUi(tester);
          await capture(tester, 'v2-player-390-${mode.name}-playing');
          await tester.tap(find.byTooltip(appCopy.v3Queue));
          await pumpPlaybackUi(tester);
          await capture(tester, 'v2-queue-${mode.name}');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
