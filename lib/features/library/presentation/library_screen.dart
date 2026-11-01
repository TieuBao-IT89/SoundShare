import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../home/domain/song.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      children: [
        const Text(
          'Your library',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _CollectionCard(
                icon: Icons.favorite_rounded,
                title: 'Liked songs',
                subtitle: '12 tracks',
                color: AppColors.violet,
                onTap: () => context.push('/player'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CollectionCard(
                icon: Icons.queue_music_rounded,
                title: 'Playlists',
                subtitle: 'Make a mix',
                color: AppColors.mint,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your uploads',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Upload'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sampleSongs
            .take(2)
            .map(
              (song) => ListTile(
                onTap: () => context.push('/player'),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: Artwork(url: song.artwork),
                title: Text(song.title),
                subtitle: Text(
                  song.artist,
                  style: const TextStyle(color: AppColors.muted),
                ),
                trailing: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.muted,
                ),
              ),
            ),
        const SizedBox(height: 22),
        const Text(
          'Made for you',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ListTile(
          onTap: () => context.push('/explore'),
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.surfaceLight,
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.violet),
          ),
          title: const Text('Discover weekly'),
          subtitle: const Text(
            'A fresh mix every week',
            style: TextStyle(color: AppColors.muted),
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
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
