import '../../../core/widgets/theme_mode_menu.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../explore/domain/discovery.dart';
import '../../explore/presentation/sample_collection_tile.dart';
import '../application/catalog_provider.dart';
import '../domain/song.dart';
import '../../community/presentation/community_home_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final sample = ref.watch(demoModeProvider);
    if (!sample) return const CommunityHomeScreen();
    final name = ref.watch(authSessionProvider)?.name.trim();
    final displayName = name == null || name.isEmpty
        ? (sample ? t.guestName : t.accountName)
        : name;
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          _HomeHeader(name: displayName),
          const SizedBox(height: 24),
          ref
              .watch(catalogProvider)
              .when(
                loading: () => const CatalogLoading(),
                error: (_, _) => const CatalogError(),
                data: (songs) {
                  if (songs.isEmpty) {
                    return AuroraReveal(
                      child: GlassCard(
                        child: EmptyState(
                          icon: Icons.library_music_outlined,
                          title: t.homeEmptyTitle,
                          message: sample ? t.homeEmptyDemo : t.homeEmptyReal,
                          actionLabel: sample ? t.exploreMusic : t.uploadTrack,
                          onAction: () =>
                              context.go(sample ? '/explore' : '/upload'),
                        ),
                      ),
                    );
                  }
                  final collections = sampleCollections
                      .where((collection) => songs.any(collection.contains))
                      .toList();
                  final liked = ref.watch(likedSongIndicesProvider);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuroraReveal(child: _FeaturedBanner(song: songs.first)),
                      if (songs.length > 1) ...[
                        const SizedBox(height: 32),
                        AuroraReveal(
                          delay: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeading(
                                t.newUploads,
                                actionLabel: t.browseAll,
                                onAction: () => context.go('/library'),
                              ),
                              const SizedBox(height: 8),
                              for (var i = 1; i < songs.length; i++)
                                SongTile(song: songs[i], index: i),
                            ],
                          ),
                        ),
                      ],
                      if (collections.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        AuroraReveal(
                          delay: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeading(
                                t.genreCollections,
                                actionLabel: t.explore,
                                onAction: () => context.go('/explore'),
                              ),
                              Text(
                                sample
                                    ? t.collectionsDemoSubtitle
                                    : t.collectionsRealSubtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final wide = constraints.maxWidth >= 680;
                                  return Wrap(
                                    spacing: 16,
                                    children: [
                                      for (final collection in collections)
                                        SizedBox(
                                          width: wide
                                              ? (constraints.maxWidth - 16) / 2
                                              : constraints.maxWidth,
                                          child: SampleCollectionTile(
                                            sample: sample,
                                            collection: collection,
                                            songs: songs,
                                            onTap: () => context.go(
                                              DiscoveryFilters(
                                                collectionId: collection.id,
                                              ).location,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (liked.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        SectionHeading(
                          t.yourFavorites,
                          actionLabel: t.openLibrary,
                          onAction: () => context.go('/library'),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < songs.length; i++)
                          if (liked.contains(i))
                            SongTile(song: songs[i], index: i),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        sample ? t.songsDemoCaption : t.songsPrivateCaption,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AuroraLogo(size: 32, wordmark: true),
                ),
              ),
            ),
            const ThemeModeMenu(),
            IconButton(
              tooltip: t.searchLabel,
              onPressed: () => context.go('/explore'),
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton.filledTonal(
              tooltip: t.profile,
              onPressed: () => context.go('/profile'),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.surfaceLight,
                foregroundColor: context.colors.accentText,
              ),
              icon: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                '${t.homeGreeting} $name',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: context.colors.secondaryText),
              ),
            ),
            const SizedBox(width: 12),
            GradientIconButton(
              icon: Icons.add_rounded,
              tooltip: t.uploadMusic,
              size: 48,
              onPressed: () => context.push('/upload'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedBanner extends ConsumerWidget {
  const _FeaturedBanner({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final sample = ref.watch(demoModeProvider);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: context.colors.violet.withValues(alpha: .14),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        gradient: context.colors.featuredGradient,
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 620;
            final copy = Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sample ? t.demoBadge : t.privateBadge,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.accentText,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.homeTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song.artist} · ${song.genre}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.colors.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: t.listenNow,
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => openCatalogSong(context, ref, 0),
                  ),
                ],
              ),
            );
            final art = Padding(
              padding: wide
                  ? const EdgeInsets.fromLTRB(0, 24, 24, 24)
                  : const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Artwork(
                url: song.artwork,
                size: wide ? 240 : constraints.maxWidth - 40,
                height: wide ? 240 : 180,
                radius: 18,
                semanticLabel: t.artworkFor(song.title),
              ),
            );
            return wide
                ? Row(
                    children: [
                      Expanded(child: copy),
                      art,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [art, copy],
                  );
          },
        ),
      ),
    );
  }
}
