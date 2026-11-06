import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final queue =
        ref.watch(playbackQueueProvider) ??
        ref.watch(catalogProvider).valueOrNull ??
        [];
    final current = ref.watch(currentSongIndexProvider);
    final actions = ref.watch(playbackActionsProvider);
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(t.v3Queue, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          if (queue.isEmpty) Text(t.v3QueueEmpty),
          for (var i = 0; i < queue.length; i++)
            ListTile(
              selected: i == current,
              leading: Artwork(url: queue[i].artwork, size: 48, radius: 8),
              title: Text(queue[i].title),
              subtitle: Text(queue[i].artist),
              onTap: () {
                actions.playQueued(i);
                context.push('/player');
              },
              trailing: IconButton(
                tooltip: t.v3RemoveFromQueue,
                onPressed: i == current
                    ? null
                    : () => actions.removeFromQueue(i),
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
            ),
        ],
      ),
    );
  }
}
