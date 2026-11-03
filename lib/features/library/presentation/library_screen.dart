import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/section_heading.dart';
import '../../home/domain/song.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Text(
          'Your listening shelf',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sample tracks show how saved and shared music will live here.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _CollectionCard(
                icon: Icons.favorite_rounded,
                title: 'Liked songs',
                subtitle: 'Sample collection',
                color: AppColors.violet,
                onTap: () => context.push('/player'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CollectionCard(
                icon: Icons.queue_music_rounded,
                title: 'Playlists',
                subtitle: 'Not in this preview',
                color: AppColors.muted,
                onTap: null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(child: SectionHeading('Community samples')),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Share'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sampleSongs.isEmpty)
          const EmptyState(
            icon: Icons.library_music_outlined,
            title: 'Your shelf is waiting',
            message: 'Sample tracks will appear here when they are available.',
          )
        else
          ...sampleSongs
              .take(3)
              .map(
                (song) => ListTile(
                  onTap: () => context.push('/player'),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
                      Icons.play_circle_outline_rounded,
                      color: AppColors.violet,
                    ),
                  ),
                ),
              ),
      ],
    ),
  );
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: '$title, $subtitle',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
