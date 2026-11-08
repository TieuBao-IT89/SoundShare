import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';
import '../../features/community/application/community_providers.dart';
import 'api_client.dart';
import 'media_session.dart';
import 'native_audio_runtime.dart';
import 'music_audio_focus.dart';

final musicAudioSessionProvider = Provider<Future<AudioSession>>(
  (ref) => AudioSession.instance,
);

final audioPlayerFactoryProvider = Provider<AudioPlayer Function(bool)>(
  (ref) =>
      (handleInterruptions) =>
          AudioPlayer(handleInterruptions: handleInterruptions),
);

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final handler = ref.watch(nativeAudioHandlerProvider);
  final player = ref.read(audioPlayerFactoryProvider)(handler == null);
  ref.onDispose(() {
    final disposal = player.dispose();
    if (handler != null) {
      handler.retireEngine(disposal);
    } else {
      unawaited(disposal);
    }
  });
  return player;
});

final currentSongIndexProvider = StateProvider<int>((ref) => 0);
final selectedSongProvider = StateProvider<Song?>((ref) => null);
final hasSelectedSongProvider = StateProvider<bool>((ref) => false);
final playbackLoadingProvider = StateProvider<bool>((ref) => false);
final playbackErrorProvider = StateProvider<String?>((ref) => null);
final shuffleEnabledProvider = StateProvider<bool>((ref) => false);
final repeatEnabledProvider = StateProvider<bool>((ref) => false);
final playbackQueueProvider = StateProvider<List<Song>?>((ref) => null);

final currentSongProvider = Provider<Song?>((ref) {
  final songs = ref.watch(catalogProvider).valueOrNull ?? const <Song>[];
  final selected = ref.watch(selectedSongProvider);
  if (selected != null) {
    if (selected.community) return selected;
    for (final song in songs) {
      if (song.identity == selected.identity) return song;
    }
    return selected;
  }
  if (songs.isEmpty) return null;
  return songs[ref.watch(currentSongIndexProvider) % songs.length];
});

final playbackActionsProvider = Provider<PlaybackActions>((ref) {
  final player = ref.watch(audioPlayerProvider);
  final handler = ref.watch(nativeAudioHandlerProvider);
  final actions = PlaybackActions(ref);
  Object? lease;
  void project() {
    if (lease == null || actions._disposed) return;
    handler!.update(
      lease,
      MediaProjection(
        songs:
            ref.read(playbackQueueProvider) ??
            ref.read(catalogProvider).valueOrNull ??
            [],
        index: ref.read(currentSongIndexProvider),
        selected: ref.read(hasSelectedSongProvider),
        loading: ref.read(playbackLoadingProvider),
        failed: ref.read(playbackErrorProvider) != null,
        repeat: ref.read(repeatEnabledProvider),
        shuffle: ref.read(shuffleEnabledProvider),
      ),
    );
  }

  if (handler != null) {
    lease = handler.attach(
      player,
      MediaCommands(
        play: () => actions.playQueued(
          actions._disposed ? 0 : ref.read(currentSongIndexProvider),
        ),
        pause: actions.pause,
        stop: actions.stop,
        seek: actions.seek,
        skip: actions.skip,
        playQueued: actions.playQueued,
        repeat: actions.setRepeat,
        shuffle: actions.setShuffle,
        error: actions.fail,
      ),
    );
    ref.listen(playbackQueueProvider, (_, _) => project());
    ref.listen(currentSongIndexProvider, (_, _) => project());
    ref.listen(hasSelectedSongProvider, (_, _) => project());
    ref.listen(playbackLoadingProvider, (_, _) => project());
    ref.listen(playbackErrorProvider, (_, _) => project());
    ref.listen(repeatEnabledProvider, (_, _) => project());
    ref.listen(shuffleEnabledProvider, (_, _) => project());
    ref.listen(catalogProvider, (_, _) => project());
    project();
  }
  ref.listen(catalogProvider, (_, next) {
    final selected = ref.read(selectedSongProvider);
    final songs = next.asData?.value;
    if (selected == null ||
        songs == null ||
        ref.read(playbackQueueProvider) != null) {
      return;
    }
    final index = songs.indexWhere(
      (song) => song.identity == selected.identity,
    );
    if (index >= 0) ref.read(currentSongIndexProvider.notifier).state = index;
  });
  ref.onDispose(() {
    actions._disposed = true;
    if (lease != null) handler!.detach(lease);
    final focusDisposal = actions._focus?.dispose();
    if (focusDisposal != null) handler!.retireEngine(focusDisposal);
    actions._heartbeat?.cancel();
    actions._leavePreview();
    unawaited(actions._completion?.cancel());
  });
  return actions;
});

