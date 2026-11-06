import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';
import 'music_components.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key, this.initialGenre});
  final String? initialGenre;
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String period = 'week', mode = 'featured';
  String? genre;
  int offset = 0, creatorOffset = 0;
  @override
  void initState() {
    super.initState();
    genre = widget.initialGenre;
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialGenre != widget.initialGenre) {
      genre = widget.initialGenre;
      offset = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final query = (
      path: genre == null ? '/discover/trending' : '/discover/new-releases',
      offset: offset,
      period: genre == null ? period : null,
      genre: genre,
    );
    const freshKey = (
      path: '/discover/new-releases',
      offset: 0,
      period: null as String?,
      genre: null as String?,
    );
    return AppScaffold(
      child: ListView(
        key: const PageStorageKey('discovery-hub'),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.explore,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: t.search,
                onPressed: () => context.go('/search'),
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          Text(
            t.v4ExploreIntro,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 20),
          CommunityAsync(
            value: ref.watch(communitySongsProvider(freshKey)),
            retry: () => ref.invalidate(communitySongsProvider(freshKey)),
            data: (page) => page.items.isEmpty
                ? const SizedBox.shrink()
                : FeaturedMusic(songs: page.items),
          ),
          const SizedBox(height: 24),
          SectionHeading(genre ?? t.v4Charts),
          const SizedBox(height: 12),
          if (genre == null) ...[
            ContentTabs(
              items: [
                ('today', t.v3Today),
                ('week', t.v3Week),
                ('month', t.v3Month),
                ('all', t.v3AllTime),
              ],
              selected: period,
              onSelected: (value) => setState(() {
                period = value;
                offset = 0;
              }),
            ),
            const SizedBox(height: 8),
            Text(
              t.v3TrendingNote,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  genre = null;
                  offset = 0;
                }),
                icon: const Icon(Icons.close_rounded),
                label: Text(t.allGenres),
              ),
            ),
          CommunityAsync(
            value: ref.watch(communitySongsProvider(query)),
            retry: () => ref.invalidate(communitySongsProvider(query)),
            data: (page) => Column(
              children: [
                if (page.items.isEmpty) const CommunityEmpty(),
                if (genre == null && offset == 0 && page.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ChartSpotlight(songs: page.items.take(3).toList()),
                  ),
                for (
                  var i = genre == null && offset == 0 ? 3 : 0;
                  i < page.items.length;
                  i++
                )
                  CommunitySongRow(
                    song: page.items[i],
                    queue: page.items,
                    index: i,
                    rank: genre == null ? offset + i + 1 : null,
                    showStats: genre == null,
                  ),
                CommunityPager(
                  offset: offset,
                  next: page.nextOffset,
                  onPage: (value) => setState(() => offset = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionHeading(t.v3Creators),
          const SizedBox(height: 12),
          ContentTabs(
            items: [
              ('featured', t.v3Featured),
              ('new', t.v3Newest),
              ('popular', t.v3Popular),
              ('growing', t.v3Growing),
            ],
            selected: mode,
            onSelected: (value) => setState(() {
              mode = value;
              creatorOffset = 0;
            }),
          ),
          const SizedBox(height: 16),
          CommunityAsync(
            value: ref.watch(communityCreatorsProvider((mode, creatorOffset))),
            retry: () => ref.invalidate(
              communityCreatorsProvider((mode, creatorOffset)),
            ),
            data: (page) => Column(
              children: [
                if (page.items.isEmpty)
                  const CommunityEmpty()
                else
                  CreatorRail(profiles: page.items),
                CommunityPager(
                  offset: creatorOffset,
                  next: page.nextOffset,
                  onPage: (value) => setState(() => creatorOffset = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionHeading(t.v3NewReleases),
          const SizedBox(height: 12),
          CommunityAsync(
            value: ref.watch(communitySongsProvider(freshKey)),
            retry: () => ref.invalidate(communitySongsProvider(freshKey)),
            data: (page) => page.items.isEmpty
                ? const CommunityEmpty()
                : SongArtworkRail(songs: page.items.take(8).toList()),
          ),
          const SizedBox(height: 24),
          SectionHeading(t.v3Genres),
          const SizedBox(height: 16),
          CommunityAsync(
            value: ref.watch(communityGenresProvider),
            retry: () => ref.invalidate(communityGenresProvider),
            data: (items) => items.isEmpty
                ? const CommunityEmpty()
                : GenreTiles(
                    genres: items,
                    selected: genre,
                    onSelect: (value) => context.go(
                      Uri(
                        path: '/explore',
                        queryParameters: {'genre': value},
                      ).toString(),
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          SectionHeading(t.v3NewCreators),
          const SizedBox(height: 16),
          CommunityAsync(
            value: ref.watch(communityCreatorsProvider(('emerging', 0))),
            retry: () =>
                ref.invalidate(communityCreatorsProvider(('emerging', 0))),
            data: (page) => page.items.isEmpty
                ? const CommunityEmpty()
                : CreatorRail(profiles: page.items),
          ),
        ],
      ),
    );
  }
}
