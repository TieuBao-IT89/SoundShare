import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';

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
  Widget build(BuildContext context) {
    final t = context.l10n;
    final query = (
      path: genre == null ? '/discover/trending' : '/discover/new-releases',
      offset: offset,
      period: genre == null ? period : null,
      genre: genre,
    );
    final songs = ref.watch(communitySongsProvider(query));
    final creators = ref.watch(
      communityCreatorsProvider((mode, creatorOffset)),
    );
    return AppScaffold(
      child: ListView(
        key: const PageStorageKey('discovery-hub'),
        padding: const EdgeInsets.all(24),
        children: [
          ScreenHeading(
            eyebrow: t.explore,
            title: t.v3DiscoverTitle,
            subtitle: t.v3DiscoverSubtitle,
            action: IconButton(
              tooltip: t.search,
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 32),
          SectionHeading(t.v3Genres),
          const SizedBox(height: 16),
          CommunityAsync(
            value: ref.watch(communityGenresProvider),
            retry: () => ref.invalidate(communityGenresProvider),
            data: (items) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ChoiceChip(
                  label: Text(t.allGenres),
                  selected: genre == null,
                  onSelected: (_) => setState(() {
                    genre = null;
                    offset = 0;
                  }),
                ),
                for (var i = 0; i < items.length; i++)
                  ChoiceChip(
                    label: Text(items[i]),
                    avatar: Icon(
                      i.isEven
                          ? Icons.album_outlined
                          : Icons.graphic_eq_rounded,
                      size: 18,
                      color: i.isEven ? AppColors.cyan : AppColors.mystic,
                    ),
                    selected: genre == items[i],
                    onSelected: (_) => setState(() {
                      genre = items[i];
                      offset = 0;
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SectionHeading(genre ?? t.v3Trending),
          const SizedBox(height: 12),
          if (genre == null) ...[
            Text(
              t.v3TrendingNote,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in [
                  ('today', t.v3Today),
                  ('week', t.v3Week),
                  ('month', t.v3Month),
                  ('all', t.v3AllTime),
                ])
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: period == item.$1,
                    onSelected: (_) => setState(() {
                      period = item.$1;
                      offset = 0;
                    }),
                  ),
              ],
            ),
          ],
          CommunityAsync(
            value: songs,
            retry: () => ref.invalidate(communitySongsProvider(query)),
            data: (page) => Column(
              children: [
                if (page.items.isEmpty) const CommunityEmpty(),
                for (var i = 0; i < page.items.length; i++)
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
          const SizedBox(height: 40),
          SectionHeading(mode == 'emerging' ? t.v3NewCreators : t.v3Creators),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                ('featured', t.v3Featured),
                ('new', t.v3Newest),
                ('popular', t.v3Popular),
                ('growing', t.v3Growing),
                ('emerging', t.v3NewCreators),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: mode == item.$1,
                  onSelected: (_) => setState(() {
                    mode = item.$1;
                    creatorOffset = 0;
                  }),
                ),
            ],
          ),
          CommunityAsync(
            value: creators,
            retry: () => ref.invalidate(
              communityCreatorsProvider((mode, creatorOffset)),
            ),
            data: (page) => Column(
              children: [
                if (page.items.isEmpty) const CommunityEmpty(),
                for (final profile in page.items) CreatorRow(profile: profile),
                CommunityPager(
                  offset: creatorOffset,
                  next: page.nextOffset,
                  onPage: (value) => setState(() => creatorOffset = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
