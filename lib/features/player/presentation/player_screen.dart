import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../home/application/catalog_provider.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    final catalog = ref.watch(catalogProvider);
    final player = ref.watch(audioPlayerProvider);
    final actions = ref.watch(playbackActionsProvider);
    final index = ref.watch(currentSongIndexProvider);
    final liked = ref.watch(likedSongIndicesProvider).contains(index);
    final loading = ref.watch(playbackLoadingProvider);
    final error = ref.watch(playbackErrorProvider);
    final shuffle = ref.watch(shuffleEnabledProvider);
    final repeat = ref.watch(repeatEnabledProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to browsing',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        centerTitle: true,
        title: const Text(
          'THE LISTENING ROOM',
          style: TextStyle(fontSize: 11, letterSpacing: 1.6),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (song == null) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: catalog.isLoading
                      ? const CatalogLoading()
                      : catalog.hasError
                      ? const CatalogError()
                      : EmptyState(
                          icon: Icons.music_note_outlined,
                          title: 'Nothing to play yet',
                          message: 'Find something you love in Explore.',
                          actionLabel: 'Explore tracks',
                          onAction: () => context.go('/explore'),
                        ),
                ),
              );
            }
            final artSize = math.min(
              constraints.maxWidth - 48,
              math.min(constraints.maxHeight * .42, 330.0),
            );
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      children: [
                        Artwork(
                          url: song.artwork,
                          size: math.max(120, artSize),
                          radius: 24,
                          semanticLabel: 'Artwork for ${song.title}',
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      height: 1.15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
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
                            Semantics(
                              toggled: liked,
                              child: IconButton(
                                tooltip: liked
                                    ? 'Remove from liked songs'
                                    : 'Like song',
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(songRepositoryProvider)
                                        .favorite(song, !liked);
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Your like could not be saved. Please retry.',
                                              ),
                                            ),
                                          );
                                    }
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  final likes = {
                                    ...ref.read(likedSongIndicesProvider),
                                  };
                                  liked
                                      ? likes.remove(index)
                                      : likes.add(index);
                                  ref
                                          .read(
                                            likedSongIndicesProvider.notifier,
                                          )
                                          .state =
                                      likes;
                                },
                                icon: Icon(
                                  liked
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: liked
                                      ? AppColors.violet
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        StreamBuilder<Duration?>(
                          stream: player.durationStream,
                          initialData: player.duration,
                          builder: (context, durationSnapshot) {
                            final duration =
                                durationSnapshot.data ?? Duration.zero;
                            return StreamBuilder<Duration>(
                              stream: player.positionStream,
                              initialData: player.position,
                              builder: (context, positionSnapshot) {
                                final position =
                                    positionSnapshot.data ?? Duration.zero;
                                final max = duration.inMilliseconds.toDouble();
                                final value = max == 0
                                    ? 0.0
                                    : position.inMilliseconds
                                          .clamp(0, duration.inMilliseconds)
                                          .toDouble();
                                return Column(
                                  children: [
                                    Semantics(
                                      label: 'Playback position',
                                      child: Slider(
                                        value: value,
                                        max: max == 0 ? 1 : max,
                                        semanticFormatterCallback: (value) =>
                                            '${_time(Duration(milliseconds: value.round()))} of ${_time(duration)}',
                                        onChanged: max == 0
                                            ? null
                                            : (value) => actions.seek(
                                                Duration(
                                                  milliseconds: value.round(),
                                                ),
                                              ),
                                      ),
                                    ),
                                    Row(
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
                                          max == 0
                                              ? song.duration
                                              : _time(duration),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => actions.play(index),
                            child: const Text('Try again'),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Play previous track',
                              onPressed: loading
                                  ? null
                                  : () => actions.skip(-1),
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            StreamBuilder<PlayerState>(
                              stream: player.playerStateStream,
                              initialData: player.playerState,
                              builder: (context, snapshot) {
                                final playing = snapshot.data?.playing ?? false;
                                return Semantics(
                                  label: loading
                                      ? 'Loading audio'
                                      : playing
                                      ? 'Pause track'
                                      : 'Play track',
                                  button: true,
                                  child: SizedBox.square(
                                    dimension: 80,
                                    child: Tooltip(
                                      message: playing
                                          ? 'Pause track'
                                          : 'Play track',
                                      child: FilledButton(
                                        onPressed: loading
                                            ? null
                                            : actions.togglePlayback,
                                        style: FilledButton.styleFrom(
                                          shape: const CircleBorder(),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: loading
                                            ? MediaQuery.disableAnimationsOf(
                                                    context,
                                                  )
                                                  ? const Icon(
                                                      Icons
                                                          .hourglass_top_rounded,
                                                    )
                                                  : const SizedBox.square(
                                                      dimension: 28,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                            : Icon(
                                                playing
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                size: 36,
                                              ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              tooltip: 'Play next track',
                              onPressed: loading ? null : () => actions.skip(1),
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Semantics(
                                toggled: shuffle,
                                child: TextButton.icon(
                                  onPressed: actions.toggleShuffle,
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    color: shuffle
                                        ? AppColors.violet
                                        : AppColors.muted,
                                  ),
                                  label: Text(
                                    shuffle ? 'Shuffle on' : 'Shuffle',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: shuffle
                                          ? AppColors.violet
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Semantics(
                                toggled: repeat,
                                child: TextButton.icon(
                                  onPressed: actions.toggleRepeat,
                                  icon: Icon(
                                    repeat
                                        ? Icons.repeat_one_rounded
                                        : Icons.repeat_rounded,
                                    color: repeat
                                        ? AppColors.violet
                                        : AppColors.muted,
                                  ),
                                  label: Text(
                                    repeat ? 'Repeat on' : 'Repeat',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: repeat
                                          ? AppColors.violet
                                          : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          ref.watch(demoModeProvider)
                              ? 'Sample catalog · Demo audio'
                              : 'Your private music library',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _time(Duration duration) =>
      '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}
