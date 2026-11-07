import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';
import 'music_components.dart';

class SearchSuggestions extends ConsumerWidget {
  const SearchSuggestions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const query = (
      path: '/discover/trending',
      offset: 0,
      period: 'week',
      genre: null as String?,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        SectionHeading(context.l10n.v4Browse),
        const SizedBox(height: 12),
        CommunityAsync(
          value: ref.watch(communitySongsProvider(query)),
          retry: () => ref.invalidate(communitySongsProvider(query)),
          data: (page) => page.items.isEmpty
              ? const SizedBox.shrink()
              : SongColumns(songs: page.items.take(3).toList(), ranked: true),
        ),
        const SizedBox(height: 20),
        SectionHeading(context.l10n.v3Creators),
        const SizedBox(height: 12),
        CommunityAsync(
          value: ref.watch(communityCreatorsProvider(('featured', 0))),
          retry: () =>
              ref.invalidate(communityCreatorsProvider(('featured', 0))),
          data: (page) => page.items.isEmpty
              ? const CommunityEmpty()
              : CreatorRail(profiles: page.items.take(6).toList()),
        ),
      ],
    );
  }
}
