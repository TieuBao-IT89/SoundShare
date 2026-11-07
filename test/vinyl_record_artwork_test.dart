import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/artwork.dart';
import 'package:soundshare/core/widgets/vinyl_record_artwork.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

Animation<double> rotation(WidgetTester tester) => tester
    .widget<RotationTransition>(
      find
          .descendant(
            of: find.byType(VinylRecordArtwork),
            matching: find.byType(RotationTransition),
          )
          .first,
    )
    .turns;

Future<void> showRecord(
  WidgetTester tester, {
  bool playing = true,
  bool reduced = false,
  bool visible = true,
  ThemeData? theme,
  String url = '',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: visible,
          child: Scaffold(
            body: Center(
              child: VinylRecordArtwork(
                url: url,
                playing: playing,
                size: 300,
                semanticLabel: 'Ảnh bìa bản thu mẫu',
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class BufferingPlayer extends TestPlayer {
  ProcessingState phase = ProcessingState.ready;
  @override
  ProcessingState get processingState => phase;
  void changePhase(ProcessingState state) {
    phase = state;
    states.add(playerState);
  }
}

const captureReview = bool.fromEnvironment('CAPTURE_VINYL_REVIEW');
const coverUrl = 'https://fixture.invalid/vinyl-cover.png';
const previewSong = Song(
  id: 'vinyl-preview',
  title: 'Những ngày có nắng',
  artist: 'Bản thu mẫu SoundShare',
  artwork: coverUrl,
  duration: '3:00',
);

Future<void> cachePreviewCover(WidgetTester tester) async {
  final bitmap = await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const bounds = Rect.fromLTWH(0, 0, 320, 320);
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFF3DFC6));
    canvas.drawCircle(
      const Offset(40, 260),
      190,
      Paint()..color = const Color(0xFF136B70),
    );
    canvas.drawCircle(
      const Offset(285, 30),
      130,
      Paint()..color = const Color(0xFFB56D52),
    );
    final text = TextPainter(
      text: const TextSpan(
        text: 'S',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 180,
          fontWeight: FontWeight.w700,
          color: Color(0xFF392654),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, const Offset(104, 18));
    final caption = TextPainter(
      text: const TextSpan(
        text: 'S O U N D S H A R E',
        style: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    caption.paint(canvas, const Offset(72, 255));
    final picture = recorder.endRecording();
    final image = await picture.toImage(320, 320);
    picture.dispose();
    return image;
  });
  final cache = PaintingBinding.instance.imageCache;
  final provider = artworkImageProvider(coverUrl);
  cache.evict(provider);
  final completer = OneFrameImageStreamCompleter(
    Future.value(ImageInfo(image: bitmap!)),
  );
  final handle = completer.keepAlive();
  cache.putIfAbsent(provider, () => completer);
  addTearDown(() {
    cache.evict(provider);
    handle.dispose();
  });
  await tester.pump();
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!captureReview) return;
  // GPU image sampling completes outside the fake test clock. Let the real
  // bitmap readback finish before capturing the atmosphere it generates.
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await pumpPlaybackUi(tester);
  final previousShadows = debugDisableShadows;
  final surface = tester.renderObject(
    find
        .descendant(
          of: find.byType(VinylRecordArtwork),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  try {
    debugDisableShadows = false;
    surface.markNeedsPaint();
    await tester.pump();
    // Capture the root layer, including modal barriers and queue sheets.
    // A route's repaint boundary only contains the player behind the sheet.
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    await tester.runAsync(() async {
      final image = await layer.toImage(Offset.zero & view.size);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/vinyl-review/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = previousShadows;
    surface.markNeedsPaint();
    await tester.pump();
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });

  setUpAll(() async {
    if (!captureReview) return;
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  testWidgets('A clockwise turn takes twelve seconds and loops smoothly', (
    tester,
  ) async {
    await showRecord(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(rotation(tester).value, closeTo(.25, .001));
    await tester.pump(const Duration(seconds: 6));
    expect(rotation(tester).value, closeTo(.75, .001));
    await tester.pump(const Duration(seconds: 4));
    expect(rotation(tester).value, closeTo(1 / 12, .001));
  });

  testWidgets('Tonearm follows playback and is omitted for reduced motion', (
    tester,
  ) async {
    await showRecord(tester);
    expect(
      tester.widget<VinylTonearm>(find.byType(VinylTonearm)).engaged,
      isTrue,
    );
    await showRecord(tester, playing: false);
    expect(
      tester.widget<VinylTonearm>(find.byType(VinylTonearm)).engaged,
      isFalse,
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await showRecord(tester, reduced: true);
    expect(find.byType(VinylTonearm), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('Pause freezes phase; resume and ordinary rebuilds retain it', (
    tester,
  ) async {
    await showRecord(tester);
    await tester.pump(const Duration(seconds: 3));
    final animation = rotation(tester);
    await showRecord(tester, playing: false);
    final paused = animation.value;
    await tester.pump(const Duration(seconds: 20));
    expect(rotation(tester).value, paused);
    await showRecord(tester, playing: false, theme: AppTheme.dark);
    expect(identical(animation, rotation(tester)), isTrue);
    expect(rotation(tester).value, paused);
    await showRecord(tester);
    expect(rotation(tester).value, paused);
    await tester.pump(const Duration(seconds: 3));
    expect(rotation(tester).value, closeTo(.5, .001));
  });

  testWidgets(
    'Reduced motion and inactive tickers freeze without catching up',
    (tester) async {
      await showRecord(tester);
      await tester.pump(const Duration(seconds: 3));
      final at = rotation(tester).value;
      await showRecord(tester, reduced: true);
      await tester.pump(const Duration(seconds: 15));
      expect(rotation(tester).value, at);
      await showRecord(tester, visible: false);
      await tester.pump(const Duration(seconds: 15));
      expect(rotation(tester).value, at);
      await showRecord(tester);
      await tester.pump(const Duration(seconds: 3));
      expect(rotation(tester).value, closeTo(.5, .001));
    },
  );

  testWidgets(
    'Background pauses at the current angle and disposal removes the ticker',
    (tester) async {
      await showRecord(tester);
      await tester.pump(const Duration(seconds: 3));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final at = rotation(tester).value;
      await tester.pump(const Duration(seconds: 15));
      expect(rotation(tester).value, at);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(rotation(tester).value, closeTo(.5, .001));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Missing or failed artwork retains a circular fallback and one image label',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await showRecord(tester, playing: false);
        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
        expect(find.bySemanticsLabel('Ảnh bìa bản thu mẫu'), findsOneWidget);
        await showRecord(
          tester,
          playing: false,
          url: 'https://fixture.invalid/missing.png',
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(find.byType(Artwork), findsOneWidget);
        expect(find.byType(ClipOval), findsWidgets);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Now Playing uses the existing audio state, including buffering and completion',
    (tester) async {
      final audio = BufferingPlayer();
      final container = await showApp(
        tester,
        '/player',
        player: audio,
        repository: TestRepository(() async => [previewSong]),
      );
      await container.read(playbackActionsProvider).play(0);
      await pumpPlaybackUi(tester);
      expect(
        tester.widget<VinylRecordArtwork>(find.byType(VinylRecordArtwork)).url,
        coverUrl,
      );
      await tester.pump(const Duration(seconds: 2));
      final playingAt = rotation(tester).value;
      await audio.pause();
      await pumpPlaybackUi(tester);
      final pausedAt = rotation(tester).value;
      await tester.pump(const Duration(seconds: 5));
      expect(rotation(tester).value, pausedAt);
      expect(pausedAt, greaterThanOrEqualTo(playingAt));
      await audio.play();
      await pumpPlaybackUi(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(rotation(tester).value, isNot(pausedAt));
      for (final phase in [
        ProcessingState.buffering,
        ProcessingState.completed,
      ]) {
        audio.changePhase(phase);
        await tester.pump();
        final at = rotation(tester).value;
        await tester.pump(const Duration(seconds: 2));
        expect(rotation(tester).value, at);
      }
      expect(audio.loads, 1);
      expect(identical(container.read(audioPlayerProvider), audio), isTrue);
    },
  );

  for (final viewport in [
    (size: const Size(320, 640), scale: 2.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(430, 932), scale: 1.0),
    (size: const Size(844, 390), scale: 1.0),
    (size: const Size(1280, 900), scale: 1.0),
  ]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'Vinyl fits ${viewport.size} at ${viewport.scale}x in ${mode.name}',
        (tester) async {
          await cachePreviewCover(tester);
          final container = await showApp(
            tester,
            '/player',
            size: viewport.size,
            textScale: viewport.scale,
            initialThemeMode: mode,
            repository: TestRepository(() async => [previewSong]),
          );
          await tester.pumpAndSettle();
          final disc = find.byType(VinylRecordArtwork);
          final bounds = tester.getRect(disc);
          expect(bounds.width, closeTo(bounds.height, .001));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(viewport.size.width));
          expect(find.text(previewSong.title), findsOneWidget);
          expect(
            tester
                .widgetList<RawImage>(find.byType(RawImage))
                .any((image) => image.image != null),
            isTrue,
          );
          if (captureReview) {
            await capture(
              tester,
              'player-${viewport.size.width.toInt()}-${mode.name}',
            );
          }
          await container.read(playbackActionsProvider).play(0);
          await pumpPlaybackUi(tester);
          if (viewport.size.width == 390) {
            await capture(tester, 'player-390-${mode.name}-playing');
          }
          await tester.ensureVisible(find.byTooltip(appCopy.pauseTrack));
          await pumpPlaybackUi(tester);
          await tester.tap(find.byTooltip(appCopy.pauseTrack));
          await tester.pumpAndSettle();
          final at = rotation(tester).value;
          await tester.pump(const Duration(seconds: 1));
          expect(rotation(tester).value, at);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
