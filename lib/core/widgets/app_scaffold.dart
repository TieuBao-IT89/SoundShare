import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/theme/app_theme.dart';
import '../services/audio_service.dart';
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
    final song = ref.watch(currentSongProvider);
    final hasSelection = ref.watch(hasSelectedSongProvider);
    final loading = ref.watch(playbackLoadingProvider);
    final error = ref.watch(playbackErrorProvider);
    final player = ref.watch(audioPlayerProvider);
    final actions = ref.watch(playbackActionsProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMiniPlayer && hasSelection && song != null)
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                initialData: player.playerState,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Container(
                    key: const ValueKey('mini-player'),
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
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
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
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
                                          error == null
                                              ? song.artist
                                              : 'Playback unavailable',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: error == null
                                                ? AppColors.muted
                                                : AppColors.error,
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
                          tooltip: playing ? 'Pause track' : 'Resume track',
                          onPressed: loading ? null : actions.togglePlayback,
                          icon: loading
                              ? MediaQuery.disableAnimationsOf(context)
                                    ? const Icon(Icons.hourglass_top_rounded)
                                    : const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                              : Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                        ),
                        IconButton(
                          tooltip: 'Play next track',
                          onPressed: loading ? null : () => actions.skip(1),
                          icon: const Icon(Icons.skip_next_rounded),
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
