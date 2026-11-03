import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/audio_service.dart';
import '../../features/home/domain/song.dart';
import 'artwork.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.showMiniPlayer = true,
  });
  final Widget child;
  final bool showMiniPlayer;

  int _index(String location) => switch (location) {
    '/explore' => 1,
    '/library' => 2,
    '/profile' => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final player = ref.watch(audioPlayerProvider);
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMiniPlayer)
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  if (snapshot.data?.playing != true) {
                    return const SizedBox.shrink();
                  }
                  final song =
                      sampleSongs[ref.watch(currentSongIndexProvider) %
                          sampleSongs.length];
                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/player'),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Artwork(
                                    url: song.artwork,
                                    size: 42,
                                    radius: 10,
                                    semanticLabel: 'Artwork for ${song.title}',
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          song.artist,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Pause ${song.title}',
                          onPressed: player.pause,
                          icon: const Icon(Icons.pause_rounded, size: 25),
                        ),
                        IconButton(
                          tooltip: 'Play next track',
                          onPressed: () async {
                            final next =
                                (ref.read(currentSongIndexProvider) + 1) %
                                sampleSongs.length;
                            ref.read(currentSongIndexProvider.notifier).state =
                                next;
                            try {
                              await player.setUrl(sampleSongs[next].audioUrl);
                              unawaited(player.play());
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.skip_next_rounded, size: 24),
                        ),
                      ],
                    ),
                  );
                },
              ),
            NavigationBar(
              selectedIndex: _index(location),
              onDestinationSelected: (index) =>
                  context.go(['/', '/explore', '/library', '/profile'][index]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  label: 'Explore',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
