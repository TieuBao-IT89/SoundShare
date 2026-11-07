import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/widgets/music_progress_slider.dart';

// Run this file on both the VM and Chrome. VM-only checks cannot detect a
// JavaScript bit-shift truncating the upper duration bound to zero.
void main() {
  testWidgets('Real duration enables seeking and displays the elapsed clock', (
    tester,
  ) async {
    Duration? sought;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MusicProgressSlider(
            duration: const Duration(seconds: 20),
            position: const Duration(seconds: 4),
            onSeek: (position) => sought = position,
          ),
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 20000);
    expect(slider.value, 4000);
    expect(slider.onChanged, isNotNull);
    expect(find.text('0:04'), findsOneWidget);
    expect(find.text('0:20'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pumpAndSettle();
    expect(sought!.inSeconds, inInclusiveRange(9, 11));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invalid duration leaves seeking disabled and clocks safe', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MusicProgressSlider(
            duration: const Duration(seconds: -1),
            position: const Duration(seconds: -4),
            onSeek: (_) => fail('Invalid duration must not seek'),
          ),
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
    expect(slider.value, 0);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('--:--'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Long duration and past-end position stay within slider bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MusicProgressSlider(
            duration: const Duration(days: 60),
            position: const Duration(days: 61),
            onSeek: (_) {},
          ),
        ),
      ),
    );
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.max, 5184000000);
    expect(slider.value, slider.max);
    expect(slider.onChanged, isNotNull);
    expect(tester.takeException(), isNull);
  });
}
