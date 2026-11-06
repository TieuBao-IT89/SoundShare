import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/artwork_glow.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/music_progress_slider.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';
import '../../community/application/community_providers.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    final catalog = ref.watch(catalogProvider);
    final player = ref.watch(audioPlayerProvider);
    final actions = ref.watch(playbackActionsProvider);
    final index = ref.watch(currentSongIndexProvider);
    final liked = song?.community == true
        ? ref.watch(communityLikesProvider)[song!.identity] ?? song.liked
        : ref.watch(likedSongIndicesProvider).contains(index);
    final loading = ref.watch(playbackLoadingProvider);
    final failed = ref.watch(playbackErrorProvider) != null;
    final shuffle = ref.watch(shuffleEnabledProvider);
    final repeat = ref.watch(repeatEnabledProvider);
    final copy = context.l10n;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: copy.backToBrowsing,
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/'),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 28,
                            ),
                          ),
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                copy.nowPlaying,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: copy.v3Queue,
                            onPressed: () => context.push('/queue'),
                            icon: const Icon(Icons.queue_music_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                        child: song == null
                            ? catalog.isLoading
                                  ? const CatalogLoading()
                                  : catalog.hasError
                                  ? const CatalogError()
                                  : EmptyState(
                                      icon: Icons.music_note_outlined,
                                      title: copy.nothingToPlay,
                                      message: copy.nothingToPlayDescription,
                                      actionLabel: copy.exploreTracks,
                                      onAction: () => context.go('/explore'),
                                    )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 12),
                                  Center(
                                    child: _AmbientArtwork(
                                      identity: song.identity,
                                      url: song.artwork,
                                      label: copy.artworkFor(song.title),
                                      size: math.max(
                                        120,
                                        math.min(
                                          math.min(
                                            constraints.maxWidth - 48,
                                            360,
                                          ),
                                          constraints.maxHeight * .43,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                height: 1.25,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              song.artist,
                                              style: const TextStyle(
                                                color: AppColors.secondaryText,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Semantics(
                                        toggled: liked,
                                        child: IconButton(
                                          tooltip: liked
                                              ? copy.unlikeSong
                                              : copy.likeSong,
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(songRepositoryProvider)
                                                  .favorite(song, !liked);
                                            } catch (_) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          copy.likeSaveFailed,
                                                        ),
                                                      ),
                                                    );
                                              }
                                              return;
                                            }
                                            if (!context.mounted) return;
                                            if (song.community) {
                                              ref
                                                  .read(
                                                    communityLikesProvider
                                                        .notifier,
                                                  )
                                                  .state = {
                                                ...ref.read(
                                                  communityLikesProvider,
                                                ),
                                                song.identity: !liked,
                                              };
                                              ref.invalidate(catalogProvider);
                                              ref.invalidate(
                                                communityHomeProvider,
                                              );
                                              ref.invalidate(
                                                communitySongsProvider,
                                              );
                                              return;
                                            }
                                            final likes = {
                                              ...ref.read(
                                                likedSongIndicesProvider,
                                              ),
                                            };
                                            liked
                                                ? likes.remove(index)
                                                : likes.add(index);
                                            ref
                                                    .read(
                                                      likedSongIndicesProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                likes;
                                          },
                                          icon: AnimatedSwitcher(
                                            duration: reducedMotion
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 180,
                                                  ),
                                            transitionBuilder: (child, value) =>
                                                ScaleTransition(
                                                  scale: value,
                                                  child: child,
                                                ),
                                            child: Icon(
                                              liked
                                                  ? Icons.favorite_rounded
                                                  : Icons
                                                        .favorite_border_rounded,
                                              key: ValueKey(liked),
                                              color: liked
                                                  ? AppColors.pink
                                                  : AppColors.secondaryText,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  StreamBuilder<Duration?>(
                                    stream: player.durationStream,
                                    initialData: player.duration,
                                    builder: (context, durationSnapshot) =>
                                        StreamBuilder<Duration>(
                                          stream: player.positionStream,
                                          initialData: player.position,
                                          builder:
                                              (context, positionSnapshot) =>
                                                  MusicProgressSlider(
                                                    position:
                                                        positionSnapshot.data ??
                                                        Duration.zero,
                                                    duration:
                                                        durationSnapshot.data ??
                                                        Duration.zero,
                                                    durationFallback:
                                                        song.duration,
                                                    onSeek: actions.seek,
                                                  ),
                                        ),
                                  ),
                                  if (failed) ...[
                                    const SizedBox(height: 16),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        copy.audioLoadFailed,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: loading
                                          ? null
                                          : () => actions.playQueued(index),
                                      child: Text(copy.tryAgain),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: copy.previousTrack,
                                        onPressed: loading
                                            ? null
                                            : () => actions.skip(-1),
                                        icon: const Icon(
                                          Icons.skip_previous_rounded,
                                          size: 36,
                                        ),
                                      ),
                                      const SizedBox(width: 28),
                                      StreamBuilder<PlayerState>(
                                        stream: player.playerStateStream,
                                        initialData: player.playerState,
                                        builder: (context, snapshot) {
                                          final playing =
                                              snapshot.data?.playing ?? false;
                                          return _PrimaryPlaybackButton(
                                            playing: playing,
                                            loading: loading,
                                            onPressed: loading
                                                ? null
                                                : actions.togglePlayback,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 28),
                                      IconButton(
                                        tooltip: copy.nextTrack,
                                        onPressed: loading
                                            ? null
                                            : () => actions.skip(1),
                                        icon: const Icon(
                                          Icons.skip_next_rounded,
                                          size: 36,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _PlaybackModeButton(
                                          selected: shuffle,
                                          icon: Icons.shuffle_rounded,
                                          label: shuffle
                                              ? copy.shuffleOn
                                              : copy.shuffle,
                                          onPressed: actions.toggleShuffle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _PlaybackModeButton(
                                          selected: repeat,
                                          icon: repeat
                                              ? Icons.repeat_one_rounded
                                              : Icons.repeat_rounded,
                                          label: repeat
                                              ? copy.repeatOn
                                              : copy.repeat,
                                          onPressed: actions.toggleRepeat,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    ref.watch(demoModeProvider)
                                        ? copy.sampleAudioNotice
                                        : song.community
                                        ? copy.v3DiscoverSubtitle
                                        : copy.privateLibraryNotice,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 12,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmbientArtwork extends StatelessWidget {
  const _AmbientArtwork({
    required this.identity,
    required this.url,
    required this.label,
    required this.size,
  });
  final String identity;
  final String url;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => ArtworkGlow(
    image: url.isEmpty ? null : CachedNetworkImageProvider(url),
    child: HeroMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: Hero(
        tag: 'current-artwork-$identity',
        child: Artwork(url: url, size: size, radius: 24, semanticLabel: label),
      ),
    ),
  );
}

class _PrimaryPlaybackButton extends StatelessWidget {
  const _PrimaryPlaybackButton({
    required this.playing,
    required this.loading,
    required this.onPressed,
  });
  final bool playing;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final label = loading
        ? copy.loadingAudio
        : playing
        ? copy.pauseTrack
        : copy.playTrack;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: .35),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(80),
            foregroundColor: AppColors.text,
            disabledForegroundColor: AppColors.text,
          ),
          icon: loading
              ? reducedMotion
                    ? const Icon(Icons.hourglass_top_rounded)
                    : const SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          color: AppColors.text,
                          strokeWidth: 2,
                        ),
                      )
              : AnimatedSwitcher(
                  duration: reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(playing),
                    size: 38,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PlaybackModeButton extends StatelessWidget {
  const _PlaybackModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: selected,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected
            ? AppColors.violet.withValues(alpha: .12)
            : Colors.transparent,
        foregroundColor: selected ? AppColors.cyan : AppColors.secondaryText,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.violet : AppColors.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
