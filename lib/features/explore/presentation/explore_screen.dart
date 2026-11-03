import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/section_heading.dart';
import '../../home/domain/song.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String query = '';
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = sampleSongs
        .where(
          (song) => '${song.title} ${song.artist} ${song.genre}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore the catalog',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search tracks shared by independent artists.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search tracks, artists, or genres',
                labelText: 'Search music',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          searchController.clear();
                          setState(() => query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            SectionHeading(
              query.isEmpty ? 'Sample tracks' : _resultLabel(results.length),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: Icons.music_off_rounded,
                      title: query.isEmpty
                          ? 'No sample tracks yet'
                          : 'No tracks found',
                      message: query.isEmpty
                          ? 'Tracks will appear here when the sample catalog is ready.'
                          : 'Try another title, artist, or genre.',
                      actionLabel: query.isEmpty ? null : 'Clear search',
                      onAction: query.isEmpty
                          ? null
                          : () {
                              searchController.clear();
                              setState(() => query = '');
                            },
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final song = results[index];
                        return ListTile(
                          onTap: () => context.push('/player'),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          leading: Artwork(
                            url: song.artwork,
                            semanticLabel: 'Artwork for ${song.title}',
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${song.artist} · ${song.genre}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          trailing: IconButton(
                            tooltip: 'Play ${song.title}',
                            onPressed: () => context.push('/player'),
                            icon: const Icon(
                              Icons.play_circle_outline,
                              color: AppColors.violet,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _resultLabel(int count) =>
      '$count ${count == 1 ? 'track' : 'tracks'} found';
}
