import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../home/domain/song.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final results = sampleSongs
        .where(
          (song) => '${song.title} ${song.artist}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Songs, artists, and more',
              ),
            ),
            const SizedBox(height: 22),
            Text(
              query.isEmpty ? 'Recently shared' : '${results.length} results',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.music_off_rounded,
                            size: 42,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No tracks found',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try another title or artist',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final song = results[index];
                        return ListTile(
                          onTap: () => context.push('/player'),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: Artwork(url: song.artwork),
                          title: Text(song.title),
                          subtitle: Text(
                            song.artist,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          trailing: const Icon(
                            Icons.play_circle_outline,
                            color: AppColors.violet,
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
}
