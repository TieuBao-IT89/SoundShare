import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../services/audio_service.dart';
import 'artwork.dart';
import 'music_progress_slider.dart';

/// Shares its selection, audio instance, and actions with the full player.
class FloatingMiniPlayer extends ConsumerWidget {
  const FloatingMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    final selected = ref.watch(hasSelectedSongProvider);
    if (!selected || song == null) return const SizedBox.shrink();
    final loading = ref.watch(playbackLoadingProvider);
    final failed = ref.watch(playbackErrorProvider) != null;
    final player = ref.watch(audioPlayerProvider);
    final actions = ref.watch(playbackActionsProvider);
    final copy = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: DecoratedBox(
            key: const ValueKey('mini-player'),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .97),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: .12),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: copy.openPlayer,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.push('/player'),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    HeroMode(
                                      enabled: !MediaQuery.disableAnimationsOf(
                                        context,
                                      ),
                                      child: Hero(
                                        tag: 'current-artwork-${song.identity}',
                                        child: Artwork(
                                          url: song.artwork,
                                          size: 46,
                                          radius: 12,
                                          semanticLabel: copy.artworkFor(
                                            song.title,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            failed
                                                ? copy.playbackUnavailable
                                                : song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: failed
                                                  ? AppColors.error
                                                  : AppColors.secondaryText,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        initialData: player.playerState,
                        builder: (context, snapshot) {
                          final playing = snapshot.data?.playing ?? false;
                          return IconButton(
                            tooltip: loading
                                ? copy.loadingAudio
                                : playing
                                ? copy.pauseTrack
                                : copy.resumeTrack,
                            onPressed: loading ? null : actions.togglePlayback,
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.text,
                              backgroundColor: AppColors.violet.withValues(
                                alpha: .16,
                              ),
                            ),
                            icon: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: Tween<double>(
                                        begin: .88,
                                        end: 1,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: KeyedSubtree(
                                key: ValueKey(
                                  loading
                                      ? 'loading'
                                      : playing
                                      ? 'playing'
                                      : 'paused',
                                ),
                                child: loading
                                    ? MediaQuery.disableAnimationsOf(context)
                                          ? const Icon(
                                              Icons.hourglass_top_rounded,
                                            )
                                          : const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                    : Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: copy.nextTrack,
                        onPressed: loading ? null : () => actions.skip(1),
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  StreamBuilder<Duration?>(
                    stream: player.durationStream,
                    initialData: player.duration,
                    builder: (context, durationSnapshot) =>
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
                          initialData: player.position,
                          builder: (context, positionSnapshot) =>
                              MusicProgressIndicator(
                                position:
                                    positionSnapshot.data ?? Duration.zero,
                                duration:
                                    durationSnapshot.data ?? Duration.zero,
                              ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
