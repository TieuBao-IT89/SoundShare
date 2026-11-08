import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as audio;

import '../../features/home/domain/song.dart';
import 'media_artwork.dart';

/// Commands stay in PlaybackActions; this object never owns a second player.
class MediaCommands {
  const MediaCommands({
    required this.play,
    required this.pause,
    required this.stop,
    required this.seek,
    required this.skip,
    required this.playQueued,
    required this.repeat,
    required this.shuffle,
    required this.error,
  });
  final Future<void> Function() play, pause, stop, error;
  final Future<void> Function(Duration) seek;
  final Future<void> Function(int) skip, playQueued;
  final Future<void> Function(bool) repeat, shuffle;
}

class MediaProjection {
  const MediaProjection({
    this.songs = const [],
    this.index = 0,
    this.selected = false,
    this.loading = false,
    this.failed = false,
    this.repeat = false,
    this.shuffle = false,
  });
  final List<Song> songs;
  final int index;
  final bool selected, loading, failed, repeat, shuffle;
}

class _MediaBinding {
  _MediaBinding(this.player, this.commands, this.artwork);
  final audio.AudioPlayer player;
  final MediaCommands commands;
  MediaArtworkStore? artwork;
  final subscriptions = <StreamSubscription<dynamic>>[];
  MediaProjection projection = const MediaProjection();
  String? artworkKey;
  Uri? localArtwork;
  bool active = true;

  void dispose() {
    active = false;
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    subscriptions.clear();
    artwork?.dispose();
  }
}

/// One process-wide Android MediaSession, with a revocable account binding.
/// No Riverpod Ref, JWT, playback URL or persisted queue enters this handler.
class SoundShareAudioHandler extends BaseAudioHandler {
  SoundShareAudioHandler({this.artworkFactory});
  final MediaArtworkStore Function()? artworkFactory;
  _MediaBinding? _binding;
  int _generation = 0;
  Future<void> _retirement = Future.value();
  bool _retirementFailed = false;

