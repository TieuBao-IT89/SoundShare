import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundshare/app/app.dart';
import 'package:soundshare/app/theme/theme_controller.dart';
import 'package:soundshare/core/config/app_mode.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/features/home/application/catalog_provider.dart';
import 'package:soundshare/features/home/data/mock_song_repository.dart';
import 'package:soundshare/features/home/domain/song.dart';

class TestPlayer extends Fake implements AudioPlayer {
  final states = StreamController<PlayerState>.broadcast();
  bool active = false;
  bool failLoad = false;
  bool failPlay = false;
  int loads = 0;
  AudioSource? source;
  LoopMode loop = LoopMode.off;
  bool shuffleOn = false;
  double volumeValue = 1;
  @override
  double get volume => volumeValue;
  @override
  Stream<double> get volumeStream => Stream.value(volumeValue);
  @override
  Future<void> setVolume(double value) async {
    volumeValue = value;
  }

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

class TestRepository extends SongRepository {
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
  ThemeMode initialThemeMode = ThemeMode.light,
  ThemePreferenceStore? themeStore,
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
      initialThemeModeProvider.overrideWithValue(initialThemeMode),
      if (themeStore != null)
        themePreferenceStoreProvider.overrideWithValue(themeStore),
      demoModeProvider.overrideWithValue(true),
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
      child: SoundShareApp(router: router, authenticationRequired: false),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

Future<void> tapVisible(
  WidgetTester tester,
  Finder finder, {
  double scrollDelta = 300,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      scrollDelta,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await pumpPlaybackUi(tester);
  await tester.tap(finder);
  await pumpPlaybackUi(tester);
}

/// A playing vinyl schedules frames continuously. Advance the finite UI
/// transitions around it instead of waiting for every animation to stop.
Future<void> pumpPlaybackUi(WidgetTester tester) async {
  for (var frame = 0; frame < 6; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
