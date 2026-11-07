import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import 'soundshare_search_field.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    super.key,
    required this.child,
    this.ambient = false,
  });
  final Widget child;
  final bool ambient;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(gradient: context.colors.backgroundGradient),
    child: Stack(
      children: [
        if (ambient) ...[
          Positioned(
            top: -160,
            right: -140,
            child: IgnorePointer(
              child: _Glow(
                color: context.colors.primary.withValues(alpha: .17),
                size: 500,
              ),
            ),
          ),
          Positioned(
            bottom: -180,
            left: -180,
            child: IgnorePointer(
              child: _Glow(
                color: context.colors.accentText.withValues(alpha: .07),
                size: 480,
              ),
            ),
          ),
        ],
        Positioned.fill(child: child),
      ],
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.gradient,
    this.borderRadius,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: gradient == null ? context.colors.surface : null,
      gradient: gradient,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: context.colors.isDark
          ? null
          : Border.all(color: context.colors.border),
      boxShadow: context.colors.isDark
          ? null
          : [
              BoxShadow(
                color: context.colors.shadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
    ),
    child: Material(color: Colors.transparent, child: child),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: onPressed == null
          ? context.colors.surfaceLight
          : context.colors.action,
      borderRadius: BorderRadius.circular(16),
    ),
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledForegroundColor: context.colors.secondaryText,
        shadowColor: Colors.transparent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy || icon != null) ...[
            if (busy && !MediaQuery.disableAnimationsOf(context))
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(busy ? Icons.hourglass_top_rounded : icon, size: 20),
            const SizedBox(width: 10),
          ],
          Flexible(child: Text(label, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}

class GradientIconButton extends StatelessWidget {
  const GradientIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 56,
    this.selected = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final bool selected;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: context.colors.buttonGradient,
      boxShadow: [
        BoxShadow(
          color: context.colors.primary.withValues(alpha: .22),
          blurRadius: 24,
          spreadRadius: selected ? 3 : 0,
        ),
      ],
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: Size(size, size),
        foregroundColor: Colors.white,
        disabledForegroundColor: context.colors.secondaryText,
      ),
      iconSize: size * .48,
      icon: Icon(icon),
    ),
  );
}

class AuroraLogo extends StatelessWidget {
  const AuroraLogo({super.key, this.size = 40, this.wordmark = false});
  final double size;
  final bool wordmark;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.appName,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                context.colors.brandGradient.createShader(bounds),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: size,
              color: Colors.white,
            ),
          ),
          if (wordmark) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'SoundShare',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size * .5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class MysticSearchBar extends StatelessWidget {
  const MysticSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  @override
  Widget build(BuildContext context) => SoundShareSearchField(
    controller: controller,
    onChanged: onChanged,
    onClear: onClear,
    enableShortcut: true,
  );
}

class AuroraReveal extends StatefulWidget {
  const AuroraReveal({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  State<AuroraReveal> createState() => _AuroraRevealState();
}

class _AuroraRevealState extends State<AuroraReveal> {
  bool visible = false;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => visible = true);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 260);
    return AnimatedSlide(
      offset: visible || reduced ? Offset.zero : const Offset(0, .025),
      duration: duration,
      child: AnimatedOpacity(
        opacity: visible || reduced ? 1 : 0,
        duration: duration,
        child: widget.child,
      ),
    );
  }
}

/// Pointer feedback around existing controls; their gestures, focus and
/// semantics remain with the child. Scrolling cancels the pressed appearance.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  int? pointer;
  Offset? origin;
  bool pressed = false;

  void _release() {
    pointer = null;
    origin = null;
    if (pressed) setState(() => pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (event) {
        if (pointer != null) return;
        pointer = event.pointer;
        origin = event.position;
        setState(() => pressed = true);
      },
      onPointerMove: (event) {
        if (pointer == event.pointer &&
            (event.position - origin!).distance > 18) {
          _release();
        }
      },
      onPointerUp: (event) {
        if (pointer == event.pointer) _release();
      },
      onPointerCancel: (event) {
        if (pointer == event.pointer) _release();
      },
      child: AnimatedScale(
        scale: pressed && !reduced ? .98 : 1,
        duration: reduced
            ? Duration.zero
            : Duration(milliseconds: pressed ? 100 : 180),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.rows = 3});
  final int rows;
  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: context.l10n.loadingLibrary,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) => MediaQuery.disableAnimationsOf(context)
              ? child!
              : ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(-3 + animation.value * 6, 0),
                    end: Alignment(-1 + animation.value * 6, 0),
                    colors: [
                      context.colors.surfaceLight.withValues(alpha: 0),
                      context.colors.secondaryText.withValues(alpha: .25),
                      context.colors.surfaceLight.withValues(alpha: 0),
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
          child: Column(
            children: [
              for (var i = 0; i < widget.rows; i++)
                Container(
                  height: 76,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 10,
                              width: 130,
                              decoration: BoxDecoration(
                                color: context.colors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 8,
                              width: 84,
                              decoration: BoxDecoration(
                                color: context.colors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
