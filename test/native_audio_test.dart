import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart' as media;
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundshare/core/config/app_mode.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/services/media_artwork.dart';
import 'package:soundshare/core/services/media_session.dart';
import 'package:soundshare/core/services/native_audio_runtime.dart';
import 'package:soundshare/core/services/notification_artwork_native.dart';
import 'package:soundshare/core/widgets/visible_playback_position.dart';
import 'package:soundshare/features/home/application/catalog_provider.dart';
import 'package:soundshare/features/home/domain/song.dart';

import 'support/test_app.dart';

class MediaPlayer extends TestPlayer {
  final positions = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get positionStream => positions.stream;
  final events = StreamController<PlaybackEvent>.broadcast();
  final speeds = StreamController<double>.broadcast();
  final buffers = StreamController<Duration>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  ProcessingState phase = ProcessingState.idle;
  Duration at = Duration.zero;
  Duration buffered = const Duration(seconds: 40);
  int disposals = 0;
  Completer<void>? retirement;
  @override
  ProcessingState get processingState => phase;
  @override
  Duration get position => at;
  @override
  Duration get bufferedPosition => buffered;
  @override
  double get speed => 1;
  @override
  Stream<double> get speedStream => speeds.stream;
  @override
  Stream<Duration> get bufferedPositionStream => buffers.stream;
  @override
  Stream<Duration?> get durationStream => durations.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    at = initialPosition ?? Duration.zero;
    phase = ProcessingState.ready;
    return super.setUrl(url, initialPosition: initialPosition);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    at = position ?? Duration.zero;
    phase = ProcessingState.ready;
    events.add(PlaybackEvent());
  }

  @override
  Future<void> stop() async {
    phase = ProcessingState.idle;
    await super.stop();
  }

  @override
  Future<void> dispose() async {
    disposals++;
    active = false;
    await retirement?.future;
  }

  void processing(ProcessingState value) {
    phase = value;
    states.add(playerState);
  }

  Future<void> close() async {
    await positions.close();
    await states.close();
    await events.close();
    await speeds.close();
    await buffers.close();
    await durations.close();
  }
}

class FocusSession extends Fake implements AudioSession {
  int deactivations = 0;
  @override
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    AndroidAudioAttributes? androidAudioAttributes,
    bool? androidWillPauseWhenDucked,
    AudioSessionConfiguration fallbackConfiguration =
        const AudioSessionConfiguration.music(),
  }) async {
    if (!active) deactivations++;
    return true;
  }

  final interruptions = StreamController<AudioInterruptionEvent>.broadcast();
  final noisy = StreamController<void>.broadcast();
  AudioSessionConfiguration? configured;
  @override
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      interruptions.stream;
  @override
  Stream<void> get becomingNoisyEventStream => noisy.stream;
  @override
  Future<void> configure(AudioSessionConfiguration configuration) async {
    configured = configuration;
  }

  Future<void> close() async {
    await interruptions.close();
    await noisy.close();
  }
}

class Tickets extends TestRepository {
  Tickets() : super(() async => sampleSongs);
  int tickets = 0, beats = 0;
  DateTime? expiry;
  int? denied;
  Completer<Map<String, dynamic>>? pending;
  @override
  Future<Map<String, dynamic>> playbackInfo(Song song) async {
    tickets++;
    if (denied != null) throw ApiException(denied!, 'UNAUTHORIZED');
    return pending?.future ??
        Future.value({
          'url': song.audioUrl,
          'playSessionId': 'ticket-$tickets',
          if (expiry != null) 'expiresAt': expiry!.toIso8601String(),
        });
  }

  @override
  Future<bool> heartbeat(String sessionId, int positionMs, bool playing) async {
    beats++;
    if (denied != null) throw ApiException(denied!, 'UNAUTHORIZED');
    return false;
  }
}

