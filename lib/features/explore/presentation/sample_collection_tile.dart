import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../domain/discovery.dart';

String localizedCollectionTitle(
  BuildContext context,
  SampleCollection collection,
) => switch (collection.id) {
  'soft-focus' => context.l10n.softFocusTitle,
  'after-hours' => context.l10n.afterHoursTitle,
  _ => collection.title,
};

String localizedCollectionDescription(
  BuildContext context,
  SampleCollection collection,
) => switch (collection.id) {
  'soft-focus' => context.l10n.softFocusDescription,
  'after-hours' => context.l10n.afterHoursDescription,
  _ => collection.description,
};

class SampleCollectionTile extends StatelessWidget {
  const SampleCollectionTile({
    super.key,
    required this.collection,
    required this.songs,
    required this.onTap,
    this.sample = true,
  });
  final SampleCollection collection;
  final List<Song> songs;
  final VoidCallback onTap;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final matches = songs.where(collection.contains).toList();
    final title = localizedCollectionTitle(context, collection);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (matches.isNotEmpty)
                        Artwork(
                          url: matches.first.artwork,
                          size: 64,
                          radius: 14,
                          semanticLabel: t.artworkFor(title),
                        )
                      else
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: AppColors.mystic,
                          size: 32,
                        ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.secondaryText,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    localizedCollectionDescription(context, collection),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.secondaryText, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sample
                        ? t.sampleCount(matches.length)
                        : t.trackCount(matches.length),
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: AppColors.cyan),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
