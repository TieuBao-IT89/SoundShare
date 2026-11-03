import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../home/domain/song.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});
  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool favorite = false;
  bool shuffle = false;
  LoopMode loopMode = LoopMode.off;
  bool loading = false;
  String? playbackError;

  Future<void> _play(Song song) async {
    final player = ref.read(audioPlayerProvider);
    setState(() {
      loading = true;
      playbackError = null;
    });
    try {
      await player.setUrl(song.audioUrl);
      unawaited(player.play());
    } catch (_) {
      if (mounted) {
        setState(
          () => playbackError =
              'Could not load audio. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(currentSongIndexProvider);
    final song = sampleSongs[index % sampleSongs.length];
    final player = ref.watch(audioPlayerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        centerTitle: true,
        title: const Text(
          'SAMPLE TRACK',
          style: TextStyle(fontSize: 11, letterSpacing: 1.8),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - 56;
            final artworkSize = math.min(availableWidth, 340.0);
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Artwork(
                        url: song.artwork,
                        size: artworkSize,
                        radius: 26,
                        semanticLabel: 'Artwork for ${song.title}',
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  song.artist,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: favorite
                                ? 'Remove from liked songs'
                                : 'Like song',
                            onPressed: () =>
                                setState(() => favorite = !favorite),
                            icon: Icon(
                              favorite ? Icons.favorite : Icons.favorite_border,
                              color: favorite
                                  ? AppColors.violet
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<Duration?>(
                        stream: player.durationStream,
                        builder: (context, durationSnap) {
                          final duration = durationSnap.data ?? Duration.zero;
                          return StreamBuilder<Duration>(
                            stream: player.positionStream,
                            builder: (context, positionSnap) {
                              final position =
                                  positionSnap.data ?? Duration.zero;
                              final max = duration.inMilliseconds.toDouble();
                              final value = max == 0
                                  ? 0.0
                                  : position.inMilliseconds
                                        .clamp(0, duration.inMilliseconds)
                                        .toDouble();
                              return Column(
                                children: [
                                  Slider(
                                    value: value,
                                    max: max == 0 ? 1 : max,
                                    onChanged: max == 0
                                        ? null
                                        : (v) => player.seek(
                                            Duration(milliseconds: v.round()),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _time(position),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          duration == Duration.zero
                                              ? song.duration
                                              : _time(duration),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      if (playbackError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: [
                              Text(
                                playbackError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                              TextButton(
                                onPressed: loading ? null : () => _play(song),
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: shuffle
                                ? 'Turn shuffle off'
                                : 'Turn shuffle on',
                            onPressed: () {
                              final enabled = !shuffle;
                              setState(() => shuffle = enabled);
                              player.setShuffleModeEnabled(enabled);
                            },
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: shuffle
                                  ? AppColors.violet
                                  : AppColors.muted,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Play previous track',
                            onPressed: () {
                              final next =
                                  (index - 1 + sampleSongs.length) %
                                  sampleSongs.length;
                              ref
                                      .read(currentSongIndexProvider.notifier)
                                      .state =
                                  next;
                              _play(sampleSongs[next]);
                            },
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 36,
                            ),
                          ),
                          StreamBuilder<PlayerState>(
                            stream: player.playerStateStream,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              return FilledButton(
                                onPressed: loading
                                    ? null
                                    : () async {
                                        if (playing) {
                                          await player.pause();
                                          return;
                                        }
                                        try {
                                          unawaited(player.play());
                                        } catch (_) {
                                          await _play(song);
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(18),
                                  backgroundColor: AppColors.violet,
                                ),
                                child: loading
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 32,
                                      ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Play next track',
                            onPressed: () {
                              final next = (index + 1) % sampleSongs.length;
                              ref
                                      .read(currentSongIndexProvider.notifier)
                                      .state =
                                  next;
                              _play(sampleSongs[next]);
                            },
                            icon: const Icon(Icons.skip_next_rounded, size: 36),
                          ),
                          IconButton(
                            tooltip: loopMode == LoopMode.one
                                ? 'Turn repeat off'
                                : 'Repeat current track',
                            onPressed: () {
                              final next = loopMode == LoopMode.off
                                  ? LoopMode.one
                                  : LoopMode.off;
                              setState(() => loopMode = next);
                              player.setLoopMode(next);
                            },
                            icon: Icon(
                              Icons.repeat_rounded,
                              color: loopMode == LoopMode.one
                                  ? AppColors.violet
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_music_outlined,
                            size: 16,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'From the sample catalog',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
