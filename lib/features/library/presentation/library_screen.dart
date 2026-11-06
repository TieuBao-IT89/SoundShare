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

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool? showAll;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final demo = ref.watch(demoModeProvider);
    final all = showAll ?? !demo;
    final catalog = ref.watch(catalogProvider);
    final liked = ref.watch(likedSongIndicesProvider);
    final total = catalog.asData?.value.length;
    final favorites = total == null ? null : liked.length;

    return AppScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxWidth >= 680;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              roomy ? 36 : 20,
              28,
              roomy ? 36 : 20,
              32,
            ),
            children: [
              if (!demo) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/library/search'),
                      icon: const Icon(Icons.search_rounded),
                      label: Text(t.v3LibrarySearch),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/playlists'),
                      icon: const Icon(Icons.queue_music_rounded),
                      label: Text(t.v3Playlists),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/saved'),
                      icon: const Icon(Icons.bookmark_outline_rounded),
                      label: Text(t.v3SavedTracks),
                    ),
                    TextButton(
                      onPressed: () => context.push('/manage-songs'),
                      child: Text(t.v3ManageSongs),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              AuroraReveal(
                child: ScreenHeading(
                  eyebrow: t.libraryEyebrow,
                  title: t.libraryTitle,
                  subtitle: t.librarySubtitle,
                  action: IconButton.filledTonal(
                    tooltip: t.uploadMusic,
                    onPressed: () => context.push('/upload'),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AuroraReveal(
                delay: 60,
                child: LayoutBuilder(
                  builder: (context, shelf) {
                    final cards = [
                      _CollectionSelector(
                        selected: !all,
                        title: t.likedTracks,
                        count: !demo
                            ? null
                            : favorites == null
                            ? '—'
                            : t.likedCount(favorites),
                        caption: demo
                            ? t.librarySavedSession
                            : t.librarySavedPrivate,
                        icon: Icons.favorite_rounded,
                        accent: AppColors.pink,
                        onTap: () {
                          if (demo) {
                            setState(() => showAll = false);
                          } else {
                            context.push('/liked');
                          }
                        },
                      ),
                      _CollectionSelector(
                        selected: all,
                        title: demo ? t.sampleCatalog : t.allUploads,
                        count: total == null
                            ? '—'
                            : (demo
                                  ? t.sampleCount(total)
                                  : t.trackCount(total)),
                        caption: demo ? t.demoNotice : t.privateLibraryNotice,
                        icon: Icons.library_music_rounded,
                        accent: AppColors.cyan,
                        onTap: () => setState(() => showAll = true),
                      ),
                    ];
                    if (shelf.maxWidth >= 560 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 22) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: 12),
                        cards[1],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              SectionHeading(
                all ? (demo ? t.sampleCatalog : t.allUploads) : t.yourFavorites,
              ),
              const SizedBox(height: 12),
              catalog.when(
                loading: () => const CatalogLoading(),
                error: (_, _) => const CatalogError(),
                data: (songs) {
                  final indices = [
                    for (var i = 0; i < songs.length; i++)
                      if (all || liked.contains(i)) i,
                  ];
                  if (indices.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 24,
                      ),
                      child: Column(
                        children: [
                          EmptyState(
                            icon: all
                                ? Icons.library_music_outlined
                                : Icons.favorite_border_rounded,
                            title: all
                                ? (demo ? t.sampleEmpty : t.libraryEmptyTitle)
                                : t.favoritesEmptyTitle,
                            message: all
                                ? (demo
                                      ? t.homeEmptyDemo
                                      : t.libraryEmptyMessage)
                                : t.favoritesEmptyMessage,
                            actionLabel: t.exploreMusic,
                            onAction: () => context.go('/explore'),
                          ),
                          if (all && !demo)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: GradientButton(
                                label: t.uploadMusic,
                                icon: Icons.upload_rounded,
                                onPressed: () => context.push('/upload'),
                              ),
                            ),
                        ],
                      ),
                    );
                  }
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        for (final index in indices)
                          SongTile(song: songs[index], index: index),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    demo
                        ? Icons.info_outline_rounded
                        : Icons.lock_outline_rounded,
                    color: AppColors.secondaryText,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      demo ? t.demoLibraryNote : t.libraryPrivacyNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CollectionSelector extends StatelessWidget {
  const _CollectionSelector({
    required this.selected,
    required this.title,
    required this.count,
    required this.caption,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String? count;
  final String caption;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: selected ? AppColors.surfaceLight : AppColors.surface,
        border: Border.all(
          color: selected ? accent.withValues(alpha: .65) : AppColors.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accent, size: 30),
                    const Spacer(),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: accent, size: 22),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                if (count != null)
                  Text(
                    count!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.text),
                  ),
                const SizedBox(height: 10),
                Text(
                  caption,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.secondaryText, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
