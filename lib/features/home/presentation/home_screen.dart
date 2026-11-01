import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
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
                          'MONDAY, OCTOBER 31',
                          style: TextStyle(
                            color: AppColors.muted,
                            letterSpacing: 1.5,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Good evening, Alex',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/upload'),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _SectionTitle(
                'Made for your mood',
                action: 'See all',
                onTap: () => context.go('/explore'),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push('/player'),
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6045A8), Color(0xFF282444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Opacity(
                            opacity: .55,
                            child: Artwork(
                              url: sampleSongs[0].artwork,
                              size: 190,
                              radius: 24,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'YOUR DAILY MIX',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                color: Color(0xFFD4C7FF),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Soft focus',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Fresh sounds for slower days',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Text(
                                'PLAY MIX  →',
                                style: TextStyle(
                                  color: Color(0xFF182013),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionTitle('Recently shared'),
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
              const _SectionTitle('Find your next favorite'),
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
    leading: Artwork(url: song.artwork),
    title: Text(
      song.title,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${song.artist}  ·  ${song.genre}',
      style: const TextStyle(color: AppColors.muted),
    ),
    trailing: IconButton(
      onPressed: onTap,
      icon: const Icon(
        Icons.play_circle_outline_rounded,
        color: AppColors.violet,
        size: 27,
      ),
    ),
  );
}
