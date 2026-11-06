import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';
import '../../home/domain/song.dart';
import '../application/search_provider.dart';
import '../domain/discovery.dart';
import 'sample_collection_tile.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({
    super.key,
    this.filters = const DiscoveryFilters(),
    this.privateLibrary = false,
  });
  final DiscoveryFilters filters;
  final bool privateLibrary;
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
    context.replace(
      widget.privateLibrary
          ? filters.location.replaceFirst('/explore', '/library/search')
          : filters.location,
    );
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
    final t = context.l10n;
    final filters = widget.filters;
    final catalog = ref.watch(catalogProvider);
    return AppScaffold(
      child: ListView(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          ScreenHeading(
            eyebrow: t.appName.toUpperCase(),
            title: widget.privateLibrary ? t.v3LibrarySearch : t.exploreTitle,
            subtitle: ref.watch(demoModeProvider)
                ? t.exploreSubtitleDemo
                : t.exploreSubtitleReal,
          ),
          const SizedBox(height: 24),
          MysticSearchBar(
            controller: searchController,
            onChanged: (value) => _update(filters.withQuery(value)),
            onClear: filters.query.isEmpty
                ? null
                : () => _update(filters.withQuery('')),
          ),
          if (filters.isActive) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  t.combinedFilters,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () =>
                      _update(const DiscoveryFilters(), resetView: true),
                  child: Text(t.clearAll),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          catalog.when(
            loading: () => const CatalogLoading(),
            error: (_, _) => const CatalogError(),
            data: (songs) => _discovery(songs, filters),
          ),
        ],
      ),
    );
  }

  Widget _discovery(
    List<Song> songs,
    DiscoveryFilters filters, {
    List<Song>? serverMatches,
  }) {
    final t = context.l10n;
    final sample = ref.watch(demoModeProvider);
    if (!sample && filters.isActive && serverMatches == null) {
      return ref
          .watch(searchProvider(filters))
          .when(
            loading: () => const CatalogLoading(),
            error: (_, _) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: t.searchFailed,
              message: t.searchFailureMessage,
              actionLabel: t.tryAgain,
              onAction: () => ref.invalidate(searchProvider(filters)),
            ),
            data: (matches) =>
                _discovery(songs, filters, serverMatches: matches),
          );
    }
    if (songs.isEmpty) {
      return GlassCard(
        child: EmptyState(
          icon: Icons.library_music_outlined,
          title: sample ? t.sampleEmpty : t.libraryEmpty,
          message: sample ? t.homeEmptyDemo : t.uploadToDiscover,
          actionLabel: sample ? null : t.uploadTrack,
          onAction: () => context.go('/upload'),
        ),
      );
    }
    final genres = catalogGenres(songs);
    final collection = findSampleCollection(filters.collectionId);
    final matches = serverMatches == null
        ? matchingSongIndices(songs, filters)
        : [
            for (var i = 0; i < songs.length; i++)
              if (serverMatches.any(
                (song) => song.identity == songs[i].identity,
              ))
                i,
          ];
    final results = _results(songs, matches, filters, collection);
    final choices = _choices(songs, genres, filters, collection);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A typed query brings its results into view before the browse controls.
        if (filters.query.isNotEmpty) ...[
          results,
          const SizedBox(height: 32),
          choices,
        ] else ...[
          choices,
          const SizedBox(height: 28),
          results,
        ],
        const SizedBox(height: 24),
        Text(
          sample ? t.songsDemoCaption : t.songsPrivateCaption,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _choices(
    List<Song> songs,
    List<String> genres,
    DiscoveryFilters filters,
    SampleCollection? collection,
  ) {
    final t = context.l10n;
    final sample = ref.watch(demoModeProvider);
    final hasUnknownGenre =
        filters.genre != null &&
        !genres.any(
          (genre) => genre.toLowerCase() == filters.genre!.toLowerCase(),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(t.browseGenres),
        const SizedBox(height: 12),
        ChoiceChip(
          label: Text(t.allGenres),
          selected: filters.genre == null,
          onSelected: (_) => _update(filters.withGenre(null)),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 4 : 2;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < genres.length; i++)
                  _GenreChoice(
                    genre: genres[i],
                    width: width,
                    accent: switch (i % 4) {
                      0 => AppColors.mystic,
                      1 => AppColors.cyan,
                      2 => AppColors.pink,
                      _ => AppColors.violet,
                    },
                    selected:
                        genres[i].toLowerCase() == filters.genre?.toLowerCase(),
                    compact: filters.isActive,
                    onSelected: (selected) =>
                        _update(filters.withGenre(selected ? genres[i] : null)),
                  ),
              ],
            );
          },
        ),
        if (hasUnknownGenre)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InputChip(
              label: Text(filters.genre!, softWrap: true),
              selected: true,
              deleteButtonTooltipMessage: t.removeUnknownGenre,
              onDeleted: () => _update(filters.withGenre(null)),
            ),
          ),
        const SizedBox(height: 28),
        SectionHeading(sample ? t.collectionsDemo : t.collectionsReal),
        const SizedBox(height: 8),
        Text(t.collectionsHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(t.allCollections),
              selected: filters.collectionId == null,
              onSelected: (_) => _update(filters.withCollection(null)),
            ),
            for (final item in sampleCollections)
              ChoiceChip(
                label: Text(
                  '${localizedCollectionTitle(context, item)} · ${songs.where(item.contains).length}',
                ),
                selected: filters.collectionId == item.id,
                onSelected: (selected) =>
                    _update(filters.withCollection(selected ? item.id : null)),
              ),
            if (filters.collectionId != null && collection == null)
              InputChip(
                label: Text(t.unknownCollection),
                selected: true,
                deleteButtonTooltipMessage: t.removeUnknownCollection,
                onDeleted: () => _update(filters.withCollection(null)),
              ),
          ],
        ),
        if (collection != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              localizedCollectionDescription(context, collection),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.secondaryText),
            ),
          ),
      ],
    );
  }

  Widget _results(
    List<Song> songs,
    List<int> matches,
    DiscoveryFilters filters,
    SampleCollection? collection,
  ) {
    final t = context.l10n;
    final sample = ref.watch(demoModeProvider);
    final emptyCollection =
        collection != null && !songs.any(collection.contains);
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey('${filters.location}|${matches.join(',')}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: SectionHeading(
              filters.isActive
                  ? t.resultsCount(matches.length)
                  : sample
                  ? t.catalogDemo
                  : t.yourTracks,
            ),
          ),
          const SizedBox(height: 12),
          if (matches.isEmpty)
            GlassCard(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: filters.collectionId != null && collection == null
                    ? t.collectionUnavailable
                    : emptyCollection
                    ? t.collectionQuiet
                    : t.noResults,
                message: emptyCollection
                    ? (sample ? t.collectionEmptyDemo : t.collectionEmptyReal)
                    : t.noResultsHint,
                actionLabel: filters.query.isNotEmpty
                    ? t.clearSearch
                    : t.browseAllTracks,
                onAction: () => _update(
                  filters.query.isNotEmpty
                      ? filters.withQuery('')
                      : const DiscoveryFilters(),
                  resetView: true,
                ),
              ),
            )
          else
            for (final index in matches)
              SongTile(song: songs[index], index: index),
        ],
      ),
    );
  }
}

class _GenreChoice extends StatelessWidget {
  const _GenreChoice({
    required this.genre,
    required this.width,
    required this.accent,
    required this.selected,
    required this.compact,
    required this.onSelected,
  });
  final String genre;
  final double width;
  final Color accent;
  final bool selected;
  final bool compact;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: selected ? .32 : .18),
          AppColors.surface.withValues(alpha: .8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: ChoiceChip(
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      selectedColor: Colors.transparent,
      side: BorderSide(color: selected ? accent : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 8 : 16),
      label: SizedBox(
        width: width - 48,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Icon(Icons.graphic_eq_rounded, color: accent, size: 24),
              const SizedBox(height: 16),
            ],
            Text(genre, style: Theme.of(context).textTheme.titleSmall),
            if (selected) Icon(Icons.check_rounded, color: accent, size: 18),
          ],
        ),
      ),
    ),
  );
}
