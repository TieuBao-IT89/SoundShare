import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import 'community_widgets.dart';

/// Playlist endpoints expose metadata, not cover art. The album motif is an
/// explicit fallback, never a fabricated image or a count inferred by the UI.
class PlaylistGrid extends StatelessWidget {
  const PlaylistGrid({super.key, required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const CommunityEmpty();
    return LayoutBuilder(
      builder: (context, bounds) {
        final large = MediaQuery.textScalerOf(context).scale(14) > 22;
        final columns = large
            ? 1
            : bounds.maxWidth >= 960
            ? 4
            : bounds.maxWidth >= 600
            ? 3
            : bounds.maxWidth >= 360
            ? 2
            : 1;
        final width = (bounds.maxWidth - (columns - 1) * 20) / columns;
        return Wrap(
          spacing: 20,
          runSpacing: 24,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/playlists/${item['id']}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.4,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.library_music_outlined,
                              size: 48,
                              color: context.colors.mystic,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item['songCount'] ?? 0} ${context.l10n.v3Songs} · ${item['visibility'] == 'public' ? context.l10n.v3Public : context.l10n.v3Private}',
                        style: TextStyle(
                          color: context.colors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
