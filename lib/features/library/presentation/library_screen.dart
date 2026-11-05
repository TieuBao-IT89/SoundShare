import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../home/application/catalog_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool? showAll;
  @override
  Widget build(BuildContext context) {
    final samples = showAll ?? !ref.watch(demoModeProvider);
    final liked = ref.watch(likedSongIndicesProvider);
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          ScreenHeading(
            eyebrow: 'YOUR LIBRARY',
            title: 'Keep the good ones.',
            subtitle: 'A little shelf for the tracks you want to hear again.',
            action: IconButton(
              tooltip: 'Prepare a track',
              onPressed: () => context.push('/upload'),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.violet,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${liked.length} liked ${liked.length == 1 ? 'track' : 'tracks'}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ref.watch(demoModeProvider)
                            ? 'Saved for this listening session'
                            : 'Saved to your account',
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Liked tracks'),
                selected: !samples,
                onSelected: (_) => setState(() => showAll = false),
              ),
              ChoiceChip(
                label: Text(
                  ref.watch(demoModeProvider)
                      ? 'Sample catalog'
                      : 'All uploads',
                ),
                selected: samples,
                onSelected: (_) => setState(() => showAll = true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ref
              .watch(catalogProvider)
              .when(
                loading: () => const CatalogLoading(),
                error: (_, _) => const CatalogError(),
                data: (songs) {
                  final indices = [
                    for (var i = 0; i < songs.length; i++)
                      if (samples || liked.contains(i)) i,
                  ];
                  if (indices.isEmpty) {
                    return EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: samples
                          ? (ref.watch(demoModeProvider)
                                ? 'No sample tracks yet'
                                : 'No uploads yet')
                          : 'Find your first favorite',
                      message:
                          'Tap the heart in the player to keep a track here.',
                      actionLabel: 'Explore tracks',
                      onAction: () => context.go('/explore'),
                    );
                  }
                  return Column(
                    children: [
                      for (final index in indices)
                        SongTile(song: songs[index], index: index),
                    ],
                  );
                },
              ),
          const SizedBox(height: 24),
          Text(
            ref.watch(demoModeProvider)
                ? 'Likes are kept during this session. Playlists and library sync are coming later.'
                : 'Your uploads and likes are saved to your account. Files stay private.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
