import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../community/application/community_providers.dart';
import '../../community/presentation/community_widgets.dart';
import '../../community/presentation/playlist_preview.dart';
import '../../home/application/catalog_provider.dart';

class MusicLibraryScreen extends ConsumerWidget {
  const MusicLibraryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final catalog = ref.watch(catalogProvider);
    return AppScaffold(
      child: CustomScrollView(
        key: const PageStorageKey('music-library'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.libraryTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: t.uploadMusic,
                      onPressed: () => context.push('/upload'),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in [
                      ('/liked', Icons.favorite_border_rounded, t.likedTracks),
                      (
                        '/saved',
                        Icons.bookmark_outline_rounded,
                        t.v3SavedTracks,
                      ),
                      ('/playlists', Icons.queue_music_rounded, t.v3Playlists),
                      (
                        '/library/search',
                        Icons.search_rounded,
                        t.v3LibrarySearch,
                      ),
                    ])
                      ActionChip(
                        avatar: Icon(item.$2, size: 18),
                        label: Text(item.$3),
                        onPressed: () => context.push(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.allUploads,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: t.v3ManageSongs,
                      onPressed: () => context.push('/manage-songs'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                Text(
                  t.libraryPrivacyNote,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (catalog.isLoading)
            const SliverToBoxAdapter(child: CatalogLoading())
          else if (catalog.hasError)
            const SliverToBoxAdapter(child: CatalogError())
          else if (catalog.requireValue.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.library_music_outlined,
                  title: t.libraryEmptyTitle,
                  message: t.libraryEmptyMessage,
                  actionLabel: t.uploadMusic,
                  onAction: () => context.push('/upload'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: catalog.requireValue.length,
                itemBuilder: (context, i) =>
                    SongTile(song: catalog.requireValue[i], index: i),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.v3Playlists,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/playlists'),
                      child: Text(t.v4SeeAll),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CommunityAsync(
                  value: ref.watch(myPlaylistsProvider(0)),
                  retry: () => ref.invalidate(myPlaylistsProvider(0)),
                  data: (data) => PlaylistGrid(
                    items: (data['items'] as List)
                        .take(4)
                        .cast<Map<String, dynamic>>()
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