class PlaybackActions {
  PlaybackActions(this.ref);
  final Ref ref;
  String? _loadedId;
  DateTime? _loadedAt;
  DateTime? _expiresAt;
  MusicAudioFocus? _focus;
  int _request = 0;
  int _sourceGeneration = 0;
  bool _disposed = false;
  Timer? _heartbeat;
  StreamSubscription<PlayerState>? _completion;
  String? _playSessionId;
  bool _sendingHeartbeat = false;
  bool _validReported = false;
  bool _pauseRequested = false;
  PreviewContext? _preview;
  StreamSubscription<Duration>? _previewPosition;
  int _previewRequest = 0;

  /// A reversible, account-local lease over the existing audio engine.
  PreviewContext beginPreview() {
    if (_disposed) throw StateError('Playback session has ended');
    _leavePreview();
    final player = ref.read(audioPlayerProvider);
    final context = PreviewContext(
      ref.read(playbackQueueProvider),
      ref.read(catalogProvider).valueOrNull ?? const [],
      ref.read(currentSongIndexProvider),
      ref.read(hasSelectedSongProvider),
      player.position,
      ref.read(repeatEnabledProvider),
      ref.read(shuffleEnabledProvider),
    );
    _preview = context;
    ++_request;
    unawaited(pause());
    return context;
  }

  void _leavePreview() {
    ++_previewRequest;
    _preview?.active = false;
    _preview = null;
    unawaited(_previewPosition?.cancel());
    _previewPosition = null;
  }

  Future<void> preview(PreviewContext context, Song song) async {
    if (_disposed || !context.active || _preview != context) return;
    final ticket = ++_previewRequest;
    ++_request;
    await pause(previewTransition: true);
    if (_disposed ||
        !context.active ||
        _preview != context ||
        ticket != _previewRequest) {
      return;
    }
    await setRepeat(false);
    await setShuffle(false);
    if (_disposed ||
        !context.active ||
        _preview != context ||
        ticket != _previewRequest) {
      return;
    }
    ref.read(playbackQueueProvider.notifier).state = [song];
    context.song = song;
    unawaited(_previewPosition?.cancel());
    await _play([song], 0, position: Duration.zero);
    if (_disposed ||
        !context.active ||
        _preview != context ||
        ticket != _previewRequest) {
      return;
    }
    var ended = false;
    final actualDuration = ref
        .read(audioPlayerProvider)
        .duration
        ?.inMilliseconds;
    final limit = max(
      1,
      actualDuration == null
          ? song.previewDurationMs
          : min(song.previewDurationMs, actualDuration),
    );
    context.limitMs = limit;
    void finishPreview() {
      if (ended || !context.active || _preview != context) return;
      ended = true;
      final player = ref.read(audioPlayerProvider);
      final wasPlaying = player.playing;
      if (wasPlaying) {
        unawaited(
          _sendHeartbeat(
            completed: player.processingState == ProcessingState.completed,
          ),
        );
      }
      unawaited(pause());
      if (wasPlaying) context.onEnd?.call();
    }

    context.onCompleted = finishPreview;
    _previewPosition = ref.read(audioPlayerProvider).positionStream.listen((
      position,
    ) {
      if (position < Duration(milliseconds: limit)) {
        ended = false;
      }
      if (!ended &&
          context.active &&
          _preview == context &&
          position >= Duration(milliseconds: limit)) {
        finishPreview();
      }
    });
  }

  Future<void> restorePreview(PreviewContext context) async {
    if (_disposed || !context.active || _preview != context) return;
    _leavePreview();
    final restoreRequest = _request;
    await pause();
    if (_disposed || _request != restoreRequest) return;
    if (!context.selected) {
      await stop();
      return;
    }
    final queue = context.queue ?? context.catalog;
    ref.read(playbackQueueProvider.notifier).state = context.queue;
    await _play(
      queue,
      context.index,
      autoPlay: false,
      position: context.position,
    );
    if (_disposed || _request != restoreRequest + 1) return;
    await setRepeat(context.repeat);
    await setShuffle(context.shuffle);
  }

