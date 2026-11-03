import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/section_heading.dart';
import '../domain/song.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A listening room for independent music.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tracks worth a closer listen.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Share a track',
                    onPressed: () => context.push('/upload'),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _SectionTitle(
                'Start with a sample track',
                action: 'Explore',
                onTap: () => context.go('/explore'),
              ),
              const SizedBox(height: 14),
              if (sampleSongs.isNotEmpty)
                _FeaturedTrack(
                  song: sampleSongs.first,
                  onTap: () => context.push('/player'),
                )
              else
                const EmptyState(
                  icon: Icons.library_music_outlined,
                  title: 'The listening room is quiet',
                  message:
                      'Shared tracks will appear here when they are ready.',
                ),
              const SizedBox(height: 28),
              const _SectionTitle('From the sample library'),
              const SizedBox(height: 8),
              ...sampleSongs
                  .take(3)
                  .map(
                    (song) => _SongTile(
                      song: song,
                      onTap: () => context.push('/player'),
                    ),
                  ),
              const SizedBox(height: 20),
              const _SectionTitle('More sample tracks'),
              const SizedBox(height: 14),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sampleSongs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => context.push('/player'),
                    child: SizedBox(
                      width: 128,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Artwork(
                            url: sampleSongs[index].artwork,
                            size: 128,
                            radius: 18,
                          ),
                          const SizedBox(height: 9),
                          Text(
                            sampleSongs[index].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            sampleSongs[index].artist,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onTap,
          child: Text(action!, style: const TextStyle(color: AppColors.violet)),
        ),
    ],
  );
}

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song, required this.onTap});
  final Song song;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    onTap: onTap,
    leading: Artwork(
      url: song.artwork,
      semanticLabel: 'Artwork for ${song.title}',
    ),
    title: Text(
      song.title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${song.artist} · ${song.genre}',
      style: const TextStyle(color: AppColors.muted),
    ),
    trailing: IconButton(
      tooltip: 'Play ${song.title}',
      onPressed: onTap,
      icon: const Icon(
        Icons.play_circle_outline_rounded,
        color: AppColors.violet,
        size: 27,
      ),
    ),
  );
}

class _FeaturedTrack extends StatelessWidget {
  const _FeaturedTrack({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Artwork(
              url: song.artwork,
              size: 116,
              radius: 14,
              semanticLabel: 'Artwork for ${song.title}',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAMPLE TRACK',
                    style: TextStyle(
                      color: AppColors.mint,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.play_arrow_rounded, color: AppColors.violet),
                      SizedBox(width: 4),
                      Text(
                        'Listen now',
                        style: TextStyle(
                          color: AppColors.violet,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
