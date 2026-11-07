import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'artwork.dart';

/// Visual phase only, retained by the screen when its responsive tree changes.
class VinylRotationPhase {
  double turns = 0;
}

/// A cached record surface rotates; playback remains owned by the audio player.
class VinylRecordArtwork extends StatefulWidget {
  const VinylRecordArtwork({
    super.key,
    required this.url,
    required this.playing,
    required this.size,
    required this.semanticLabel,
    this.phase,
  });

  final String url, semanticLabel;
  final bool playing;
  final double size;
  final VinylRotationPhase? phase;

  @override
  State<VinylRecordArtwork> createState() => _VinylRecordArtworkState();
}

class _VinylRecordArtworkState extends State<VinylRecordArtwork>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
    animationBehavior: AnimationBehavior.preserve,
    value: widget.phase?.turns ?? 0,
  );
  bool _motionEnabled = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _rotation.addListener(_rememberPhase);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  void _rememberPhase() {
    widget.phase?.turns = _rotation.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionEnabled =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _syncRotation();
  }

  @override
  void didUpdateWidget(covariant VinylRecordArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRotation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncRotation();
  }

  void _syncRotation() {
    if (widget.playing && _motionEnabled && _foreground) {
      // repeat() starts from the controller's current value, preserving phase.
      if (!_rotation.isAnimating) _rotation.repeat();
    } else if (_rotation.isAnimating) {
      _rotation.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labelSize = widget.size * .70;
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xE608090C),
                  blurRadius: 1.5,
                  offset: Offset(0, widget.size * .012),
                ),
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: colors.isDark ? .4 : .18,
                  ),
                  blurRadius: widget.size * .08,
                  offset: Offset(0, widget.size * .035),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: RotationTransition(
                    turns: _rotation,
                    child: RepaintBoundary(
                      child: ClipOval(
                        child: CustomPaint(
                          painter: const _VinylGroovesPainter(),
                          child: Center(
                            child: Container(
                              width: labelSize,
                              height: labelSize,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.surfaceLight,
                                border: Border.all(
                                  color: const Color(0xFF08090C),
                                ),
                              ),
                              child: ClipOval(
                                child: AnimatedSwitcher(
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 500),
                                  child: Artwork(
                                    key: ValueKey(widget.url),
                                    url: widget.url,
                                    size: labelSize - 6,
                                    radius: labelSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Reflections and the spindle hole stay fixed to the light,
                // while the cached record and its artwork rotate underneath.
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _VinylReflectionPainter()),
                  ),
                ),
                Container(
                  width: math.max(5, widget.size * .028),
                  height: math.max(5, widget.size * .028),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.background,
                    border: Border.all(
                      color: const Color(0xFF101114),
                      width: 2,
                    ),
                  ),
                ),
                if (widget.size >= 220 &&
                    !MediaQuery.disableAnimationsOf(context))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: VinylTonearm(engaged: widget.playing),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  const _VinylGroovesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF111216), Color(0xFF292B32), Color(0xFF101115)],
          stops: [0, .78, 1],
        ).createShader(Offset.zero & size),
    );
    final groove = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 40; i++) {
      groove
        ..strokeWidth = i % 5 == 0 ? .9 : .6
        ..color = i.isEven ? const Color(0x1CFFFFFF) : const Color(0x70000000);
      canvas.drawCircle(center, radius * (.725 + i * .0065), groove);
    }
    canvas.drawCircle(
      center,
      radius - .7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF46474D),
    );
    canvas.drawCircle(
      center,
      radius * .71,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF08090C),
    );
  }

  @override
  bool shouldRepaint(_VinylGroovesPainter oldDelegate) => false;
}

class _VinylReflectionPainter extends CustomPainter {
  const _VinylReflectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius - 1))
      ..addOval(Rect.fromCircle(center: center, radius: radius * .71));
    canvas.drawPath(
      ring,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0x00FFFFFF),
            Color(0x18FFFFFF),
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
            Color(0x10FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0, .14, .28, .5, .66, .82],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_VinylReflectionPainter oldDelegate) => false;
}

/// Decorative only: the stylus touches the outer grooves, leaving the cover
/// and all gestures unobstructed. Pause/buffering/completion return it to rest.
class VinylTonearm extends StatelessWidget {
  const VinylTonearm({super.key, required this.engaged});
  final bool engaged;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: engaged ? 1 : 0),
    duration: const Duration(milliseconds: 650),
    curve: Curves.easeInOutCubic,
    builder: (context, value, _) =>
        RepaintBoundary(child: CustomPaint(painter: _TonearmPainter(value))),
  );
}

class _TonearmPainter extends CustomPainter {
  const _TonearmPainter(this.engagement);
  final double engagement;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.shortestSide;
    final pivot = Offset(d * .94, d * .075);
    canvas.drawCircle(
      pivot + Offset(0, d * .012),
      d * .043,
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(
      pivot,
      d * .04,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFCFD3DD), Color(0xFF525868)],
        ).createShader(Rect.fromCircle(center: pivot, radius: d * .04)),
    );
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-.30 * (1 - engagement));
    final shaft = Path()
      ..moveTo(0, -d * .025)
      ..lineTo(0, d * .29)
      ..lineTo(-d * .065, d * .42);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(d * .008, d * .01);
    canvas.drawPath(
      shaft,
      pen
        ..strokeWidth = d * .025
        ..color = const Color(0x55000000),
    );
    canvas.restore();
    canvas.drawPath(
      shaft,
      pen
        ..strokeWidth = d * .021
        ..color = const Color(0xFF515767),
    );
    canvas.drawPath(
      shaft,
      pen
        ..strokeWidth = d * .011
        ..color = const Color(0xFFE5E7ED),
    );
    canvas.translate(-d * .065, d * .42);
    canvas.rotate(.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: d * .028, height: d * .065),
        Radius.circular(d * .008),
      ),
      Paint()..color = const Color(0xFF30343F),
    );
    canvas.drawLine(
      Offset(0, d * .017),
      Offset(0, d * .038),
      Paint()
        ..color = const Color(0xFFD5B99B)
        ..strokeWidth = d * .006,
    );
    canvas.restore();
    canvas.drawCircle(
      pivot,
      d * .018,
      Paint()..color = const Color(0xFF30343F),
    );
    canvas.drawCircle(
      pivot - Offset(d * .005, d * .006),
      d * .006,
      Paint()..color = const Color(0xFFDFE2EB),
    );
  }

  @override
  bool shouldRepaint(_TonearmPainter oldDelegate) =>
      oldDelegate.engagement != engagement;
}
