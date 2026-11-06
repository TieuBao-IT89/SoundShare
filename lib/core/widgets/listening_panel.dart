import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/home/application/catalog_provider.dart';
import '../../l10n/l10n.dart';
import '../services/audio_service.dart';
import 'artwork.dart';

// Presentation preference belongs to the current account container.
final queuePanelVisibleProvider = StateProvider<bool>((ref) => false);

class ListeningPanel extends ConsumerWidget {
  const ListeningPanel({super.key, this.onClose});
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue =
        ref.watch(playbackQueueProvider) ??
        ref.watch(catalogProvider).valueOrNull ??
        [];
    final current = ref.watch(currentSongIndexProvider);
    final song = ref.watch(currentSongProvider);
    final actions = ref.watch(playbackActionsProvider);
    return Material(
      color: AppColors.secondaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.v3Queue,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: context.l10n.v4CloseQueue,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
          if (song != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.nowPlaying,
                    style: const TextStyle(color: AppColors.cyan, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Artwork(url: song.artwork, size: 48, radius: 8),
                    title: Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => context.push('/player'),
                  ),
                  const Divider(),
                ],
              ),
            ),
          Expanded(
            child: queue.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.l10n.v3QueueEmpty),
                  )
                : ListView.builder(
                    key: const PageStorageKey('listening-queue'),
                    itemCount: queue.length,
                    itemBuilder: (context, i) => ListTile(
                      selected: i == current,
                      leading: SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      title: Text(
                        queue[i].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        queue[i].artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => actions.playQueued(i),
                      trailing: IconButton(
                        tooltip: context.l10n.v3RemoveFromQueue,
                        onPressed: i == current
                            ? null
                            : () => actions.removeFromQueue(i),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