class DeferredArt implements MediaArtworkStore {
  final pending = <Completer<Uri?>>[];
  bool disposed = false;
  @override
  Future<Uri?> resolve(String artworkUrl) {
    final result = Completer<Uri?>();
    pending.add(result);
    return result.future;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class Harness {
  Harness({SoundShareAudioHandler? bridge, Tickets? repository})
    : handler = bridge ?? SoundShareAudioHandler(),
      songs = repository ?? Tickets() {
    container = ProviderContainer(
      overrides: [
        demoModeProvider.overrideWithValue(true),
        nativeAudioHandlerProvider.overrideWithValue(handler),
        musicAudioSessionProvider.overrideWithValue(Future.value(focus)),
        audioPlayerFactoryProvider.overrideWithValue((automaticInterruptions) {
          expect(automaticInterruptions, isFalse);
          creations++;
          return player;
        }),
        songRepositoryProvider.overrideWithValue(songs),
      ],
    );
  }
  final SoundShareAudioHandler handler;
  final Tickets songs;
  final player = MediaPlayer();
  final focus = FocusSession();
  late final ProviderContainer container;
  int creations = 0;
  PlaybackActions get actions => container.read(playbackActionsProvider);
  Future<void> mount(WidgetTester tester) =>
      tester.pumpWidget(_HarnessOwner(this));
  Future<void> start() async {
    await container.read(catalogProvider.future);
    await actions.playFrom(sampleSongs, 0);
  }

  Future<void> close() async {
    container.dispose();
    await player.close();
    await focus.close();
  }
}

class _HarnessOwner extends StatefulWidget {
  const _HarnessOwner(this.harness);
  final Harness harness;
  @override
  State<_HarnessOwner> createState() => _HarnessOwnerState();
}

class _HarnessOwnerState extends State<_HarnessOwner> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
  @override
  void dispose() {
    widget.harness.container.dispose();
    super.dispose();
  }
}

void main() {
  testWidgets(
    'Stop replaces private platform metadata even when the platform ignores null items',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      media.MediaItem? platformMetadata;
      final subscription = h.handler.mediaItem.listen((item) {
        if (item != null) platformMetadata = item;
      });
      addTearDown(subscription.cancel);
      await h.start();
      await tester.pump();
      expect(platformMetadata!.title, sampleSongs.first.title);
      await h.handler.stop();
      await tester.pump();
      expect(platformMetadata!.title, 'SoundShare');
      expect(platformMetadata!.artist, isNull);
      expect(platformMetadata!.artUri, isNull);
      expect(h.handler.mediaItem.value, isNull);
      expect(h.handler.queue.value, isEmpty);
    },
  );

  testWidgets(
    'Hidden UI cancels position ticks and resumes at the actual engine position',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.start();
      h.player.at = const Duration(seconds: 12);
      await tester.pumpWidget(
        MaterialApp(
          home: VisiblePlaybackPosition(
            player: h.player,
            builder: (_, position) => Text('${position.inSeconds}'),
          ),
        ),
      );
      expect(h.player.positions.hasListener, isTrue);
      expect(find.text('12'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(h.player.positions.hasListener, isFalse);
      expect(h.player.playing, isTrue);
      h.player.at = const Duration(seconds: 67);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.player.positions.hasListener, isTrue);
      expect(find.text('67'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      h.container.dispose();
    },
  );

  testWidgets(
    'Decoded artwork is a local cached PNG and its URL is never the returned metadata',
    (tester) async {
      await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'soundshare-art-test-',
        );
        late List<int> png;
        var requests = 0;
        final store = NativeNotificationArtwork(
          directory: () async => directory,
          client: MockClient((_) async {
            requests++;
            return http.Response.bytes(png, 200);
          }),
        );
        final logo = await store.resolve('');
        png = await File.fromUri(logo!).readAsBytes();
        const url = 'https://fixture.test/art?signature=private';
        final cover = await store.resolve(url);
        expect(cover!.scheme, 'file');
        expect(cover, isNot(logo));
        expect(await store.resolve(url), cover);
        expect(requests, 1);
        store.dispose();
        for (
          var i = 0;
          i < 10 && (await directory.list().toList()).isNotEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(await directory.list().toList(), isEmpty);
        await directory.delete();
      });
    },
  );

  testWidgets('Cold media buttons do not restore an unauthenticated queue', (
    tester,
  ) async {
    final handler = SoundShareAudioHandler();
    await handler.play();
    await handler.skipToNext();
    await handler.click();
    expect(handler.queue.value, isEmpty);
    expect(handler.mediaItem.value, isNull);
    expect(
      handler.playbackState.value.processingState,
      media.AudioProcessingState.idle,
    );
  });

