import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../explore/domain/discovery.dart';
import '../../explore/presentation/sample_collection_tile.dart';
import '../application/catalog_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => AppScaffold(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
      children: [
        ScreenHeading(
          eyebrow: 'SOUNDSHARE',
          title: 'A room for\nindependent sound.',
          subtitle: 'Stay a little. Find something that stays with you.',
          action: IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
              foregroundColor: AppColors.violet,
            ),
            tooltip: 'Prepare a track',
            onPressed: () => context.push('/upload'),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: 26),
        ref
            .watch(catalogProvider)
            .when(
              loading: () => const CatalogLoading(),
              error: (_, _) => const CatalogError(),
              data: (songs) {
                if (songs.isEmpty) {
                  return EmptyState(
                    icon: Icons.library_music_outlined,
                    title: 'The listening room is quiet',
                    message: ref.watch(demoModeProvider)
                        ? 'Tracks will appear here when they are available.'
                        : 'Upload your first MP3 to start your private music library.',
                    actionLabel: ref.watch(demoModeProvider)
                        ? 'Explore'
                        : 'Upload a track',
                    onAction: () => context.go(
                      ref.read(demoModeProvider) ? '/explore' : '/upload',
                    ),
                  );
                }
                final featured = songs.first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.watch(demoModeProvider)
                          ? 'IN FOCUS · SAMPLE SELECTION'
                          : 'IN FOCUS · YOUR LIBRARY',
                      style: TextStyle(
                        color: AppColors.mint,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) => Artwork(
                        url: featured.artwork,
                        size: constraints.maxWidth,
                        height: 200,
                        radius: 20,
                        semanticLabel: 'Artwork for ${featured.title}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      featured.title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${featured.artist} · ${featured.genre}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => openCatalogSong(context, ref, 0),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Listen to this track'),
                    ),
                    const SizedBox(height: 28),
                    SectionHeading(
                      'Take a different turn',
                      actionLabel: 'Browse all',
                      onAction: () => context.go('/explore'),
                    ),
                    Text(
                      ref.watch(demoModeProvider)
                          ? 'Sample collections · Grouped by genre'
                          : 'Your collections · Grouped by genre',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    for (final collection in sampleCollections)
                      SampleCollectionTile(
                        sample: ref.watch(demoModeProvider),
                        collection: collection,
                        songs: songs,
                        onTap: () => context.go(
                          DiscoveryFilters(collectionId: collection.id)
                              .location,
                        ),
                      ),
                    const SizedBox(height: 28),
                    SectionHeading(
                      'Keep discovering',
                      actionLabel: 'Explore',
                      onAction: () => context.go('/explore'),
                    ),
                    for (var i = 1; i < songs.length; i++)
                      SongTile(song: songs[i], index: i),
                    const SizedBox(height: 20),
                    Text(
                      ref.watch(demoModeProvider)
                          ? 'Sample catalog · All tracks use demo audio.'
                          : 'Your uploads · Private to your account',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              },
            ),
      ],
    ),
  );
}
