import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/community/application/community_providers.dart';
import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';
import '../../l10n/l10n.dart';
import '../services/audio_service.dart';
import 'music_progress_slider.dart';
import 'listening_panel.dart';

/// All controls read the existing player; these widgets own no playback state.
class PlaybackToggle extends ConsumerWidget {
  const PlaybackToggle({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    final busy = ref.watch(playbackLoadingProvider);
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      initialData: player.playerState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return IconButton.filled(
          tooltip: busy
              ? context.l10n.loadingAudio
              : playing
              ? context.l10n.pauseTrack
              : large
              ? context.l10n.playTrack
              : context.l10n.resumeTrack,
          onPressed: busy
              ? null
              : ref.read(playbackActionsProvider).togglePlayback,
          style: IconButton.styleFrom(
            minimumSize: Size.square(large ? 72 : 48),
            backgroundColor: AppColors.text,
            foregroundColor: AppColors.background,
          ),
          icon: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Icon(
              busy
                  ? Icons.hourglass_top_rounded
                  : playing
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              key: ValueKey((busy, playing)),
              size: large ? 36 : 26,
            ),
          ),
        );
      },
    );
  }
}

class PlayerQueueButton extends ConsumerWidget {
  const PlayerQueueButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: context.l10n.v3Queue,
    onPressed: () {
      if (MediaQuery.sizeOf(context).width >= 768 &&
          ref.read(hasSelectedSongProvider)) {
        ref.read(queuePanelVisibleProvider.notifier).state = !ref.read(
          queuePanelVisibleProvider,
        );
      } else {
        context.push('/queue');
      }
    },
    icon: const Icon(Icons.queue_music_rounded),
  );
}

class PlaybackModes extends ConsumerWidget {
  const PlaybackModes({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(playbackActionsProvider);
    final shuffle = ref.watch(shuffleEnabledProvider),
        repeat = ref.watch(repeatEnabledProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: shuffle ? context.l10n.shuffleOn : context.l10n.shuffle,
          isSelected: shuffle,
          onPressed: actions.toggleShuffle,
          icon: const Icon(Icons.shuffle_rounded),
        ),
        IconButton(
          tooltip: context.l10n.previousTrack,
          onPressed: () => actions.skip(-1),
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        PlaybackToggle(large: large),
        IconButton(
          tooltip: context.l10n.nextTrack,
          onPressed: () => actions.skip(1),
          icon: const Icon(Icons.skip_next_rounded),
        ),
        IconButton(
          tooltip: repeat ? context.l10n.repeatOn : context.l10n.repeat,
          isSelected: repeat,
          onPressed: actions.toggleRepeat,
          icon: Icon(repeat ? Icons.repeat_one_rounded : Icons.repeat_rounded),
        ),
      ],
    );
  }
}

class PlaybackProgress extends ConsumerWidget {
  const PlaybackProgress({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      initialData: player.duration,
      builder: (context, duration) => StreamBuilder<Duration>(
        stream: player.positionStream,
        initialData: player.position,
        builder: (context, position) => MusicProgressSlider(
          position: position.data ?? Duration.zero,
          duration: duration.data ?? Duration.zero,
          onSeek: ref.read(playbackActionsProvider).seek,
        ),
      ),
    );
  }
}

class SongFavoriteButton extends ConsumerStatefulWidget {
  const SongFavoriteButton({super.key, required this.song});
  final Song song;
  @override
  ConsumerState<SongFavoriteButton> createState() => _SongFavoriteButtonState();
}

class _SongFavoriteButtonState extends ConsumerState<SongFavoriteButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final song = widget.song, index = ref.watch(currentSongIndexProvider);
    final liked = song.community
        ? ref.watch(communityLikesProvider)[song.identity] ?? song.liked
        : ref.watch(likedSongIndicesProvider).contains(index);
    return IconButton(
      tooltip: liked ? context.l10n.unlikeSong : context.l10n.likeSong,
      isSelected: liked,
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      ),
      onPressed: busy
          ? null
          : () async {
              setState(() => busy = true);
              try {
                await ref.read(songRepositoryProvider).favorite(song, !liked);
                if (!mounted) return;
                if (song.community) {
                  ref.read(communityLikesProvider.notifier).state = {
                    ...ref.read(communityLikesProvider),
                    song.identity: !liked,
                  };
                  ref.invalidate(catalogProvider);
                  ref.invalidate(communityHomeProvider);
                  ref.invalidate(communitySongsProvider);
                } else {
                  final likes = {...ref.read(likedSongIndicesProvider)};
                  liked ? likes.remove(index) : likes.add(index);
                  ref.read(likedSongIndicesProvider.notifier).state = likes;
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.likeSaveFailed)),
                  );
                }
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
    );
  }
}
