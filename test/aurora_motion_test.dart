import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/widgets/artwork_glow.dart';
import 'package:soundshare/core/widgets/aurora_widgets.dart';

class _DeferredImage extends ImageProvider<_DeferredImage> {
  final frame = Completer<ui.Image>();
  @override
  Future<_DeferredImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
    _DeferredImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    frame.future.then((image) => ImageInfo(image: image.clone())),
  );
}

Future<ui.Image> _bitmap(Color color) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(color, BlendMode.src);
  final picture = recorder.endRecording();
  return picture.toImage(8, 8).whenComplete(picture.dispose);
}

Widget _glow(ImageProvider? image, {bool reduced = false}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: ArtworkGlow(
        image: image,
        child: const SizedBox.square(dimension: 100),
      ),
    ),
  ),
);

Color _glowColor(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(ArtworkGlow),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (box.decoration! as BoxDecoration).boxShadow!.first.color;
}

void main() {
  testWidgets(
    'Card press feedback preserves tap, keyboard and scroll cancellation',
    (tester) async {
      var taps = 0;
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressScale(
                child: Material(
                  child: InkWell(
                    focusNode: focus,
                    onTap: () => taps++,
                    child: const SizedBox(
                      width: 200,
                      height: 80,
                      child: Text('Song'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final target = find.byType(InkWell);
      final original = tester.getRect(target);
      final press = await tester.startGesture(original.center);
      await tester.pumpAndSettle();
      expect(tester.getRect(target).width, lessThan(original.width));
      expect(taps, 0);
      await press.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.getRect(target), original);

      final drag = await tester.startGesture(original.center);
      await tester.pump(const Duration(milliseconds: 120));
      await drag.moveBy(const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(tester.getRect(target), original);
      await drag.cancel();
      expect(taps, 1);

      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reduce Motion keeps pressed cards and shimmer static', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(
            body: Column(
              children: [
                PressScale(
                  child: SizedBox(width: 200, height: 80, child: Text('Song')),
                ),
                LoadingSkeleton(),
              ],
            ),
          ),
        ),
      ),
    );
    final target = find.text('Song');
    final original = tester.getRect(target);
    final press = await tester.startGesture(original.center);
    await tester.pumpAndSettle();
    expect(tester.getRect(target), original);
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await press.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Late artwork never replaces the current track glow', (
    tester,
  ) async {
    late ui.Image red;
    late ui.Image blue;
    await tester.runAsync(() async {
      red = await _bitmap(Colors.red);
      blue = await _bitmap(Colors.blue);
    });
    addTearDown(() {
      red.dispose();
      blue.dispose();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
    final old = _DeferredImage();
    final current = _DeferredImage();
    await tester.pumpWidget(_glow(old));
    await tester.pumpWidget(_glow(current, reduced: true));
    expect(_glowColor(tester), AppColors.mystic.withValues(alpha: .28));
    await tester.runAsync(() async {
      current.frame.complete(blue);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    final currentColor = _glowColor(tester);
    expect(currentColor, isNot(AppColors.mystic.withValues(alpha: .28)));
    await tester.runAsync(() async {
      old.frame.complete(red);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(_glowColor(tester), currentColor);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Artwork failure and disposal keep fallback without exposing errors',
    (tester) async {
      final failed = _DeferredImage();
      await tester.pumpWidget(_glow(failed));
      failed.frame.completeError(StateError('private artwork URL'));
      await tester.pumpAndSettle();
      expect(_glowColor(tester), AppColors.mystic.withValues(alpha: .28));
      expect(find.textContaining('private artwork URL'), findsNothing);

      final pending = _DeferredImage();
      await tester.pumpWidget(_glow(pending));
      await tester.pumpWidget(const SizedBox.shrink());
      pending.frame.completeError(StateError('expired artwork URL'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
