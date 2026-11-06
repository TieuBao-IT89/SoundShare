import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/artwork_glow.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/playback_controls.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});
  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width >= 768
      ? const AppScaffold(showMiniPlayer: false, child: _PlayerContent())
      : const Scaffold(body: SafeArea(child: _PlayerContent()));
}

class _PlayerContent extends ConsumerWidget {
  const _PlayerContent();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider),
        catalog = ref.watch(catalogProvider);
    final failed = ref.watch(playbackErrorProvider) != null;
    final t = context.l10n;
    return Column(
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
              const PlayerQueueButton(),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              if (song == null) {
                return catalog.isLoading
                    ? const CatalogLoading()
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
                        bounds.maxHeight * .48,
                      ),
                    );
              final artwork = SizedBox.square(
                dimension: artSize,
                child: ArtworkGlow(
                  image: song.artwork.isEmpty
                      ? null
                      : artworkImageProvider(song.artwork),
                  child: HeroMode(
                    enabled: !MediaQuery.disableAnimationsOf(context),
                    child: Hero(
                      tag: 'current-artwork-${song.identity}',
                      child: Artwork(
                        url: song.artwork,
                        size: artSize,
                        radius: 20,
                        semanticLabel: t.artworkFor(song.title),
                      ),
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      SongFavoriteButton(song: song),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 16,
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
                  const SizedBox(height: 24),
                  const PlaybackProgress(),
                  if (failed) ...[
                    const SizedBox(height: 12),
                    Text(
                      t.audioLoadFailed,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(playbackActionsProvider)
                          .playQueued(ref.read(currentSongIndexProvider)),
                      child: Text(t.tryAgain),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const PlaybackModes(large: true),
                  const SizedBox(height: 24),
                  Text(
                    ref.watch(demoModeProvider)
                        ? t.sampleAudioNotice
                        : song.community
                        ? t.v3DiscoverSubtitle
                        : t.privateLibraryNotice,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                                const SizedBox(height: 28),
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
    );
  }
}
