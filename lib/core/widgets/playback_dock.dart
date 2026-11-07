import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../services/audio_service.dart';
import 'artwork.dart';
import 'listening_panel.dart';
import 'playback_controls.dart';

class PlaybackDock extends ConsumerWidget {
  const PlaybackDock({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(currentSongProvider);
    if (!ref.watch(hasSelectedSongProvider) || song == null) {
      return const SizedBox.shrink();
    }
    return Material(
      key: const ValueKey('mini-player'),
      color: context.colors.secondaryBackground,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.colors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final wide =
                  bounds.maxWidth >= 1000 &&
                  MediaQuery.textScalerOf(context).scale(14) < 22;
              final identity = Row(
                children: [
                  InkWell(
                    onTap: () => context.push('/player'),
                    child: Artwork(url: song.artwork, size: 52, radius: 8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/player'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (wide) SongFavoriteButton(song: song),
                ],
              );
              final queue = IconButton(
                tooltip: context.l10n.v3Queue,
                isSelected: ref.watch(queuePanelVisibleProvider),
                onPressed: () =>
                    ref.read(queuePanelVisibleProvider.notifier).state = !ref
                        .read(queuePanelVisibleProvider),
                icon: const Icon(Icons.queue_music_rounded),
              );
              if (!wide) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(child: identity),
                        IconButton(
                          tooltip: context.l10n.previousTrack,
                          onPressed: () =>
                              ref.read(playbackActionsProvider).skip(-1),
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        const PlaybackToggle(),
                        IconButton(
                          tooltip: context.l10n.nextTrack,
                          onPressed: () =>
                              ref.read(playbackActionsProvider).skip(1),
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        queue,
                      ],
                    ),
                    const PlaybackProgress(),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: bounds.maxWidth * .27, child: identity),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [PlaybackModes(), PlaybackProgress()],
                    ),
                  ),
                  const SizedBox(width: 24),
                  queue,
                  const SizedBox(width: 8),
                  SizedBox(width: 140, height: 48, child: _Volume()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Volume extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    return StreamBuilder<double>(
      stream: player.volumeStream,
      initialData: player.volume,
      builder: (context, value) => Row(
        children: [
          const Icon(Icons.volume_up_outlined, size: 20),
          Expanded(
            child: Slider(
              value: (value.data ?? 1).clamp(0, 1),
              onChanged: (level) async {
                try {
                  await player.setVolume(level);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.audioLoadFailed)),
                    );
                  }
                }
              },
              semanticFormatterCallback: (value) =>
                  '${context.l10n.v4Volume} ${(value * 100).round()}%',
            ),
          ),
        ],
      ),
    );
  }
}
