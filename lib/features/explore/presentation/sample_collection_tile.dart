import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/artwork.dart';
import '../../home/domain/song.dart';
import '../domain/discovery.dart';

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
    final matches = songs.where(collection.contains).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (matches.isNotEmpty) ...[
                  Artwork(
                    url: matches.first.artwork,
                    size: 56,
                    semanticLabel: 'Sample artwork for ${collection.title}',
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        collection.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${matches.length} ${sample ? 'sample ' : ''}${matches.length == 1 ? 'track' : 'tracks'}',
                        style: const TextStyle(
                          color: AppColors.mint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.violet,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
