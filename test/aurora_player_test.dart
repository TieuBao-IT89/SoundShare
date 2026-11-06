import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/music_progress_slider.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

class _PositionedPlayer extends TestPlayer {
  final positions = StreamController<Duration>.broadcast();
  Duration at = const Duration(seconds: 65);
  @override
  Duration get position => at;
  @override
  Stream<Duration> get positionStream => positions.stream;

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    at = position ?? Duration.zero;
    positions.add(at);
  }
}

void main() {
  for (final viewport in [
    (size: const Size(320, 640), scale: 2.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(1280, 900), scale: 2.0),
  ]) {
    testWidgets(
      'Mini and full player share position at ${viewport.size.width} / ${viewport.scale}x text',
      (tester) async {
        final audio = _PositionedPlayer();
        final container = await showApp(
          tester,
          '/explore',
          player: audio,
          size: viewport.size,
          textScale: viewport.scale,
        );
        addTearDown(audio.positions.close);
        await container.read(playbackActionsProvider).play(0);
        await tester.pumpAndSettle();
        final mini = tester.widget<MusicProgressIndicator>(
          find.byType(MusicProgressIndicator),
        );
        expect(mini.position, const Duration(seconds: 65));
        expect(mini.duration, const Duration(minutes: 3));
        expect(audio.loads, 1);

        await tester.tap(find.text('Slow Motion').last);
        await tester.pumpAndSettle();
        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, 65000);
        expect(slider.max, 180000);
        slider.onChanged!(90000);
        await tester.pumpAndSettle();
        expect(audio.position, const Duration(seconds: 90));
        expect(find.text('1:30'), findsOneWidget);

        await tapVisible(tester, find.byTooltip(appCopy.backToBrowsing));
        final updatedMini = tester.widget<MusicProgressIndicator>(
          find.byType(MusicProgressIndicator),
        );
        expect(updatedMini.position, const Duration(seconds: 90));
        expect(audio.active, isTrue);
        expect(audio.loads, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Unknown audio duration keeps seeking disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MusicProgressSlider(
            position: const Duration(seconds: 65),
            duration: Duration.zero,
            onSeek: (_) => fail('Unknown duration must not seek.'),
          ),
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
    expect(find.text('--:--'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion uses a static audio loading indicator', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final container = await showApp(tester, '/player');
    container.read(playbackLoadingProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
