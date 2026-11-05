import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../home/application/catalog_provider.dart';
import '../../home/domain/song.dart';
import '../domain/discovery.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key, this.filters = const DiscoveryFilters()});
  final DiscoveryFilters filters;
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final scrollController = ScrollController();
  late final searchController = TextEditingController(
    text: widget.filters.query,
  );

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (searchController.text != widget.filters.query) {
      searchController.value = TextEditingValue(
        text: widget.filters.query,
        selection: TextSelection.collapsed(offset: widget.filters.query.length),
      );
    }
  }

  void _update(DiscoveryFilters filters, {bool resetView = false}) {
    context.replace(filters.location);
    if (resetView) {
      FocusScope.of(context).unfocus();
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.filters;
    final catalog = ref.watch(catalogProvider);
    return AppScaffold(
      child: ListView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const ScreenHeading(
            eyebrow: 'EXPLORE',
            title: 'Follow your ears.',
            subtitle: 'Start with a genre, a collection, or a name. All tracks here are samples.',
          ),
          const SizedBox(height: 22),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            maxLength: 120,
            onChanged: (value) => _update(filters.withQuery(value)),
            decoration: InputDecoration(
              labelText: 'Search music',
              hintText: 'Title, artist, or genre',
              counterText: '',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: filters.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () => _update(filters.withQuery('')),
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          if (filters.isActive) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Your choices are combined',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                TextButton(
                  onPressed: () =>
                      _update(const DiscoveryFilters(), resetView: true),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          catalog.when(
            loading: () => const CatalogLoading(),
            error: (_, _) => const CatalogError(),
            data: (songs) => _discovery(songs, filters),
          ),
        ],
      ),
    );
  }

  Widget _discovery(List<Song> songs, DiscoveryFilters filters) {
    if (songs.isEmpty) {
      return const EmptyState(
        icon: Icons.library_music_outlined,
        title: 'The sample catalog is empty',
        message: 'Genres and collections will have music when sample tracks are available.',
      );
    }
    final genres = catalogGenres(songs);
    final collection = findSampleCollection(filters.collectionId);
    final matches = matchingSongIndices(songs, filters);
    final hasUnknownGenre =
        filters.genre != null &&
        !genres.any(
          (genre) => genre.toLowerCase() == filters.genre!.toLowerCase(),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Browse by genre'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('All genres'),
              selected: filters.genre == null,
              onSelected: (_) => _update(filters.withGenre(null)),
            ),
            for (final genre in genres)
              ChoiceChip(
                label: Text(genre),
                selected: genre.toLowerCase() == filters.genre?.toLowerCase(),
                onSelected: (selected) =>
                    _update(filters.withGenre(selected ? genre : null)),
              ),
            if (hasUnknownGenre)
              InputChip(
                label: Text(filters.genre!, softWrap: true),
                selected: true,
                deleteButtonTooltipMessage: 'Remove unavailable genre',
                onDeleted: () => _update(filters.withGenre(null)),
              ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeading('Sample collections'),
        const SizedBox(height: 6),
        const Text(
          'Small selections grouped by genre.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: const Text('All collections'),
              selected: filters.collectionId == null,
              onSelected: (_) => _update(filters.withCollection(null)),
            ),
            for (final item in sampleCollections)
              ChoiceChip(
                label: Text(
                  '${item.title} · ${songs.where(item.contains).length}',
                ),
                selected: filters.collectionId == item.id,
                onSelected: (selected) =>
                    _update(filters.withCollection(selected ? item.id : null)),
              ),
            if (filters.collectionId != null && collection == null)
              InputChip(
                label: const Text('Unavailable collection'),
                selected: true,
                deleteButtonTooltipMessage: 'Remove unavailable collection',
                onDeleted: () => _update(filters.withCollection(null)),
              ),
          ],
        ),
        if (collection != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              collection.description,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        const SizedBox(height: 26),
        Semantics(
          liveRegion: true,
          child: SectionHeading(
            filters.isActive
                ? '${matches.length} ${matches.length == 1 ? 'track' : 'tracks'} found'
                : 'The sample catalog',
          ),
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: filters.collectionId != null && collection == null
                ? 'This collection is unavailable'
                : collection != null && !songs.any(collection.contains)
                ? 'This collection is quiet'
                : 'No tracks found',
            message: collection != null && !songs.any(collection.contains)
                ? 'There are no sample tracks in this collection yet. Try another collection or browse all tracks.'
                : 'Try another genre or collection, or clear your search.',
            actionLabel: filters.query.isNotEmpty
                ? 'Clear search'
                : 'Browse all tracks',
            onAction: () => _update(
              filters.query.isNotEmpty
                  ? filters.withQuery('')
                  : const DiscoveryFilters(),
              resetView: true,
            ),
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
  }
}
