import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';
import '../../features/community/application/community_providers.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
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
  final actions = PlaybackActions(ref);
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
    actions._heartbeat?.cancel();
    unawaited(actions._completion?.cancel());
  });
  return actions;
});

class PlaybackActions {
  PlaybackActions(this.ref);
  final Ref ref;
  String? _loadedId;
  DateTime? _loadedAt;
  int _request = 0;
  int _sourceGeneration = 0;
  bool _disposed = false;
  Timer? _heartbeat;
  StreamSubscription<PlayerState>? _completion;
  String? _playSessionId;
  bool _sendingHeartbeat = false;
  bool _validReported = false;
  bool _pauseRequested = false;

  Future<void> playFrom(List<Song> songs, int index) async {
    if (songs.isEmpty) return;
    ref.read(playbackQueueProvider.notifier).state = List.unmodifiable(songs);
    await _play(songs, index);
  }

  void addToQueue(Song song) {
    final songs =
        ref.read(playbackQueueProvider) ??
        ref.read(catalogProvider).valueOrNull ??
        <Song>[];
    ref.read(playbackQueueProvider.notifier).state = [...songs, song];
  }

  void removeFromQueue(int index) {
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

  Future<void> playQueued(int index) => _play(
    ref.read(playbackQueueProvider) ??
        ref.read(catalogProvider).valueOrNull ??
        [],
    index,
  );

  Future<void> _sendHeartbeat({bool completed = false}) async {
    if (_disposed || _playSessionId == null || _sendingHeartbeat) return;
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
    final songs = ref.read(catalogProvider).asData?.value ?? const <Song>[];
    ref.read(playbackQueueProvider.notifier).state = null;
    await _play(songs, index);
  }

  Future<void> _play(List<Song> songs, int index) async {
    if (songs.isEmpty) return;
    _pauseRequested = false;
    final selected = index % songs.length;
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
      if (_loadedId != song.identity ||
          player.audioSource == null ||
          retry ||
          (_loadedAt != null &&
              DateTime.now().difference(_loadedAt!) >
                  const Duration(minutes: 4))) {
        final resumeAt = _loadedId == song.identity
            ? player.position
            : Duration(milliseconds: song.resumePositionMs);
        final sourceGeneration = ++_sourceGeneration;
        _heartbeat?.cancel();
        unawaited(_completion?.cancel());
        _playSessionId = null;
        _validReported = false;
        final info = await ref.read(songRepositoryProvider).playbackInfo(song);
        if (_disposed || request != _request) return;
        await player.setUrl(info['url'] as String, initialPosition: resumeAt);
        if (_disposed || request != _request) return;
        _loadedId = song.identity;
        _loadedAt = DateTime.now();
        _playSessionId = info['playSessionId'] as String?;
        _completion = player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed &&
              !_disposed &&
              sourceGeneration == _sourceGeneration) {
            unawaited(_sendHeartbeat(completed: true));
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
      if (_disposed || request != _request) return;
      ref.read(playbackLoadingProvider.notifier).state = false;
      if (!_pauseRequested) {
        unawaited(player.play().catchError((Object _) => _error(request)));
      }
    } catch (_) {
      _loadedId = null;
      _error(request);
    }
  }

  Future<void> togglePlayback() async {
    final player = ref.read(audioPlayerProvider);
    if (!player.playing ||
        player.processingState == ProcessingState.completed) {
      return playQueued(ref.read(currentSongIndexProvider));
    }
    await pause();
  }

  Future<void> pause() async {
    // A sleep deadline may occur while a signed URL or decoder is loading.
    // Remember that intent so the outstanding request cannot start audio later.
    _pauseRequested = true;
    try {
      unawaited(_sendHeartbeat());
      await ref.read(audioPlayerProvider).pause();
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await ref.read(audioPlayerProvider).seek(position);
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> skip(int direction) async {
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
    final enabled = !ref.read(shuffleEnabledProvider);
    try {
      await ref.read(audioPlayerProvider).setShuffleModeEnabled(enabled);
      if (!_disposed) ref.read(shuffleEnabledProvider.notifier).state = enabled;
    } catch (_) {
      _error(_request);
    }
  }

  Future<void> toggleRepeat() async {
    final enabled = !ref.read(repeatEnabledProvider);
    try {
      await ref
          .read(audioPlayerProvider)
          .setLoopMode(enabled ? LoopMode.one : LoopMode.off);
      if (!_disposed) ref.read(repeatEnabledProvider.notifier).state = enabled;
    } catch (_) {
      _error(_request);
    }
  }
}
