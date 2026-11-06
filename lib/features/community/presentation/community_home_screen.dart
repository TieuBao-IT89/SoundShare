import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';
import 'music_components.dart';

class CommunityHomeScreen extends ConsumerStatefulWidget {
  const CommunityHomeScreen({super.key});
  @override
  ConsumerState<CommunityHomeScreen> createState() =>
      _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends ConsumerState<CommunityHomeScreen> {
  String feed = 'recommended';
  @override
  Widget build(BuildContext context) {
    final t = context.l10n,
        profile = ref.watch(myPublicProfileProvider).valueOrNull;
    return AppScaffold(
      child: ListView(
        key: const PageStorageKey('community-home'),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.v4Greeting,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.displayName.isNotEmpty == true
                          ? profile!.displayName
                          : t.v4HomeIntro,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width < 768) ...[
                IconButton(
                  tooltip: t.search,
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                Tooltip(
                  message: t.profile,
                  child: InkWell(
                    onTap: () => context.go('/profile'),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Artwork(
                        url: profile?.avatar ?? '',
                        size: 40,
                        radius: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          CommunityAsync(
            value: ref.watch(communityHomeProvider),
            retry: () => ref.invalidate(communityHomeProvider),
            data: (data) {
              List<Song> songs(String key) => ((data[key] as List?) ?? [])
                  .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
                  .toList();
              final fresh = songs('newReleases'),
                  recent = songs('recent'),
                  popular = songs('popular');
              final selected = songs(feed);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fresh.isNotEmpty)
                    FeaturedMusic(songs: fresh)
                  else ...[
                    const CommunityEmpty(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => context.push('/upload'),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(t.uploadMusic),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final entry in [
                        (
                          Icons.favorite_border_rounded,
                          t.likedTracks,
                          '/liked',
                        ),
                        (
                          Icons.queue_music_rounded,
                          t.v3Playlists,
                          '/playlists',
                        ),
                        (
                          Icons.upload_file_outlined,
                          t.allUploads,
                          '/manage-songs',
                        ),
                      ])
                        ActionChip(
                          avatar: Icon(entry.$1, size: 18),
                          label: Text(entry.$2),
                          onPressed: () => context.push(entry.$3),
                        ),
                    ],
                  ),
                  if (recent.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    SectionHeading(t.v3Recent),
                    const SizedBox(height: 12),
                    SongColumns(songs: recent.take(3).toList()),
                  ],
                  const SizedBox(height: 28),
                  ContentTabs(
                    items: [
                      ('recommended', t.v3ForYou),
                      ('following', t.v3FollowingFeed),
                    ],
                    selected: feed,
                    onSelected: (value) => setState(() => feed = value),
                  ),
                  const SizedBox(height: 12),
                  if (feed == 'recommended')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        t.v3RecommendationNote,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  if (selected.isEmpty)
                    const CommunityEmpty()
                  else
                    SongArtworkRail(songs: selected),
                  if (fresh.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeading(
                      t.v3NewReleases,
                      actionLabel: t.v4SeeAll,
                      onAction: () => context.go('/explore'),
                    ),
                    const SizedBox(height: 8),
                    SongColumns(songs: fresh.take(6).toList()),
                  ],
                  if (popular.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    SectionHeading(
                      t.v4Charts,
                      actionLabel: t.v4SeeAll,
                      onAction: () => context.go('/explore'),
                    ),
                    const SizedBox(height: 8),
                    SongColumns(songs: popular.take(5).toList(), ranked: true),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
