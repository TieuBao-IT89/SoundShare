import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';

const _maxSafeInteger = 9007199254740991;

/// Presentation only: position and duration always come from the shared player.
class MusicProgressSlider extends StatelessWidget {
  const MusicProgressSlider({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.durationFallback = '--:--',
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;
  final String durationFallback;

  @override
  Widget build(BuildContext context) {
    // A decimal safe-integer bound also works on Web: `1 << 53` becomes zero
    // under JavaScript's 32-bit bit operations, disabling seeking and clocks.
    final total = duration.inMilliseconds.clamp(0, _maxSafeInteger).toDouble();
    final value = total == 0
        ? 0.0
        : position.inMilliseconds.clamp(0, total).toDouble();
    final elapsed = formatMusicTime(Duration(milliseconds: value.round()));
    final totalLabel = total == 0
        ? durationFallback
        : formatMusicTime(duration);
    final copy = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: copy.playbackPosition,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              trackShape: _AuroraSliderTrackShape(context.colors),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              thumbColor: context.colors.isDark
                  ? context.colors.text
                  : context.colors.primary,
              overlayColor: context.colors.mystic.withValues(alpha: .15),
            ),
            child: Slider(
              value: value,
              max: total == 0 ? 1 : total,
              semanticFormatterCallback: (value) => copy.playbackPositionValue(
                formatMusicTime(Duration(milliseconds: value.round())),
                totalLabel,
              ),
              onChanged: total == 0 || onSeek == null
                  ? null
                  : (value) => onSeek!(Duration(milliseconds: value.round())),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(elapsed, style: _timeStyle(context)),
              Text(totalLabel, style: _timeStyle(context)),
            ],
          ),
        ),
      ],
    );
  }

  static TextStyle _timeStyle(BuildContext context) => TextStyle(
    color: context.colors.secondaryText,
    fontSize: 12,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// A non-interactive compact version used by the floating mini player.
class MusicProgressIndicator extends StatelessWidget {
  const MusicProgressIndicator({
    super.key,
    required this.position,
    required this.duration,
  });
  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds;
    final value = total <= 0
        ? 0.0
        : (position.inMilliseconds / total).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: SizedBox(
        height: 3,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: context.colors.surfaceLight),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    gradient: context.colors.brandGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatMusicTime(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, _maxSafeInteger);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _AuroraSliderTrackShape extends RoundedRectSliderTrackShape {
  const _AuroraSliderTrackShape(this.palette);
  final AppPalette palette;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    if ((sliderTheme.trackHeight ?? 0) <= 0) return;
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final radius = Radius.circular(rect.height / 2);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()
        ..color = palette.isDark ? palette.surfaceLight : palette.fieldBorder,
    );
    final active = textDirection == TextDirection.ltr
        ? Rect.fromLTRB(rect.left, rect.top, thumbCenter.dx, rect.bottom)
        : Rect.fromLTRB(thumbCenter.dx, rect.top, rect.right, rect.bottom);
    if (active.width <= 0 || !isEnabled) return;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(active, radius),
      Paint()
        ..shader = palette.buttonGradient.createShader(rect)
        ..color = palette.text.withValues(alpha: enableAnimation.value),
    );
  }
}
