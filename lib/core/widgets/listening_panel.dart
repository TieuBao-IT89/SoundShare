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
      color: context.colors.secondaryBackground,
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
                    style: TextStyle(
                      color: context.colors.accentText,
                      fontSize: 12,
                    ),
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
                    onTap: onClose ?? () => context.push('/player'),
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
                : ReorderableListView.builder(
                    key: const PageStorageKey('listening-queue'),
                    buildDefaultDragHandles: false,
                    onReorderItem: actions.reorderQueue,
                    itemCount: queue.length,
                    itemBuilder: (context, i) => ListTile(
                      key: ValueKey((
                        queue[i].identity,
                        queue
                            .take(i)
                            .where((song) => song.identity == queue[i].identity)
                            .length,
                      )),
                      selected: i == current,
                      leading: SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(color: context.colors.secondaryText),
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.l10n.v3RemoveFromQueue,
                            onPressed: i == current
                                ? null
                                : () => actions.removeFromQueue(i),
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: Tooltip(
                              message: context.l10n.playerReorder,
                              child: const SizedBox.square(
                                dimension: 48,
                                child: Icon(Icons.drag_handle_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
