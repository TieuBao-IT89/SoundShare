import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';
import '../services/audio_service.dart';
import 'artwork.dart';
import 'section_heading.dart';

void openCatalogSong(BuildContext context, WidgetRef ref, int index) {
  ref.read(playbackActionsProvider).play(index);
  context.push('/player');
}

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.violet,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 10),
      Semantics(
        header: true,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            height: 1.12,
            fontWeight: FontWeight.w700,
            letterSpacing: -.6,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, height: 1.45),
      ),
    ],
  );
}

class CatalogLoading extends StatelessWidget {
  const CatalogLoading({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Loading music library',
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
        ],
      ),
    ),
  );
}

class CatalogError extends ConsumerWidget {
  const CatalogError({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    icon: Icons.cloud_off_outlined,
    title: 'The music is taking a moment',
    message: 'We could not load the catalog. Try again when you are connected.',
    actionLabel: 'Try again',
    onAction: () => ref.invalidate(catalogProvider),
  );
}

class SongTile extends ConsumerWidget {
  const SongTile({super.key, required this.song, required this.index});
  final Song song;
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 6),
    onTap: () => openCatalogSong(context, ref, index),
    leading: Artwork(
      url: song.artwork,
      semanticLabel: 'Artwork for ${song.title}',
    ),
    title: Text(
      song.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      '${song.artist} · ${song.genre}',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.muted),
    ),
    trailing: IconButton(
      tooltip: 'Play ${song.title}',
      onPressed: () => openCatalogSong(context, ref, index),
      icon: const Icon(
        Icons.play_circle_outline_rounded,
        color: AppColors.violet,
      ),
    ),
  );
}
