import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundshare/app/app.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/catalog_widgets.dart';
import 'package:soundshare/features/home/application/catalog_provider.dart';
import 'package:soundshare/features/home/data/mock_song_repository.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/upload/presentation/upload_screen.dart';

class TestPlayer extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  bool active = false;
  bool failLoad = false;
  bool failPlay = false;
  int loads = 0;
  AudioSource? source;
  LoopMode loop = LoopMode.off;
  bool shuffleOn = false;
  @override
  bool get playing => active;
  @override
  PlayerState get playerState => PlayerState(active, processingState);
  @override
  Stream<PlayerState> get playerStateStream => states.stream;
  @override
  ProcessingState get processingState =>
      source == null ? ProcessingState.idle : ProcessingState.ready;
  @override
  AudioSource? get audioSource => source;
  @override
  Duration get duration => const Duration(minutes: 3);
  @override
  Duration get position => Duration.zero;
  @override
  Stream<Duration?> get durationStream => Stream.value(duration);
  @override
  Stream<Duration> get positionStream => Stream.value(position);
  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    loads++;
    if (failLoad) throw StateError('private provider details');
    source = AudioSource.uri(Uri.parse(url));
    return duration;
  }

  @override
  Future<void> play() async {
    if (failPlay) throw StateError('private provider details');
    active = true;
    states.add(playerState);
  }

  @override
  Future<void> pause() async {
    active = false;
    states.add(playerState);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {}
  @override
  Future<void> setLoopMode(LoopMode mode) async {
    loop = mode;
  }

  @override
  Future<void> setShuffleModeEnabled(bool enabled) async {
    shuffleOn = enabled;
  }
}

class TestRepository implements SongRepository {
  TestRepository(this.load);
  final Future<List<Song>> Function() load;
  @override
  Future<List<Song>> featured() => load();
}

class TestPicker extends FilePicker {
  Future<FilePickerResult?> Function() choose = () async => null;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) => choose();
}

Future<ProviderContainer> showApp(
  WidgetTester tester,
  String route, {
  TestPlayer? player,
  SongRepository? repository,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final audio = player ?? TestPlayer();
  final router = createAppRouter(initialLocation: route);
  final container = ProviderContainer(
    overrides: [
      audioPlayerProvider.overrideWithValue(audio),
      if (repository != null)
        songRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    container.dispose();
    await audio.states.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: SoundShareApp(router: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

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
        expect(tester.takeException(), isNull);
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
      await tapVisible(tester, find.byTooltip('Play Blue Again'));
      expect(container.read(currentSongIndexProvider), 3);
      expect(player.active, isTrue);
      await tapVisible(tester, find.byTooltip('Pause track'));
      expect(player.active, isFalse);
      await tapVisible(tester, find.byTooltip('Like song'));
      await tapVisible(tester, find.byTooltip('Back to browsing'));
      await tester.tap(find.text('Library').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mini-player')), findsOneWidget);
      expect(find.text('1 liked track'), findsOneWidget);
      expect(find.text('Blue Again'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Resume track'));
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
    expect(find.text('No tracks found'), findsOneWidget);
    await tapVisible(tester, find.text('Clear search'));
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
    expect(find.text('The music is taking a moment'), findsOneWidget);
    expect(find.textContaining('internal database details'), findsNothing);
    await tapVisible(tester, find.text('Try again'));
    expect(calls, 2);
    expect(find.text('The listening room is quiet'), findsOneWidget);
  });

  testWidgets('Player handles load and asynchronous play failures with retry', (
    tester,
  ) async {
    final player = TestPlayer()..failLoad = true;
    await showApp(tester, '/player', player: player);
    await tapVisible(tester, find.byTooltip('Play track'));
    expect(find.textContaining('Audio could not be loaded'), findsOneWidget);
    expect(find.textContaining('private provider details'), findsNothing);
    player.failLoad = false;
    player.failPlay = true;
    await tapVisible(tester, find.text('Try again'));
    expect(find.textContaining('Audio could not be loaded'), findsOneWidget);
    player.failPlay = false;
    await tapVisible(tester, find.text('Try again'));
    expect(find.textContaining('Audio could not be loaded'), findsNothing);
    expect(player.active, isTrue);
  });

  testWidgets(
    'Previous and next wrap; repeat and shuffle change playback settings',
    (tester) async {
      final player = TestPlayer();
      final container = await showApp(tester, '/player', player: player);
      await tapVisible(tester, find.byTooltip('Play previous track'));
      expect(container.read(currentSongIndexProvider), 3);
      await tapVisible(tester, find.byTooltip('Play next track'));
      expect(container.read(currentSongIndexProvider), 0);
      await tapVisible(tester, find.text('Repeat'));
      expect(player.loop, LoopMode.one);
      await tapVisible(tester, find.text('Shuffle'));
      expect(player.shuffleOn, isTrue);
      await tapVisible(tester, find.byTooltip('Play next track'));
      expect(container.read(currentSongIndexProvider), isNot(0));
    },
  );

  testWidgets('Profile guest mode has no fabricated identity or statistics', (
    tester,
  ) async {
    await showApp(tester, '/profile');
    expect(find.text('Listening as a guest'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsNothing);
    expect(find.text('240'), findsNothing);
    await tapVisible(tester, find.text('0 liked tracks'));
    expect(find.text('Find your first favorite'), findsOneWidget);
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
        await tapVisible(tester, find.text('Choose an MP3 file'));
      }

      await select(PlatformFile(name: 'song.wav', size: 100));
      expect(
        find.text('Choose a non-empty MP3 file up to 20 MB.'),
        findsOneWidget,
      );
      await select(PlatformFile(name: 'song.mp3', size: 20 * 1024 * 1024 + 1));
      expect(
        find.text('Choose a non-empty MP3 file up to 20 MB.'),
        findsOneWidget,
      );
      picker.choose = () async => throw StateError('private filesystem');
      await tapVisible(tester, find.text('Choose an MP3 file'));
      expect(
        find.text('The file could not be opened. Please choose it again.'),
        findsOneWidget,
      );
      await select(PlatformFile(name: 'my-track.mp3', size: 100));
      await tapVisible(tester, find.text('Preview track details'));
      expect(find.text('Add a title for this track.'), findsOneWidget);
      expect(find.text('Add the artist name.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(0), 'A new song');
      await tester.enterText(find.byType(TextFormField).at(1), 'An artist');
      await tapVisible(tester, find.text('Preview track details'));
      expect(find.text('Your local preview is ready'), findsOneWidget);
      expect(
        find.text(
          'Publishing is not available in this preview. Your file has not been uploaded.',
        ),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Changed');
      await tester.pump();
      expect(find.text('Your local preview is ready'), findsNothing);
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
    await tester.tap(find.text('Choose an MP3 file'));
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
    await tapVisible(tester, find.byTooltip('Play Blue Again'));
    expect(find.text('Blue Again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