  testWidgets(
    'Standard headset media/next/previous buttons use the live account',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await tester.pump();
      await h.handler.seek(const Duration(seconds: 20));
      await h.handler.click();
      await tester.pump();
      expect(h.player.playing, isFalse);
      await h.handler.click();
      await tester.pump();
      expect(h.player.playing, isTrue);
      expect(h.player.position.inSeconds, 20);
      expect(h.songs.tickets, 1);
      await h.handler.click(media.MediaButton.next);
      await tester.pump();
      expect(h.container.read(currentSongIndexProvider), 1);
      await h.handler.click(media.MediaButton.previous);
      await tester.pump();
      expect(h.container.read(currentSongIndexProvider), 0);
    },
  );

  testWidgets(
    'The next account waits for native decoder disposal before loading',
    (tester) async {
      final bridge = SoundShareAudioHandler();
      final a = Harness(bridge: bridge);
      addTearDown(a.close);
      await a.mount(tester);
      await a.start();
      a.player.retirement = Completer<void>();
      a.container.dispose();
      final b = Harness(bridge: bridge);
      addTearDown(b.close);
      await b.mount(tester);
      final loading = b.actions.playFrom([sampleSongs[1]], 0);
      await tester.pump();
      expect(b.player.loads, 0);
      expect(bridge.mediaItem.value?.title, sampleSongs[1].title);
      a.player.retirement!.complete();
      await loading;
      await tester.pump();
      expect(b.player.loads, 1);
      expect(b.player.playing, isTrue);
      expect(a.player.playing, isFalse);
    },
  );

  testWidgets(
    'An interruption during URL loading prevents delayed automatic play',
    (tester) async {
      final songs = Tickets()..pending = Completer<Map<String, dynamic>>();
      final h = Harness(repository: songs);
      addTearDown(h.close);
      await h.mount(tester);
      final loading = h.actions.playFrom(sampleSongs, 0);
      await tester.pump();
      h.focus.noisy.add(null);
      await tester.pump();
      songs.pending!.complete({'url': sampleSongs.first.audioUrl});
      await loading;
      await tester.pump();
      expect(h.player.playing, isFalse);
    },
  );

  testWidgets(
    'One player survives UI rebuild, background and foreground; disposal revokes media',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.start();
      await pumpPlaybackUi(tester);
      Widget ui() => UncontrolledProviderScope(
        container: h.container,
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) =>
                Text('${ref.watch(audioPlayerProvider).hashCode}'),
          ),
        ),
      );
      await tester.pumpWidget(ui());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(h.player.playing, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(ui());
      expect(h.creations, 1);
      expect(
        identical(h.container.read(audioPlayerProvider), h.player),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      h.container.dispose();
      expect(h.player.disposals, 1);
      expect(h.handler.mediaItem.value, isNull);
      expect(h.handler.queue.value, isEmpty);
      await h.handler.play();
      expect(h.player.playing, isFalse);
    },
  );

  testWidgets(
    'Media commands delegate play, pause, seek, next, previous and queue index',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await pumpPlaybackUi(tester);
      await h.handler.pause();
      await tester.pump();
      expect(h.player.playing, isFalse);
      expect(h.handler.playbackState.value.playing, isFalse);
      await h.handler.play();
      await tester.pump();
      expect(h.player.loads, 1);
      expect(h.songs.tickets, 1);
      await h.handler.seek(const Duration(seconds: 25));
      await tester.pump();
      expect(h.player.position.inSeconds, 25);
      expect(h.handler.playbackState.value.updatePosition.inSeconds, 25);
      await h.handler.skipToNext();
      await tester.pump();
      expect(h.handler.mediaItem.value!.title, sampleSongs[1].title);
      await h.handler.skipToPrevious();
      await tester.pump();
      expect(h.handler.mediaItem.value!.title, sampleSongs[0].title);
      await h.handler.skipToQueueItem(2);
      await tester.pump();
      expect(h.handler.playbackState.value.queueIndex, 2);
      expect(
        h.container.read(currentSongProvider)!.title,
        sampleSongs[2].title,
      );
      final loads = h.player.loads;
      await h.handler.skipToQueueItem(-1);
      await h.handler.skipToQueueItem(99);
      expect(h.player.loads, loads);
    },
  );

  testWidgets(
    'Projection distinguishes loading, buffering, ready, completed and safe error',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await tester.pump();
      h.player.processing(ProcessingState.buffering);
      await tester.pump();
      expect(
        h.handler.playbackState.value.processingState,
        media.AudioProcessingState.buffering,
      );
      expect(h.handler.playbackState.value.bufferedPosition.inSeconds, 40);
      h.player.processing(ProcessingState.ready);
      await tester.pump();
      expect(
        h.handler.playbackState.value.processingState,
        media.AudioProcessingState.ready,
      );
      h.player.events.addError(
        StateError('https://private.test/song?token=private'),
      );
      await pumpPlaybackUi(tester);
      expect(h.container.read(playbackErrorProvider), isNotNull);
      expect(h.player.playing, isFalse);
      expect(
        h.handler.playbackState.value.processingState,
        media.AudioProcessingState.error,
      );
      expect(
        h.handler.playbackState.value.errorMessage,
        isNot(contains('private')),
      );
    },
  );

  testWidgets(
    'Shuffle/repeat mirror one source; unsupported modes do not invent behavior',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await h.handler.setShuffleMode(media.AudioServiceShuffleMode.all);
      await h.handler.setRepeatMode(media.AudioServiceRepeatMode.one);
      expect(h.player.shuffleOn, isTrue);
      expect(h.player.loop, LoopMode.one);
      expect(
        h.handler.playbackState.value.repeatMode,
        media.AudioServiceRepeatMode.one,
      );
      expect(h.container.read(repeatEnabledProvider), isTrue);
      await h.handler.setRepeatMode(media.AudioServiceRepeatMode.all);
      expect(h.player.loop, LoopMode.one);
      await h.handler.skipToNext();
      expect(h.container.read(currentSongIndexProvider), isNot(0));
      await h.handler.setRepeatMode(media.AudioServiceRepeatMode.none);
      expect(h.player.loop, LoopMode.off);
    },
  );

  testWidgets(
    'Duplicate queue occurrences and reorder use existing queue without audio reload',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.actions.playFrom([
        sampleSongs[0],
        sampleSongs[1],
        sampleSongs[0],
      ], 2);
      await tester.pump();
      expect(
        h.handler.queue.value.map((item) => item.id).toSet(),
        hasLength(3),
      );
      h.actions.reorderQueue(2, 0);
      expect(h.handler.playbackState.value.queueIndex, 0);
      expect(h.player.loads, 1);
      await h.handler.skipToNext();
      expect(h.container.read(currentSongIndexProvider), 1);
      expect(h.container.read(playbackQueueProvider)!.length, 3);
    },
  );

  testWidgets(
    'Duplicate completion events advance exactly once after media pause/resume',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await h.handler.pause();
      await h.handler.play();
      h.player.processing(ProcessingState.completed);
      h.player.processing(ProcessingState.completed);
      await pumpPlaybackUi(tester);
      expect(h.container.read(currentSongIndexProvider), 1);
      expect(h.songs.tickets, 2);
      expect(h.player.loads, 2);
    },
  );

  testWidgets(
    'Stop revokes pending load, clears queue/metadata and does not resume on reopen',
    (tester) async {
      final songs = Tickets()..pending = Completer<Map<String, dynamic>>();
      final h = Harness(repository: songs);
      addTearDown(h.close);
      await h.mount(tester);
      final loading = h.actions.playFrom(sampleSongs, 0);
      await tester.pump();
      expect(
        h.handler.playbackState.value.processingState,
        media.AudioProcessingState.loading,
      );
      await h.handler.stop();
      songs.pending!.complete({'url': sampleSongs.first.audioUrl});
      await loading;
      await pumpPlaybackUi(tester);
      expect(h.player.playing, isFalse);
      expect(h.player.loads, 0);
      expect(h.handler.mediaItem.value, isNull);
      expect(h.handler.queue.value, isEmpty);
      expect(h.container.read(hasSelectedSongProvider), isFalse);
      expect(h.focus.deactivations, 1);
    },
  );

  testWidgets(
    'Old account callbacks and artwork cannot touch a replacement binding',
    (tester) async {
      final stores = <DeferredArt>[];
      final bridge = SoundShareAudioHandler(
        artworkFactory: () {
          final store = DeferredArt();
          stores.add(store);
          return store;
        },
      );
      final a = Harness(bridge: bridge);
      final oldActions = a.actions;
      addTearDown(a.close);
      await a.mount(tester);
      await a.start();
      await tester.pump();
      a.container.dispose();
      final b = Harness(bridge: bridge);
      addTearDown(b.close);
      await b.mount(tester);
      await b.actions.playFrom([sampleSongs[2]], 0);
      await tester.pump();
      stores.first.pending.first.complete(
        Uri.parse('file:///cache/old-account.png'),
      );
      a.player.states.add(a.player.playerState);
      await oldActions.skip(1);
      await pumpPlaybackUi(tester);
      expect(bridge.mediaItem.value!.title, sampleSongs[2].title);
      expect(bridge.mediaItem.value!.artUri, isNull);
      expect(a.player.disposals, 1);
      expect(b.creations, 1);
      expect(stores.first.disposed, isTrue);
    },
  );

  testWidgets(
    'Only local artwork is published; duration and cover changes update metadata once',
    (tester) async {
      final art = DeferredArt();
      final bridge = SoundShareAudioHandler(artworkFactory: () => art);
      final h = Harness(bridge: bridge);
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await tester.pump();
      art.pending.first.complete(Uri.parse('file:///cache/cover.png'));
      await tester.pump();
      expect(bridge.mediaItem.value!.artUri!.scheme, 'file');
      await h.handler.seek(const Duration(seconds: 7));
      await tester.pump();
      expect(art.pending, hasLength(1));
      final metadata = jsonEncode({
        'item': bridge.mediaItem.value.toString(),
        'queue': bridge.queue.value.map((item) => item.toString()).toList(),
      });
      expect(metadata, isNot(contains(sampleSongs.first.audioUrl)));
      expect(metadata, isNot(contains(sampleSongs.first.artwork)));
      expect(metadata, isNot(contains('ticket-')));
      await bridge.skipToNext();
      await tester.pump();
      art.pending.last.complete(Uri.parse('https://private.test/signed-art'));
      await tester.pump();
      expect(bridge.mediaItem.value!.artUri, isNull);
    },
  );

  testWidgets(
    'Interruption/noisy pauses real playback and focus regain never overrides manual pause',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await tester.pump();
      expect(
        h.focus.configured!.androidAudioAttributes!.usage,
        AndroidAudioUsage.media,
      );
      for (final type in AudioInterruptionType.values) {
        await h.handler.play();
        h.focus.interruptions.add(AudioInterruptionEvent(true, type));
        await tester.pump();
        expect(h.player.playing, isFalse);
        h.focus.interruptions.add(AudioInterruptionEvent(false, type));
        await tester.pump();
        expect(h.player.playing, isFalse);
      }
      await h.handler.play();
      h.focus.noisy.add(null);
      await tester.pump();
      expect(h.player.playing, isFalse);
      expect(h.handler.playbackState.value.playing, isFalse);
    },
  );

  testWidgets(
    'One heartbeat source, no paused beats and media taps do not create tickets',
    (tester) async {
      final h = Harness();
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await tester.pump(const Duration(seconds: 16));
      expect(h.songs.beats, 1);
      await h.handler.pause();
      await tester.pump(const Duration(seconds: 30));
      expect(h.songs.beats, 1);
      await h.handler.play();
      await tester.pump(const Duration(seconds: 16));
      expect(h.songs.beats, 2);
      expect(h.songs.tickets, 1);
    },
  );

  for (final status in [401, 403, 404]) {
    testWidgets(
      'Heartbeat $status revokes foreground playback and private metadata',
      (tester) async {
        final h = Harness();
        addTearDown(h.close);
        await h.mount(tester);
        await h.start();
        h.songs.denied = status;
        await tester.pump(const Duration(seconds: 16));
        await pumpPlaybackUi(tester);
        expect(h.player.playing, isFalse);
        expect(h.handler.queue.value, isEmpty);
        expect(h.handler.mediaItem.value, isNull);
        expect(h.container.read(playbackErrorProvider), isNotNull);
      },
    );
  }

  testWidgets(
    'Expired URL seek refreshes through repository, retaining paused position and one ticket',
    (tester) async {
      final songs = Tickets()
        ..expiry = DateTime.now().subtract(const Duration(seconds: 1));
      final h = Harness(repository: songs);
      addTearDown(h.close);
      await h.mount(tester);
      await h.start();
      await h.handler.pause();
      songs.expiry = DateTime.now().add(const Duration(minutes: 5));
      await h.handler.seek(const Duration(seconds: 63));
      await tester.pump();
      expect(h.player.position.inSeconds, 63);
      expect(h.player.playing, isFalse);
      expect(songs.tickets, 2);
      expect(h.player.loads, 2);
      await h.handler.play();
      expect(h.player.position.inSeconds, 63);
      expect(songs.tickets, 2);
    },
  );

  testWidgets(
    'Failed cover returns local SoundShare logo and cache is removed on disposal',
    (tester) async {
      await tester.runAsync(() async {
        final directory = await Directory.systemTemp.createTemp(
          'soundshare-art-test-',
        );
        final store = NativeNotificationArtwork(
          directory: () async => directory,
          client: MockClient((_) async => http.Response('expired', 403)),
        );
        final uri = await store.resolve(
          'https://fixture.test/cover?signature=not-for-notification',
        );
        expect(uri?.scheme, 'file');
        final file = File.fromUri(uri!);
        expect(await file.length(), greaterThan(100));
        store.dispose();
        for (var i = 0; i < 10 && await file.exists(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(await file.exists(), isFalse);
        await directory.delete();
      });
    },
  );
}
