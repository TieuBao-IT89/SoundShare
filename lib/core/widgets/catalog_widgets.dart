import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';
import '../../l10n/l10n.dart';
import '../services/audio_service.dart';
import 'artwork.dart';
import 'aurora_widgets.dart';
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
  final String eyebrow, title, subtitle;
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
                color: AppColors.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
              ),
            ),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 12),
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        style: const TextStyle(color: AppColors.secondaryText, height: 1.6),
      ),
    ],
  );
}

class CatalogLoading extends StatelessWidget {
  const CatalogLoading({super.key});
  @override
  Widget build(BuildContext context) => const LoadingSkeleton();
}

class CatalogError extends ConsumerWidget {
  const CatalogError({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
    icon: Icons.wifi_off_rounded,
    title: context.l10n.catalogLoadFailed,
    message: context.l10n.catalogLoadFailedMessage,
    actionLabel: context.l10n.tryAgain,
    onAction: () => ref.invalidate(catalogProvider),
  );
}

class SongTile extends ConsumerWidget {
  const SongTile({super.key, required this.song, required this.index});
  final Song song;
  final int index;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(hasSelectedSongProvider) &&
        ref.watch(currentSongProvider)?.identity == song.identity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        child: Semantics(
          selected: selected,
          child: Material(
            color: selected
                ? AppColors.primary.withValues(alpha: .12)
                : AppColors.surface.withValues(alpha: .45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected
                    ? AppColors.mystic.withValues(alpha: .4)
                    : Colors.transparent,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              onTap: () => openCatalogSong(context, ref, index),
              leading: Artwork(
                url: song.artwork,
                semanticLabel: context.l10n.artworkFor(song.title),
              ),
              title: Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.cyan : AppColors.text,
                ),
              ),
              subtitle: Text(
                '${song.artist} · ${song.genre}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                tooltip: context.l10n.playSong(song.title),
                onPressed: () => openCatalogSong(context, ref, index),
                icon: Icon(
                  selected
                      ? Icons.graphic_eq_rounded
                      : Icons.play_arrow_rounded,
                  color: selected ? AppColors.cyan : AppColors.secondaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
