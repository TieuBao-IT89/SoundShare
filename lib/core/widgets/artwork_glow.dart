import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Samples the cached artwork once per image. Only the glow changes; the
/// application's contrast, controls and playback state stay independent.
class ArtworkGlow extends StatefulWidget {
  const ArtworkGlow({
    super.key,
    required this.image,
    required this.child,
    this.ambientBackground = false,
  });
  final ImageProvider? image;
  final Widget child;
  final bool ambientBackground;

  @override
  State<ArtworkGlow> createState() => _ArtworkGlowState();
}

class _ArtworkGlowState extends State<ArtworkGlow> {
  int generation = 0;
  ImageStream? stream;
  ImageStreamListener? listener;
  Timer? timeout;
  Color? primary;
  Color? secondary;

  @override
  void initState() {
    super.initState();
    _sample();
  }

  @override
  void didUpdateWidget(covariant ArtworkGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) _sample();
  }

  void _sample() {
    _detach();
    final ticket = ++generation;
    // Keep the previous atmosphere until the next cover has decoded. Otherwise
    // switching tracks briefly flashes the brand fallback between two colors.
    final image = widget.image;
    if (image == null) {
      primary = null;
      secondary = null;
      return;
    }
    // Share Artwork's image cache, and release the listener on track changes,
    // disposal or timeout. No request is made for the audio or player state.
    stream = image.resolve(ImageConfiguration.empty);
    listener = ImageStreamListener(
      (info, _) {
        _detach();
        unawaited(_extract(info.image, ticket));
      },
      onError: (Object error, StackTrace? trace) {
        _detach();
        _fallback(ticket);
      },
      reportErrors: false,
    );
    timeout = Timer(const Duration(seconds: 5), () {
      _detach();
      _fallback(ticket);
    });
    stream!.addListener(listener!);
  }

  void _fallback(int ticket) {
    if (!mounted || ticket != generation) return;
    setState(() {
      primary = null;
      secondary = null;
    });
  }

  void _detach() {
    timeout?.cancel();
    timeout = null;
    if (listener != null) stream?.removeListener(listener!);
    stream = null;
    listener = null;
  }

  Future<void> _extract(ui.Image image, int ticket) async {
    ui.Picture? picture;
    ui.Image? sample;
    try {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        const Rect.fromLTWH(0, 0, 32, 32),
        Paint()..filterQuality = FilterQuality.low,
      );
      picture = recorder.endRecording();
      sample = await picture.toImage(32, 32);
      final pixels = await sample.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (!mounted || ticket != generation || pixels == null) return;
      final accent = _accentFromPixels(pixels);
      if (accent == null) {
        _fallback(ticket);
        return;
      }
      final hsl = HSLColor.fromColor(accent);
      setState(() {
        primary = accent;
        secondary = hsl.withHue((hsl.hue + 35) % 360).toColor();
      });
    } catch (_) {
      // Expired/CORS-restricted artwork retains the Aurora fallback.
      // Never surface provider errors or signed artwork URLs.
    } finally {
      sample?.dispose();
      picture?.dispose();
      image.dispose();
    }
  }

  @override
  void dispose() {
    generation++;
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final primary = this.primary ?? p.mystic;
    final secondary = this.secondary ?? p.cyan;
    if (widget.ambientBackground) {
      Color ambient(Color color) {
        final hsl = HSLColor.fromColor(color)
            .withSaturation(.35)
            .withLightness(p.isDark ? .3 : .8);
        return Color.lerp(p.background, hsl.toColor(), p.isDark ? .35 : .38)!;
      }

      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 650);
      return AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: p.background,
          gradient: RadialGradient(
            center: const Alignment(-.65, -.65),
            radius: 1.1,
            colors: [ambient(primary), p.background],
          ),
        ),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.9, .4),
              radius: 1,
              colors: [
                ambient(secondary).withValues(alpha: .65),
                ambient(secondary).withValues(alpha: 0),
              ],
            ),
          ),
          child: widget.child,
        ),
      );
    }
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: p.isDark ? .28 : .12),
              blurRadius: 72,
              offset: const Offset(-20, 0),
            ),
            BoxShadow(
              color: secondary.withValues(alpha: p.isDark ? .14 : .06),
              blurRadius: 64,
              offset: const Offset(24, 20),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// Twelve hue groups over a 32×32 sample favor a repeated, colorful region over
// white lettering, black borders and single bright pixels. Neutral art keeps
// the brand fallback. This work runs once per decoded image, never per frame.
Color? _accentFromPixels(ByteData pixels) {
  final weights = List<double>.filled(12, 0);
  final reds = List<double>.filled(12, 0);
  final greens = List<double>.filled(12, 0);
  final blues = List<double>.filled(12, 0);
  for (var offset = 0; offset + 3 < pixels.lengthInBytes; offset += 4) {
    if (pixels.getUint8(offset + 3) < 128) continue;
    final red = pixels.getUint8(offset);
    final green = pixels.getUint8(offset + 1);
    final blue = pixels.getUint8(offset + 2);
    final hsl = HSLColor.fromColor(Color.fromARGB(255, red, green, blue));
    if (hsl.saturation < .2 || hsl.lightness < .1 || hsl.lightness > .9) {
      continue;
    }
    final bucket = (hsl.hue / 30).floor().clamp(0, 11);
    final weight = hsl.saturation * (1 - (hsl.lightness - .5).abs());
    weights[bucket] += weight;
    reds[bucket] += red * weight;
    greens[bucket] += green * weight;
    blues[bucket] += blue * weight;
  }
  var best = 0;
  for (var i = 1; i < weights.length; i++) {
    if (weights[i] > weights[best]) best = i;
  }
  final weight = weights[best];
  if (weight == 0) return null;
  return HSLColor.fromColor(
    Color.fromARGB(
      255,
      (reds[best] / weight).round(),
      (greens[best] / weight).round(),
      (blues[best] / weight).round(),
    ),
  ).withSaturation(.65).withLightness(.65).toColor();
}
