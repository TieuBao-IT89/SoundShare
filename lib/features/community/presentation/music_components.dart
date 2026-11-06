import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

class FeaturedMusic extends ConsumerStatefulWidget {
  const FeaturedMusic({super.key, required this.songs});
  final List<Song> songs;
  @override
  ConsumerState<FeaturedMusic> createState() => _FeaturedMusicState();
}

class _FeaturedMusicState extends ConsumerState<FeaturedMusic> {
  int page = 0;
  final controller = PageController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs.take(3).toList();
    if (songs.isEmpty) return const CommunityEmpty();
    final height = MediaQuery.textScalerOf(context).scale(24) > 36
        ? 520.0
        : 250.0;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: controller,
            itemCount: songs.length,
            onPageChanged: (value) => setState(() => page = value),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, bounds) => Artwork(
                      url: songs[i].artwork,
                      size: bounds.maxWidth,
                      height: height,
                      radius: 0,
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xF20F1220),
                          Color(0xB0181C2C),
                          Color(0x180F1220),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.v4Featured,
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              songs[i].title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              songs[i].artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                ref
                                    .read(playbackActionsProvider)
                                    .playFrom(widget.songs, i);
                                context.push('/player');
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(context.l10n.listenNow),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (songs.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < songs.length; i++)
                Semantics(
                  selected: page == i,
                  child: IconButton(
                    tooltip: context.l10n.v4FeaturedPosition(
                      i + 1,
                      songs.length,
                    ),
                    onPressed: () => controller.animateToPage(
                      i,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    icon: Container(
                      width: page == i ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: page == i
                            ? AppColors.cyan
                            : AppColors.secondaryText,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class SongArtworkRail extends ConsumerWidget {
  const SongArtworkRail({super.key, required this.songs});
  final List<Song> songs;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height: 220 + MediaQuery.textScalerOf(context).scale(60) * 1.4,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: songs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 20),
      itemBuilder: (context, i) => SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(playbackActionsProvider).playFrom(songs, i);
                    context.push('/player');
                  },
                  child: Artwork(
                    url: songs[i].artwork,
                    size: 168,
                    radius: 12,
                    semanticLabel: context.l10n.playSong(songs[i].title),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Material(
                    color: AppColors.secondaryBackground.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(24),
                    child: SongActionMenu(song: songs[i]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              songs[i].title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
            if (songs[i].username != null)
              Text(
                songs[i].artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            if (songs[i].username != null)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => context.push(
                  '/u/${Uri.encodeComponent(songs[i].username!)}',
                ),
                child: Text(
                  '@${songs[i].username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  songs[i].artist,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class ChartSpotlight extends ConsumerWidget {
  const ChartSpotlight({super.key, required this.songs});
  final List<Song> songs;
  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 22;
      final width = bounds.maxWidth >= 840 && !large
          ? (bounds.maxWidth - 32) / 3
          : 220.0;
      return SizedBox(
        height: large ? 510 : 334,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, i) => SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        ref.read(playbackActionsProvider).playFrom(songs, i);
                        context.push('/player');
                      },
                      child: Artwork(
                        url: songs[i].artwork,
                        size: width,
                        height: 156,
                        radius: 12,
                        semanticLabel: context.l10n.playSong(songs[i].title),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 8,
                      child: Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 48,
                          height: 1.1,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: AppColors.secondaryBackground,
                        borderRadius: BorderRadius.circular(24),
                        child: SongActionMenu(song: songs[i]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  songs[i].title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  songs[i].artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${songs[i].validPlays} ${context.l10n.v3Views} · ${songs[i].likeCount} ${context.l10n.v3Likes}',
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SongColumns extends StatelessWidget {
  const SongColumns({super.key, required this.songs, this.ranked = false});
  final List<Song> songs;
  final bool ranked;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 22;
      final columns = !large && bounds.maxWidth >= 1120
          ? 3
          : !large && bounds.maxWidth >= 720
          ? 2
          : 1;
      final width = (bounds.maxWidth - (columns - 1) * 24) / columns;
      return Wrap(
        spacing: 24,
        runSpacing: 4,
        children: [
          for (var i = 0; i < songs.length; i++)
            SizedBox(
              width: width,
              child: CommunitySongRow(
                song: songs[i],
                queue: songs,
                index: i,
                rank: ranked ? i + 1 : null,
                showStats: ranked,
              ),
            ),
        ],
      );
    },
  );
}

class CreatorRail extends StatelessWidget {
  const CreatorRail({super.key, required this.profiles});
  final List<PublicProfile> profiles;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(14) > 22 ? 460 : 270,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (context, i) => SizedBox(
        width: MediaQuery.textScalerOf(context).scale(14) > 22 ? 250 : 186,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.push(
                    '/u/${Uri.encodeComponent(profiles[i].username!)}',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Artwork(url: profiles[i].avatar, size: 64, radius: 40),
                      const SizedBox(height: 12),
                      Text(
                        profiles[i].displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '@${profiles[i].username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${profiles[i].followers} ${context.l10n.v3Followers}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                FollowButton(profile: profiles[i]),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class GenreTiles extends StatelessWidget {
  const GenreTiles({
    super.key,
    required this.genres,
    required this.onSelect,
    this.selected,
  });
  final List<String> genres;
  final ValueChanged<String> onSelect;
  final String? selected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final count = bounds.maxWidth >= 900
          ? 4
          : bounds.maxWidth >= 560
          ? 3
          : 2;
      final width = (bounds.maxWidth - (count - 1) * 12) / count;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < genres.length; i++)
            SizedBox(
              width: width,
              child: Material(
                color: i.isEven
                    ? AppColors.surface
                    : AppColors.secondaryBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected == genres[i]
                        ? AppColors.cyan
                        : AppColors.border,
                  ),
                ),
                child: InkWell(
                  onTap: () => onSelect(genres[i]),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          [
                            Icons.graphic_eq_rounded,
                            Icons.album_outlined,
                            Icons.waves_rounded,
                            Icons.piano_outlined,
                          ][i % 4],
                          color: i.isEven ? AppColors.cyan : AppColors.mystic,
                          size: 28,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          genres[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class ContentTabs extends StatelessWidget {
  const ContentTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item.$2),
              selected: selected == item.$1,
              onSelected: (_) => onSelected(item.$1),
            ),
          ),
      ],
    ),
  );
}
