import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/song_favorite_service.dart';
import '../../../core/widgets/playback_controls.dart';
import '../../../core/widgets/vinyl_record_artwork.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';

/// Gestures are confined to the record, away from the seek bar and buttons.
class PlayerRecord extends ConsumerStatefulWidget {
  const PlayerRecord({
    super.key,
    required this.song,
    required this.size,
    required this.playing,
    required this.phase,
  });
  final Song song;
  final double size;
  final bool playing;
  final VinylRotationPhase phase;
  @override
  ConsumerState<PlayerRecord> createState() => _PlayerRecordState();
}

class _PlayerRecordState extends ConsumerState<PlayerRecord> {
  double _drag = 0;
  int _feedback = 0;
  bool _liked = false;

  @override
  void didUpdateWidget(covariant PlayerRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.identity != widget.song.identity) _feedback = 0;
  }

  Future<void> _favorite() async {
    final song = widget.song;
    final liked = await toggleSongFavorite(context, ref, song);
    if (!mounted || liked == null || widget.song.identity != song.identity) {
      return;
    }
    setState(() {
      _liked = liked;
      _feedback++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final liked = ref.watch(songLikedProvider(widget.song));
    return Semantics(
      hint: context.l10n.playerRecordHint,
      customSemanticsActions: {
        CustomSemanticsAction(
          label: liked ? context.l10n.unlikeSong : context.l10n.likeSong,
        ): _favorite,
      },
      child: GestureDetector(
        excludeFromSemantics: true,
        onDoubleTap: _favorite,
        onHorizontalDragStart: (_) => _drag = 0,
        onHorizontalDragUpdate: (details) => _drag += details.primaryDelta ?? 0,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (_drag.abs() < 48 && velocity.abs() < 350) return;
          final direction = _drag.abs() >= 48 ? _drag : velocity;
          ref.read(playbackActionsProvider).skip(direction < 0 ? 1 : -1);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            VinylRecordArtwork(
              url: widget.song.artwork,
              size: widget.size,
              semanticLabel: context.l10n.artworkFor(widget.song.title),
              playing: widget.playing,
              phase: widget.phase,
            ),
            if (_feedback > 0 && !MediaQuery.disableAnimationsOf(context))
              IgnorePointer(
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(_feedback),
                    tween: Tween(begin: 1, end: 0),
                    duration: const Duration(milliseconds: 850),
                    builder: (context, value, _) => Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 1 + .15 * (1 - value),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.background.withValues(
                              alpha: .92,
                            ),
                          ),
                          child: Icon(
                            _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: context.colors.accentText,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