  /// The next account may construct an idle Dart facade, but may not load its
  /// native decoder until the previous account's disposal completes.
  void retireEngine(Future<void> disposal) {
    _retirement = Future.wait([_retirement, disposal]).then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        _retirementFailed = true;
      },
    );
  }

  Future<void> waitForRetiredEngine() async {
    await _retirement;
    if (_retirementFailed) {
      throw StateError('Previous audio engine could not be released.');
    }
  }

  Object attach(audio.AudioPlayer player, MediaCommands commands) {
    _binding?.dispose();
    _clear();
    _generation++;
    final binding = _MediaBinding(player, commands, artworkFactory?.call());
    _binding = binding;
    void changed(dynamic _) {
      if (identical(_binding, binding) && binding.active) _publish(binding);
    }

    void failed(Object _, StackTrace _) {
      if (identical(_binding, binding) && binding.active) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            playing: false,
            errorCode: 1,
            errorMessage: 'Không thể phát bản thu. Hãy thử lại.',
          ),
        );
        unawaited(binding.commands.error());
      }
    }

    // Playback events include seeks and position discontinuities. Android
    // extrapolates position between events; no background position polling.
    binding.subscriptions.addAll([
      player.playerStateStream.listen(changed, onError: failed),
      player.playbackEventStream.listen(changed, onError: failed),
      player.durationStream.listen(changed, onError: failed),
      player.bufferedPositionStream.listen(changed, onError: failed),
      player.speedStream.listen(changed, onError: failed),
    ]);
    return binding;
  }

  void update(Object lease, MediaProjection projection) {
    final binding = _binding;
    if (binding == null || !identical(binding, lease) || !binding.active) {
      return;
    }
    binding.projection = projection;
    _publish(binding);
  }

  void detach(Object lease) {
    if (!identical(_binding, lease)) return;
    _binding!.dispose();
    _binding = null;
    _clear();
  }

  void _clear() {
    // audio_service 0.18's platform observer ignores null MediaItems. Replace
    // the last private metadata first, then expose null to Dart and go idle.
    // This is a neutral clearing record, never a playable queue entry.
    if (mediaItem.value != null) {
      mediaItem.add(
        const MediaItem(id: 'soundshare-idle', title: 'SoundShare'),
      );
    }
    mediaItem.add(null);
    queue.add(const []);
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }

  void _publish(_MediaBinding binding) {
    final projection = binding.projection;
    if (!projection.selected ||
        projection.songs.isEmpty ||
        projection.index < 0 ||
        projection.index >= projection.songs.length) {
      if (binding.artworkKey != null) {
        binding.artwork?.dispose();
        binding.artwork = null;
        binding.artworkKey = null;
        binding.localArtwork = null;
      }
      _clear();
      return;
    }
    final player = binding.player;
    final song = projection.songs[projection.index];
    final artworkKey = '${song.identity}\n${song.artwork}';
    if (binding.artworkKey != artworkKey) {
      binding.artworkKey = artworkKey;
      binding.localArtwork = null;
      binding.artwork ??= artworkFactory?.call();
      final resolver = binding.artwork;
      if (resolver != null) {
        unawaited(
          resolver
              .resolve(song.artwork)
              .then((uri) {
                if (!binding.active ||
                    !identical(_binding, binding) ||
                    binding.artworkKey != artworkKey) {
                  return;
                }
                // Remote URLs must never be forwarded, even by a custom resolver.
                binding.localArtwork = uri?.scheme == 'file' ? uri : null;
                _publish(binding);
              })
              .catchError((Object _) {
                /* Artwork cannot interrupt playback. */
              }),
        );
      }
    }
    final items = [
      for (var i = 0; i < projection.songs.length; i++)
        MediaItem(
          // Queue occurrences, including duplicate tracks, have distinct IDs.
          id: 'queue-$_generation-$i',
          title: projection.songs[i].title,
          artist: projection.songs[i].artist,
          artUri: i == projection.index ? binding.localArtwork : null,
          duration: i == projection.index && !projection.loading
              ? player.duration
              : null,
        ),
    ];
    // Subjects suppress equal data, avoiding artwork reloads for position ticks.
    if (!_sameItems(queue.value, items)) queue.add(items);
    if (!_sameItem(mediaItem.value, items[projection.index])) {
      mediaItem.add(items[projection.index]);
    }
    final phase = projection.failed
        ? AudioProcessingState.error
        : projection.loading
        ? AudioProcessingState.loading
        : switch (player.processingState) {
            audio.ProcessingState.idle => AudioProcessingState.idle,
            audio.ProcessingState.loading => AudioProcessingState.loading,
            audio.ProcessingState.buffering => AudioProcessingState.buffering,
            audio.ProcessingState.ready => AudioProcessingState.ready,
            audio.ProcessingState.completed => AudioProcessingState.completed,
          };
    final playing =
        player.playing &&
        !projection.failed &&
        phase != AudioProcessingState.completed &&
        phase != AudioProcessingState.idle;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        systemActions: const {
          MediaAction.seek,
          MediaAction.skipToQueueItem,
          MediaAction.setRepeatMode,
          MediaAction.setShuffleMode,
        },
        processingState: phase,
        playing: playing,
        updatePosition: projection.loading ? Duration.zero : player.position,
        bufferedPosition: projection.loading
            ? Duration.zero
            : player.bufferedPosition,
        speed: player.speed,
        queueIndex: projection.index,
        repeatMode: projection.repeat
            ? AudioServiceRepeatMode.one
            : AudioServiceRepeatMode.none,
        shuffleMode: projection.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        errorCode: projection.failed ? 1 : null,
        errorMessage: projection.failed
            ? 'Không thể phát bản thu. Hãy thử lại.'
            : null,
      ),
    );
  }

  bool _sameItems(List<MediaItem> a, List<MediaItem> b) =>
      a.length == b.length &&
      List.generate(
        a.length,
        (i) => _sameItem(a[i], b[i]),
      ).every((same) => same);

  bool _sameItem(MediaItem? a, MediaItem b) =>
      a != null &&
      a.id == b.id &&
      a.title == b.title &&
      a.artist == b.artist &&
      a.duration == b.duration &&
      a.artUri == b.artUri;

  Future<void> _command(Future<void> Function(MediaCommands) invoke) async {
    final binding = _binding;
    if (binding == null || !binding.active) return;
    await invoke(binding.commands);
  }

  @override
  Future<void> play() => _command((target) => target.play());
  @override
  Future<void> pause() => _command((target) => target.pause());
  @override
  Future<void> stop() => _command((target) => target.stop());
  @override
  Future<void> seek(Duration position) =>
      _command((target) => target.seek(position));
  @override
  Future<void> skipToNext() => _command((target) => target.skip(1));
  @override
  Future<void> skipToPrevious() => _command((target) => target.skip(-1));
  @override
  Future<void> skipToQueueItem(int index) {
    if (index < 0 || index >= queue.value.length) return Future.value();
    return _command((target) => target.playQueued(index));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    if (repeatMode != AudioServiceRepeatMode.none &&
        repeatMode != AudioServiceRepeatMode.one) {
      return;
    }
    await _command(
      (target) => target.repeat(repeatMode == AudioServiceRepeatMode.one),
    );
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode != AudioServiceShuffleMode.none &&
        shuffleMode != AudioServiceShuffleMode.all) {
      return;
    }
    await _command(
      (target) => target.shuffle(shuffleMode == AudioServiceShuffleMode.all),
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!playbackState.value.playing) await stop();
  }
}
