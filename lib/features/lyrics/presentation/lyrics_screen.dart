import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/artwork_glow.dart';
import '../../../core/widgets/playback_controls.dart';
import '../../../core/widgets/player_sheet.dart';
import '../../../core/widgets/visible_playback_position.dart';
import '../../../l10n/l10n.dart';
import '../data/lyrics_repository.dart';
import '../domain/lrc.dart';
import 'lyrics_editor.dart';

Future<void> showLyrics(BuildContext context) =>
    showPlayerSheet<void>(context, (_) => const LyricsPanel());

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SafeArea(child: LyricsPanel(fullscreen: true)));
}

class LyricsPanel extends ConsumerWidget {
  const LyricsPanel({super.key, this.fullscreen = false});
  final bool fullscreen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final song = ref.watch(currentSongProvider);
    final player = ref.watch(audioPlayerProvider);
    final canSeek =
        ref.watch(hasSelectedSongProvider) &&
        !ref.watch(playbackLoadingProvider) &&
        ref.watch(playbackErrorProvider) == null;
    final value = ref.watch(lyricsDocumentProvider(song?.id));
    return ArtworkGlow(
      image: song == null || song.artwork.isEmpty
          ? null
          : artworkImageProvider(song.artwork),
      ambientBackground: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.playerLyrics,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (song != null)
                        Text(
                          '${song.title} · ${song.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.colors.secondaryText),
                        ),
                    ],
                  ),
                ),
                if (song != null && value.valueOrNull?.canEdit == true)
                  IconButton(
                    tooltip: t.v11EditLyrics,
                    onPressed: () => showLyricsEditor(context, song),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                if (!fullscreen)
                  IconButton(
                    tooltip: t.v11Fullscreen,
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push('/lyrics');
                    },
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/player');
                    }
                  },
                  icon: Icon(
                    fullscreen
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.close_rounded,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: value.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.v11LoadFailed, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(lyricsDocumentProvider(song?.id)),
                        child: Text(t.tryAgain),
                      ),
                    ],
                  ),
                ),
              ),
              data: (doc) => doc.lrc == null
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
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
                              t.playerLyricsUnavailable,
                              textAlign: TextAlign.center,
                            ),
                            if (song != null && doc.canEdit)
                              TextButton(
                                onPressed: () =>
                                    showLyricsEditor(context, song),
                                child: Text(t.v11EditLyrics),
                              ),
                          ],
                        ),
                      ),
                    )
                  : VisiblePlaybackPosition(
                      player: player,
                      builder: (context, position) => SyncedLyricsLines(
                        key: ValueKey('${song?.identity}-${doc.revision}'),
                        lrc: doc.lrc!,
                        position: position,
                        fullscreen: fullscreen,
                        onSeek: !canSeek
                            ? null
                            : (at) async {
                                if (ref.read(currentSongProvider)?.identity !=
                                    song?.identity) {
                                  return;
                                }
                                final duration = player.duration;
                                final target = duration != null && at > duration
                                    ? duration
                                    : at;
                                await ref
                                    .read(playbackActionsProvider)
                                    .seek(target);
                              },
                      ),
                    ),
            ),
          ),
          if (fullscreen)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: t.previousTrack,
                    onPressed: () => ref.read(playbackActionsProvider).skip(-1),
                    icon: const Icon(Icons.skip_previous_rounded),
                  ),
                  const SizedBox(width: 16),
                  const PlaybackToggle(),
                  const SizedBox(width: 16),
                  IconButton(
                    tooltip: t.nextTrack,
                    onPressed: () => ref.read(playbackActionsProvider).skip(1),
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SyncedLyricsLines extends StatefulWidget {
  const SyncedLyricsLines({
    super.key,
    required this.lrc,
    required this.position,
    this.fullscreen = false,
    this.onSeek,
  });
  final ParsedLrc lrc;
  final Duration position;
  final bool fullscreen;
  final Future<void> Function(Duration at)? onSeek;
  @override
  State<SyncedLyricsLines> createState() => _SyncedLyricsLinesState();
}

class _SyncedLyricsLinesState extends State<SyncedLyricsLines> {
  final controller = ScrollController();
  bool following = true;
  List<double> heights = [], offsets = [];
  double width = -1, scale = -1, viewport = 0, top = 0;
  int get active => widget.lrc.activeIndex(widget.position);
  void seekCue(LyricCue cue) {
    if (widget.onSeek == null) return;
    setState(() => following = true);
    widget.onSeek!(Duration(milliseconds: cue.atMs));
  }

  void scrollToActive() {
    if (!following || !mounted || !controller.hasClients || offsets.isEmpty) {
      return;
    }
    final index = math.max(0, active);
    final target = (offsets[index] + top + heights[index] / 2 - viewport * .35)
        .clamp(0.0, controller.position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(target);
    } else {
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void scheduleScroll() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToActive());
  @override
  void didUpdateWidget(covariant SyncedLyricsLines old) {
    super.didUpdateWidget(old);
    if (old.lrc != widget.lrc) {
      width = -1;
      following = true;
    }
    if (old.lrc.activeIndex(old.position) != active) scheduleScroll();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final font = widget.fullscreen ? 32.0 : 24.0;
    final style = TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: font,
      fontWeight: FontWeight.w700,
      height: 1.45,
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final contentWidth = math.max(
          1.0,
          math.min(bounds.maxWidth, 900.0) - 48,
        );
        final nextScale = MediaQuery.textScalerOf(context).scale(font);
        if (width != contentWidth ||
            scale != nextScale ||
            viewport != bounds.maxHeight) {
          width = contentWidth;
          scale = nextScale;
          viewport = bounds.maxHeight;
          top = viewport * .25;
          heights = [];
          offsets = [];
          var offset = 0.0;
          for (final cue in widget.lrc.cues) {
            final painter = TextPainter(
              text: TextSpan(
                text: cue.text.isEmpty ? '♪' : cue.text,
                style: style,
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: width);
            offsets.add(offset);
            final height = math.max(48.0, painter.height + 24);
            heights.add(height);
            offset += height;
            painter.dispose();
          }
          scheduleScroll();
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Stack(
              children: [
                NotificationListener<ScrollStartNotification>(
                  onNotification: (event) {
                    if (event.dragDetails != null && following) {
                      setState(() => following = false);
                    }
                    return false;
                  },
                  child: ListView.builder(
                    key: const ValueKey('lyrics-lines'),
                    controller: controller,
                    padding: EdgeInsets.fromLTRB(24, top, 24, viewport * .65),
                    itemCount: widget.lrc.cues.length,
                    itemBuilder: (context, index) {
                      final cue = widget.lrc.cues[index];
                      final selected = index == active;
                      final text = cue.text.isEmpty ? '♪' : cue.text;
                      return Semantics(
                        selected: selected,
                        button: widget.onSeek != null,
                        label: '${t.v11SeekLine} $text',
                        excludeSemantics: true,
                        onTap: widget.onSeek == null
                            ? null
                            : () => seekCue(cue),
                        child: SizedBox(
                          height: heights[index],
                          child: InkWell(
                            key: ValueKey('lyric-line-$index'),
                            onTap: widget.onSeek == null
                                ? null
                                : () => seekCue(cue),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: AnimatedDefaultTextStyle(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 200),
                                style: style.copyWith(
                                  color: selected
                                      ? context.colors.text
                                      : context.colors.secondaryText,
                                ),
                                child: Text(text),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!following)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          setState(() => following = true);
                          scheduleScroll();
                        },
                        icon: const Icon(Icons.my_location_rounded),
                        label: Text(t.v11FollowLyrics),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
