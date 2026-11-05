import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';

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

final currentSongProvider = Provider<Song?>((ref) {
  final songs = ref.watch(catalogProvider).valueOrNull ?? const <Song>[];
  final selected = ref.watch(selectedSongProvider);
  if (selected != null) {
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
    if (selected == null || songs == null) return;
    final index = songs.indexWhere(
      (song) => song.identity == selected.identity,
    );
    if (index >= 0) ref.read(currentSongIndexProvider.notifier).state = index;
  });
  ref.onDispose(() => actions._disposed = true);
  return actions;
});

class PlaybackActions {
  PlaybackActions(this.ref);
  final Ref ref;
  String? _loadedId;
  DateTime? _loadedAt;
  int _request = 0;
  bool _disposed = false;

  void _error(int request) {
    if (_disposed || request != _request) return;
    ref.read(playbackLoadingProvider.notifier).state = false;
    ref.read(playbackErrorProvider.notifier).state =
        'Audio could not be loaded. Check your connection and try again.';
  }

  Future<void> play(int index) async {
    final songs = ref.read(catalogProvider).asData?.value ?? const <Song>[];
    if (songs.isEmpty) return;
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
            : Duration.zero;
        final url = await ref.read(songRepositoryProvider).playback(song);
        if (_disposed || request != _request) return;
        await player.setUrl(url, initialPosition: resumeAt);
        if (_disposed || request != _request) return;
        _loadedId = song.identity;
        _loadedAt = DateTime.now();
      }
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      if (_disposed || request != _request) return;
      ref.read(playbackLoadingProvider.notifier).state = false;
      unawaited(player.play().catchError((Object _) => _error(request)));
    } catch (_) {
      _loadedId = null;
      _error(request);
    }
  }

  Future<void> togglePlayback() async {
    final player = ref.read(audioPlayerProvider);
    if (!player.playing) return play(ref.read(currentSongIndexProvider));
    try {
      await player.pause();
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
    final count = ref.read(catalogProvider).asData?.value.length ?? 0;
    if (count == 0) return;
    final current = ref.read(currentSongIndexProvider) % count;
    final next = ref.read(shuffleEnabledProvider) && count > 1
        ? (current + 1 + Random().nextInt(count - 1)) % count
        : (current + direction) % count;
    await play(next);
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
