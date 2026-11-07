import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/sleep_timer_service.dart';
import '../../../core/widgets/player_sheet.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';

class PlayerExtras extends ConsumerWidget {
  const PlayerExtras({super.key, required this.song});
  final Song song;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadline = ref.watch(sleepTimerProvider);
    final t = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: t.playerLyrics,
          icon: const Icon(Icons.lyrics_outlined),
          onPressed: () => showPlayerSheet<void>(
            context,
            (sheetContext) => _SheetContent(
              title: t.playerLyrics,
              onClose: () => Navigator.pop(sheetContext),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lyrics_outlined,
                        size: 40,
                        color: context.colors.secondaryText,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        song.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.playerLyricsUnavailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: deadline == null
              ? t.playerSleepTimer
              : t.playerSleepUntil(
                  TimeOfDay.fromDateTime(deadline).format(context),
                ),
          isSelected: deadline != null,
          icon: Icon(deadline == null ? Icons.bedtime_outlined : Icons.bedtime),
          onPressed: () => showPlayerSheet<void>(
            context,
            (sheetContext) =>
                _SleepTimerSheet(onClose: () => Navigator.pop(sheetContext)),
          ),
        ),
        IconButton(
          tooltip: t.v3AddToQueue,
          icon: const Icon(Icons.playlist_add_rounded),
          onPressed: () {
            ref.read(playbackActionsProvider).addToQueue(song);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(t.playerAddedToQueue)));
          },
        ),
      ],
    );
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deadline = ref.watch(sleepTimerProvider);
    final t = context.l10n;
    final controller = ref.read(sleepTimerProvider.notifier);
    return _SheetContent(
      title: t.playerSleepTimer,
      onClose: onClose,
      child: ListView(
        children: [
          Text(
            deadline == null
                ? t.playerSleepDescription
                : t.playerSleepUntil(
                    TimeOfDay.fromDateTime(deadline).format(context),
                  ),
          ),
          const SizedBox(height: 16),
          for (final minutes in [15, 30, 60])
            ListTile(
              title: Text(t.playerMinutes(minutes)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                controller.start(Duration(minutes: minutes));
                onClose();
              },
            ),
          if (deadline != null)
            ListTile(
              title: Text(t.playerCancelTimer),
              leading: const Icon(Icons.timer_off_outlined),
              onTap: () {
                controller.cancel();
                onClose();
              },
            ),
        ],
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.title,
    required this.child,
    required this.onClose,
  });
  final String title;
  final Widget child;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
      Expanded(
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ],
  );
}
