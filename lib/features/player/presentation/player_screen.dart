import '../../../core/widgets/theme_mode_menu.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/artwork_glow.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/playback_controls.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/vinyl_record_artwork.dart';
import 'player_record.dart';
import 'player_extras.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final phase = VinylRotationPhase();
  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width >= 768
      ? AppScaffold(showMiniPlayer: false, child: _PlayerContent(phase: phase))
      : Scaffold(
          body: SafeArea(child: _PlayerContent(phase: phase)),
        );
}

class _PlayerContent extends ConsumerWidget {
  const _PlayerContent({required this.phase});
  final VinylRotationPhase phase;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider),
        catalog = ref.watch(catalogProvider);
    final failed = ref.watch(playbackErrorProvider) != null;
    final player = ref.watch(audioPlayerProvider);
    final loading = ref.watch(playbackLoadingProvider);
    final t = context.l10n;
    return ArtworkGlow(
      image: song == null || song.artwork.isEmpty
          ? null
          : artworkImageProvider(song.artwork),
      ambientBackground: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: t.backToBrowsing,
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                Expanded(
                  child: Text(
                    t.nowPlaying,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const ThemeModeMenu(),
                const PlayerQueueButton(),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, bounds) {
                if (song == null) {
                  return catalog.isLoading
                      ? const SingleChildScrollView(child: CatalogLoading())
                      : catalog.hasError
                      ? const CatalogError()
                      : SingleChildScrollView(
                          child: EmptyState(
                            icon: Icons.music_note_outlined,
                            title: t.nothingToPlay,
                            message: t.nothingToPlayDescription,
                            actionLabel: t.exploreTracks,
                            onAction: () => context.go('/explore'),
                          ),
                        );
                }
                final wide =
                    bounds.maxWidth >= 850 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 22;
                final artSize = wide
                    ? math.min(bounds.maxWidth * .43, 460.0)
                    : math.max(
                        120.0,
                        math.min(
                          math.min(bounds.maxWidth - 48, 360.0),
                          math.min(
                            bounds.maxHeight * .48,
                            math.max(
                              120.0,
                              bounds.maxHeight -
                                  (song.username == null ? 380 : 428),
                            ),
                          ),
                        ),
                      );
                final artwork = SizedBox.square(
                  dimension: artSize,
                  child: HeroMode(
                    enabled: !MediaQuery.disableAnimationsOf(context),
                    child: Hero(
                      tag: 'current-artwork-${song.identity}',
                      child: StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        initialData: player.playerState,
                        builder: (context, snapshot) {
                          final state = snapshot.data ?? player.playerState;
                          return PlayerRecord(
                            song: song,
                            size: artSize,
                            phase: phase,
                            playing:
                                state.playing &&
                                state.processingState ==
                                    ProcessingState.ready &&
                                !loading &&
                                !failed,
                          );
                        },
                      ),
                    ),
                  ),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        SongFavoriteButton(song: song),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: song.username == null
                          ? null
                          : () => context.push(
                              '/u/${Uri.encodeComponent(song.username!)}',
                            ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: song.username == null ? 0 : 12,
                        ),
                        child: Text(
                          song.artist,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.secondaryText,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    if (song.username != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => context.push(
                            '/u/${Uri.encodeComponent(song.username!)}',
                          ),
                          child: Text('@${song.username}'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    const PlaybackProgress(),
                    if (failed) ...[
                      const SizedBox(height: 12),
                      Text(
                        t.audioLoadFailed,
                        style: TextStyle(color: context.colors.error),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(playbackActionsProvider)
                            .playQueued(ref.read(currentSongIndexProvider)),
                        child: Text(t.tryAgain),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const PlaybackModes(large: true),
                    const SizedBox(height: 8),
                    PlayerExtras(song: song),
                    const SizedBox(height: 8),
                    Text(
                      ref.watch(demoModeProvider)
                          ? t.sampleAudioNotice
                          : song.community
                          ? t.v3DiscoverSubtitle
                          : t.privateLibraryNotice,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                artwork,
                                const SizedBox(width: 56),
                                Expanded(child: details),
                              ],
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                children: [
                                  Center(child: artwork),
                                  const SizedBox(height: 20),
                                  details,
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