  Future<void> playFrom(List<Song> songs, int index) async {
    if (_disposed || songs.isEmpty) return;
    _leavePreview();
    ref.read(playbackQueueProvider.notifier).state = List.unmodifiable(songs);
    await _play(songs, index);
  }

  void addToQueue(Song song) {
    if (_disposed) return;
    final songs =
        ref.read(playbackQueueProvider) ??
        ref.read(catalogProvider).valueOrNull ??
        <Song>[];
    ref.read(playbackQueueProvider.notifier).state = [...songs, song];
  }

  void removeFromQueue(int index) {
    if (_disposed) return;
    final songs =
        ref.read(playbackQueueProvider) ??
        ref.read(catalogProvider).valueOrNull;
    if (songs == null ||
        index < 0 ||
        index >= songs.length ||
        index == ref.read(currentSongIndexProvider)) {
      return;
    }
    ref.read(playbackQueueProvider.notifier).state = [...songs]
      ..removeAt(index);
    if (index < ref.read(currentSongIndexProvider)) {
      ref.read(currentSongIndexProvider.notifier).state--;
    }
  }

  /// Reorder the explicit queue without reloading or restarting current audio.
  /// newIndex is the final position, matching onReorderItem's convention.
  void reorderQueue(int oldIndex, int newIndex) {
    if (_disposed) return;
    final source =
        ref.read(playbackQueueProvider) ??
        ref.read(catalogProvider).valueOrNull ??
        const <Song>[];
    if (oldIndex < 0 ||
        oldIndex >= source.length ||
        newIndex < 0 ||
        newIndex >= source.length) {
      return;
    }
    if (oldIndex == newIndex) return;
    final queue = [...source];
    queue.insert(newIndex, queue.removeAt(oldIndex));
    final current = ref.read(currentSongIndexProvider);
    final nextCurrent = current == oldIndex
        ? newIndex
        : oldIndex < current && newIndex >= current
        ? current - 1
        : oldIndex > current && newIndex <= current
        ? current + 1
        : current;
    ref.read(playbackQueueProvider.notifier).state = List.unmodifiable(queue);
    ref.read(currentSongIndexProvider.notifier).state = nextCurrent;
  }

  Future<void> playQueued(int index) {
    if (_disposed) return Future.value();
    final previewContext = _preview;
    final previewSong = previewContext?.song;
    if (previewContext != null &&
        previewSong != null &&
        ref.read(audioPlayerProvider).position >=
            Duration(
              milliseconds:
                  previewContext.limitMs ?? previewSong.previewDurationMs,
            )) {
      return preview(previewContext, previewSong);
    }
    return _play(
      ref.read(playbackQueueProvider) ??
          ref.read(catalogProvider).valueOrNull ??
          [],
      index,
    );
  }

  Future<void> _sendHeartbeat({bool completed = false}) async {
    if (_disposed ||
        _pauseRequested ||
        _playSessionId == null ||
        _sendingHeartbeat) {
      return;
    }
    final player = ref.read(audioPlayerProvider);
    if ((!player.playing || player.processingState != ProcessingState.ready) &&
        !(completed && player.processingState == ProcessingState.completed)) {
      return;
    }
    _sendingHeartbeat = true;
    final sessionId = _playSessionId!;
    try {
      final valid = await ref
          .read(songRepositoryProvider)
          .heartbeat(sessionId, player.position.inMilliseconds, true);
      if (valid &&
          !_validReported &&
          !_disposed &&
          sessionId == _playSessionId) {
        _validReported = true;
        ref.invalidate(communitySongsProvider);
        ref.invalidate(communityHomeProvider);
      }
    } on ApiException catch (error) {
      if (!_disposed &&
          sessionId == _playSessionId &&
          (error.status == 401 || error.status == 403 || error.status == 404)) {
        await stop();
        _error(_request);
      }
      // Transient tracking/network failures never interrupt audio.
    } catch (_) {
      /* Tracking failure never interrupts audio. */
    } finally {
      _sendingHeartbeat = false;
    }
  }

  void _error(int request) {
    if (_disposed || request != _request) return;
    ref.read(playbackLoadingProvider.notifier).state = false;
    ref.read(playbackErrorProvider.notifier).state =
        'Audio could not be loaded. Check your connection and try again.';
  }

