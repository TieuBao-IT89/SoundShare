import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../home/application/catalog_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final searchController = TextEditingController();
  String query = '';
  void clearSearch() {
    searchController.clear();
    setState(() => query = '');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    child: ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const ScreenHeading(
          eyebrow: 'EXPLORE',
          title: 'Follow your ears.',
          subtitle: 'Find a track, an artist, or a different direction.',
        ),
        const SizedBox(height: 22),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => query = value.trim()),
          decoration: InputDecoration(
            labelText: 'Search music',
            hintText: 'Title, artist, or genre',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: clearSearch,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 22),
        ref
            .watch(catalogProvider)
            .when(
              loading: () => const CatalogLoading(),
              error: (_, _) => const CatalogError(),
              data: (songs) {
                final matches = [
                  for (var i = 0; i < songs.length; i++)
                    if ('${songs[i].title} ${songs[i].artist} ${songs[i].genre}'
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                      i,
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: SectionHeading(
                        query.isEmpty
                            ? 'The sample catalog'
                            : '${matches.length} ${matches.length == 1 ? 'track' : 'tracks'} found',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (matches.isEmpty)
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: query.isEmpty
                            ? 'No tracks here yet'
                            : 'No tracks found',
                        message: 'Try another title, artist, or genre.',
                        actionLabel: query.isEmpty ? null : 'Clear search',
                        onAction: clearSearch,
                      )
                    else
                      for (final index in matches)
                        SongTile(song: songs[index], index: index),
                    const SizedBox(height: 18),
                    const Text(
                      'Sample tracks and artists · Demo audio',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
      ],
    ),
  );
}
