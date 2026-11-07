import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme/app_theme.dart';
import '../../features/home/domain/song.dart';
import '../../l10n/l10n.dart';
import '../services/audio_service.dart';
import '../services/song_favorite_service.dart';
import 'music_progress_slider.dart';
import 'listening_panel.dart';
import 'player_sheet.dart';

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
        final playing =
            (snapshot.data?.playing ?? false) &&
            snapshot.data?.processingState != ProcessingState.completed;
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
            backgroundColor: context.colors.isDark
                ? context.colors.text
                : context.colors.action,
            foregroundColor: context.colors.isDark
                ? context.colors.background
                : Colors.white,
          ),
          icon: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: busy
                ? Icon(
                    Icons.hourglass_top_rounded,
                    key: const ValueKey('loading'),
                    size: large ? 36 : 26,
                  )
                : TweenAnimationBuilder<double>(
                    key: const ValueKey('play-pause'),
                    tween: Tween(begin: playing ? 1 : 0, end: playing ? 1 : 0),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    builder: (context, value, _) => AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: AlwaysStoppedAnimation(value),
                      size: large ? 36 : 26,
                    ),
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
        showPlayerSheet<void>(
          context,
          (sheetContext) =>
              ListeningPanel(onClose: () => Navigator.pop(sheetContext)),
        );
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

Future<bool?> toggleSongFavorite(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  try {
    final liked = await ref.read(songFavoriteActionsProvider).toggle(song);
    if (liked != null) HapticFeedback.selectionClick().ignore();
    return liked;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.likeSaveFailed)));
    }
    return null;
  }
}

class SongFavoriteButton extends ConsumerWidget {
  const SongFavoriteButton({super.key, required this.song});
  final Song song;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(songLikedProvider(song));
    final busy = ref.watch(favoriteBusyProvider).contains(song.identity);
    return IconButton(
      tooltip: liked ? context.l10n.unlikeSong : context.l10n.likeSong,
      isSelected: liked,
      icon: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(liked),
        ),
      ),
      onPressed: busy ? null : () => toggleSongFavorite(context, ref, song),
    );
  }
}