  Future<void> play(int index) async {
    if (_disposed) return;
    _leavePreview();
    final songs = ref.read(catalogProvider).asData?.value ?? const <Song>[];
    ref.read(playbackQueueProvider.notifier).state = null;
    await _play(songs, index);
  }

  bool get _urlStale => _expiresAt != null
      ? !DateTime.now().isBefore(
          _expiresAt!.subtract(const Duration(seconds: 30)),
        )
      : _loadedAt != null &&
            DateTime.now().difference(_loadedAt!) > const Duration(minutes: 4);

  Future<void> _play(
    List<Song> songs,
    int index, {
    bool autoPlay = true,
    Duration? position,
  }) async {
    if (_disposed || songs.isEmpty || index < 0 || index >= songs.length) {
      return;
    }
    _pauseRequested = !autoPlay;
    final selected = index;
    final song = songs[selected];
    final retry = ref.read(playbackErrorProvider) != null;
    final request = ++_request;
    final player = ref.read(audioPlayerProvider);
    ref.read(currentSongIndexProvider.notifier).state = selected;
    ref.read(selectedSongProvider.notifier).state = song;
    ref.read(hasSelectedSongProvider.notifier).state = true;
    ref.read(playbackLoadingProvider.notifier).state = true;
    ref.read(playbackErrorProvider.notifier).state = null;
    try {
      final handler = ref.read(nativeAudioHandlerProvider);
      if (handler != null) {
        await handler.waitForRetiredEngine();
        if (_disposed || request != _request) return;
        _focus ??= MusicAudioFocus(
          pause: pause,
          session: ref.read(musicAudioSessionProvider),
        );
        await _focus!.ready;
        if (_disposed || request != _request) return;
      }
      if (_loadedId != song.identity ||
          player.audioSource == null ||
          retry ||
          _urlStale) {
        final resumeAt =
            position ??
            (_loadedId == song.identity
                ? player.position
                : Duration(milliseconds: song.resumePositionMs));
        final sourceGeneration = ++_sourceGeneration;
        _heartbeat?.cancel();
        unawaited(_completion?.cancel());
        _playSessionId = null;
        _validReported = false;
        await player.pause();
        if (_disposed || request != _request) return;
        final info = await ref.read(songRepositoryProvider).playbackInfo(song);
        if (_disposed || request != _request) return;
        await player.setUrl(info['url'] as String, initialPosition: resumeAt);
        if (_disposed || request != _request) return;
        _loadedId = song.identity;
        _loadedAt = DateTime.now();
        _expiresAt = DateTime.tryParse(info['expiresAt']?.toString() ?? '');
        _playSessionId = info['playSessionId'] as String?;
        var completionHandled = false;
        _completion = player.playerStateStream.listen((state) {
          if (state.processingState != ProcessingState.completed) {
            completionHandled = false;
          }
          if (state.processingState == ProcessingState.completed &&
              !completionHandled &&
              !_disposed &&
              sourceGeneration == _sourceGeneration) {
            completionHandled = true;
            unawaited(_sendHeartbeat(completed: true));
            if (_preview?.active == true) {
              _preview?.onCompleted?.call();
              return;
            }
            final queue = ref.read(playbackQueueProvider);
            if (queue != null &&
                state.playing &&
                !_pauseRequested &&
                !ref.read(repeatEnabledProvider)) {
              final current = ref.read(currentSongIndexProvider);
              if (ref.read(shuffleEnabledProvider) && queue.length > 1) {
                unawaited(skip(1));
              } else if (current + 1 < queue.length) {
                unawaited(playQueued(current + 1));
              }
            }
          }
        });
        if (_playSessionId != null) {
          _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
            unawaited(_sendHeartbeat());
          });
        }
      }
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      if (position != null && !_disposed && request == _request) {
        await player.seek(position);
      }
      if (_disposed || request != _request) return;
      ref.read(playbackLoadingProvider.notifier).state = false;
      if (!_pauseRequested) {
        unawaited(player.play().catchError((Object _) => _error(request)));
      }
    } catch (error) {
      if (_disposed || request != _request) return;
      _loadedId = null;
      if (error is ApiException &&
          (error.status == 401 || error.status == 403 || error.status == 404)) {
        await stop();
        _error(_request);
      } else {
        _error(request);
      }
    }
  }

  Future<void> togglePlayback() async {
    if (_disposed) return;
    final player = ref.read(audioPlayerProvider);
    if (!player.playing ||
        player.processingState == ProcessingState.completed) {
      return playQueued(ref.read(currentSongIndexProvider));
    }
    await pause();
  }

  Future<void> pause({bool previewTransition = false}) async {
    if (_disposed) return;
    if (!previewTransition) ++_previewRequest;
    // A sleep deadline may occur while a signed URL or decoder is loading.
    // Remember that intent so the outstanding request cannot start audio later.
    _pauseRequested = true;
    try {
      await ref.read(audioPlayerProvider).pause();
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> seek(Duration position) async {
    if (_disposed || !ref.read(hasSelectedSongProvider)) return;
    try {
      final player = ref.read(audioPlayerProvider);
      final safePosition = position < Duration.zero ? Duration.zero : position;
      if (_urlStale) {
        await _play(
          ref.read(playbackQueueProvider) ??
              ref.read(catalogProvider).valueOrNull ??
              [],
          ref.read(currentSongIndexProvider),
          autoPlay: player.playing,
          position: safePosition,
        );
      } else {
        await player.seek(safePosition);
      }
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> skip(int direction) async {
    if (_disposed) return;
    if (_preview != null) {
      await pause();
      return;
    }
    final count =
        (ref.read(playbackQueueProvider) ??
                ref.read(catalogProvider).asData?.value)
            ?.length ??
        0;
    if (count == 0) return;
    final current = ref.read(currentSongIndexProvider) % count;
    final next = ref.read(shuffleEnabledProvider) && count > 1
        ? (current + 1 + Random().nextInt(count - 1)) % count
        : (current + direction) % count;
    await playQueued(next);
  }

  Future<void> toggleShuffle() async {
    if (_disposed) return;
    await setShuffle(!ref.read(shuffleEnabledProvider));
  }

  Future<void> setShuffle(bool enabled) async {
    if (_disposed) return;
    try {
      await ref.read(audioPlayerProvider).setShuffleModeEnabled(enabled);
      if (!_disposed) ref.read(shuffleEnabledProvider.notifier).state = enabled;
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> toggleRepeat() async {
    if (_disposed) return;
    await setRepeat(!ref.read(repeatEnabledProvider));
  }

  Future<void> setRepeat(bool enabled) async {
    if (_disposed) return;
    try {
      await ref
          .read(audioPlayerProvider)
          .setLoopMode(enabled ? LoopMode.one : LoopMode.off);
      if (!_disposed) ref.read(repeatEnabledProvider.notifier).state = enabled;
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> fail() async {
    if (_disposed || ref.read(playbackErrorProvider) != null) return;
    _loadedId = null;
    _error(_request);
    await pause();
  }

  Future<void> stop() async {
    if (_disposed) return;
    _leavePreview();
    final stopRequest = ++_request;
    ++_sourceGeneration;
    _pauseRequested = true;
    _loadedId = null;
    _loadedAt = null;
    _expiresAt = null;
    _playSessionId = null;
    _validReported = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    unawaited(_completion?.cancel());
    _completion = null;
    ref.read(hasSelectedSongProvider.notifier).state = false;
    ref.read(playbackQueueProvider.notifier).state = null;
    ref.read(selectedSongProvider.notifier).state = null;
    ref.read(currentSongIndexProvider.notifier).state = 0;
    ref.read(playbackLoadingProvider.notifier).state = false;
    ref.read(playbackErrorProvider.notifier).state = null;
    ref.read(shuffleEnabledProvider.notifier).state = false;
    ref.read(repeatEnabledProvider.notifier).state = false;
    try {
      final player = ref.read(audioPlayerProvider);
      await player.stop();
      if (!_disposed && stopRequest == _request) {
        await _focus?.deactivate();
        if (_disposed || stopRequest != _request) return;
        await player.setLoopMode(LoopMode.off);
        if (!_disposed && stopRequest == _request) {
          await player.setShuffleModeEnabled(false);
        }
      }
    } catch (_) {
      if (stopRequest == _request) _error(stopRequest);
    }
  }
}

class PreviewContext {
  PreviewContext(
    this.queue,
    this.catalog,
    this.index,
    this.selected,
    this.position,
    this.repeat,
    this.shuffle,
  );
  final List<Song>? queue;
  final List<Song> catalog;
  final int index;
  final bool selected, repeat, shuffle;
  final Duration position;
  bool active = true;
  void Function()? onEnd;
  Song? song;
  int? limitMs;
  void Function()? onCompleted;
}
