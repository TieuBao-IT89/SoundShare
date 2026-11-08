import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/home/domain/track_draft.dart';
import 'package:soundshare/features/home/data/api_song_repository.dart';
import 'package:soundshare/features/lyrics/domain/lrc.dart';
import 'package:soundshare/features/lyrics/data/lyrics_repository.dart';
import 'package:soundshare/features/lyrics/presentation/lyrics_screen.dart';
import 'package:soundshare/features/lyrics/presentation/lyrics_editor.dart';
import 'package:soundshare/features/lyrics/presentation/lrc_attachment.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

const recording = Song(
  id: '11111111-1111-4111-8111-111111111111',
  title: 'Khúc nhạc thử',
  artist: 'Người sáng tạo mẫu',
  artwork: '',
  duration: '3:00',
  audioUrl: 'https://fixture.invalid/audio.mp3',
);
const secondRecording = Song(
  id: '22222222-2222-4222-8222-222222222222',
  title: 'Bản thu tiếp theo',
  artist: 'Người sáng tạo mẫu',
  artwork: '',
  duration: '3:00',
);
const originalLrc =
    '[00:00] Dòng đầu tiên\n[00:05] Giai điệu nối tiếp\n[00:10] Câu hát trở về';

class LyricsPlayer extends TestPlayer {
  Duration at = Duration.zero;
  final positions = StreamController<Duration>.broadcast(sync: true);
  @override
  Duration get position => at;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Future<void> seek(Duration? position, {int? index}) async {
    progress((position ?? Duration.zero).inMilliseconds);
  }

  void progress(int ms) {
    at = Duration(milliseconds: ms);
    positions.add(at);
  }
}

class LyricsFixture extends LyricsRepository {
  LyricsFixture()
    : super(ApiClient(token: ({bool refresh = false}) async => 'fixture'));
  String? content = originalLrc;
  int revision = 1, reads = 0, saves = 0;
  bool fail = false, conflict = false;
  Completer<LyricsDocument>? pending;
  @override
  Future<LyricsDocument> read(String id) async {
    reads++;
    if (fail) throw const ApiException(503, 'LYRICS_UNAVAILABLE');
    if (id == secondRecording.id && pending != null) return pending!.future;
    return LyricsDocument(
      lrc: content == null ? null : parseLrc(content!),
      revision: revision,
      canEdit: true,
    );
  }

  @override
  Future<void> save(String id, String lrc, int version) async {
    if (conflict) throw const ApiException(409, 'LYRICS_CHANGED');
    if (fail) throw const ApiException(503, 'LYRICS_UNAVAILABLE');
    expect(version, revision);
    content = lrc;
    revision++;
    saves++;
  }

  @override
  Future<void> remove(String id, int version) async {
    expect(version, revision);
    content = null;
    revision++;
  }
}

Semantics lineSemantics(WidgetTester tester, int index) =>
    tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(ValueKey('lyric-line-$index')),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.selected != null,
            ),
          )
          .first,
    );

Future<void> captureLyrics(
  WidgetTester tester,
  String name, {
  Finder? target,
}) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  RenderObject? boundary = tester.renderObject(
    target ?? find.byType(LyricsScreen).first,
  );
  while (boundary != null && boundary is! RenderRepaintBoundary) {
    boundary = boundary.parent;
  }
  await tester.runAsync(() async {
    final image = await (boundary! as RenderRepaintBoundary).toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.local/v11/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await (FontLoader('BeVietnamPro')
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final cases = jsonDecode(
    File('test/fixtures/lrc_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final entry in cases['valid'] as List) {
    test('Dart LRC matches server fixture: ${entry['name']}', () {
      final lrc = parseLrc(entry['source'] as String);
      expect([
        for (final cue in lrc.cues) {'atMs': cue.atMs, 'text': cue.text},
      ], entry['cues']);
      expect(lrc.activeIndex(const Duration(milliseconds: -1)), -1);
      expect(
        lrc.activeIndex(Duration(milliseconds: lrc.cues.last.atMs)),
        lrc.cues.length - 1,
      );
      expect(lrc.activeIndex(Duration(milliseconds: lrc.cues.first.atMs)), 0);
    });
  }
  test('Dart rejects malformed, large and untimed LRC', () {
    for (final value in [
      ...cases['invalid'] as List,
      '[00:00]${'x' * 501}',
      '[00:01]${'🎵' * 18000}',
      '[00:01]x\n' * 1001,
      '[00:00]x\n${'\n' * 2000}[00:01]x',
      '[00:00]\ud800',
    ]) {
      expect(() => parseLrc(value as String), throwsFormatException);
    }
  });

  testWidgets(
    'Lyrics follow progress and backward seek, preserve pause and share the engine in fullscreen',
    (tester) async {
      final repo = LyricsFixture(), player = LyricsPlayer();
      final container = await showApp(
        tester,
        '/player',
        player: player,
        repository: TestRepository(() async => [recording]),
        overrides: [lyricsRepositoryProvider.overrideWithValue(repo)],
      );
      await container.read(playbackActionsProvider).play(0);
      await container.read(playbackActionsProvider).pause();
      await pumpPlaybackUi(tester);
      await tapVisible(tester, find.byTooltip(appCopy.playerLyrics));
      expect(lineSemantics(tester, 0).properties.selected, isTrue);
      player.progress(7000);
      await pumpPlaybackUi(tester);
      expect(lineSemantics(tester, 1).properties.selected, isTrue);
      await tester.tap(find.byKey(const ValueKey('lyric-line-0')));
      await pumpPlaybackUi(tester);
      expect(player.position, Duration.zero);
      expect(player.active, isFalse);
      expect(player.loads, 1);
      await tester.tap(find.byTooltip(appCopy.v11Fullscreen));
      await pumpPlaybackUi(tester);
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(player.loads, 1);
      player.progress(12000);
      await pumpPlaybackUi(tester);
      expect(lineSemantics(tester, 2).properties.selected, isTrue);
      await player.positions.close();
    },
  );

  testWidgets(
    'Manual scroll suspends follow, returning to current lyrics works with long wrapped lines',
    (tester) async {
      final repo = LyricsFixture()
        ..content = [
          for (var i = 0; i < 40; i++)
            '[00:${i.toString().padLeft(2, '0')}] Dòng lời thử số $i, cùng những giai điệu nối tiếp nhau',
        ].join('\n');
      final player = LyricsPlayer();
      final container = await showApp(
        tester,
        '/lyrics',
        player: player,
        size: const Size(320, 640),
        textScale: 2,
        repository: TestRepository(() async => [recording]),
        overrides: [lyricsRepositoryProvider.overrideWithValue(repo)],
      );
      await container.read(playbackActionsProvider).play(0);
      await container.read(playbackActionsProvider).pause();
      await pumpPlaybackUi(tester);
      player.progress(25000);
      await pumpPlaybackUi(tester);
      expect(
        find.byKey(const ValueKey('lyric-line-25')).hitTestable(),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey('lyrics-lines')),
        const Offset(0, 180),
      );
      await pumpPlaybackUi(tester);
      expect(find.text(appCopy.v11FollowLyrics), findsOneWidget);
      final followRect = tester.getRect(
        find.widgetWithText(FilledButton, appCopy.v11FollowLyrics),
      );
      expect(followRect.left, greaterThanOrEqualTo(0));
      expect(followRect.right, lessThanOrEqualTo(320));
      await captureLyrics(tester, 'lyrics-manual-follow');
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('lyrics-lines')),
      );
      final offset = list.controller!.offset;
      player.progress(30000);
      await pumpPlaybackUi(tester);
      expect(list.controller!.offset, offset);
      await tester.tap(find.text(appCopy.v11FollowLyrics));
      await pumpPlaybackUi(tester);
      expect(
        find.byKey(const ValueKey('lyric-line-30')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await player.positions.close();
    },
  );

  testWidgets(
    'Track changes ignore late previous lyrics and recover from safe loading errors',
    (tester) async {
      final repo = LyricsFixture(), player = LyricsPlayer();
      final container = await showApp(
        tester,
        '/lyrics',
        player: player,
        repository: TestRepository(() async => [recording, secondRecording]),
        overrides: [lyricsRepositoryProvider.overrideWithValue(repo)],
      );
      await pumpPlaybackUi(tester);
      repo.pending = Completer<LyricsDocument>();
      await container.read(playbackActionsProvider).play(1);
      await container.read(playbackActionsProvider).pause();
      await pumpPlaybackUi(tester);
      expect(find.text('Dòng đầu tiên'), findsNothing);
      await container.read(playbackActionsProvider).play(0);
      await container.read(playbackActionsProvider).pause();
      await pumpPlaybackUi(tester);
      repo.pending!.complete(
        LyricsDocument(lrc: parseLrc('[00:00] Lời cũ đến muộn')),
      );
      await pumpPlaybackUi(tester);
      expect(find.text('Lời cũ đến muộn'), findsNothing);
      repo.fail = true;
      container.invalidate(lyricsDocumentProvider(recording.id));
      await pumpPlaybackUi(tester);
      expect(find.text(appCopy.v11LoadFailed), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text(appCopy.tryAgain));
      await pumpPlaybackUi(tester);
      expect(find.text('Dòng đầu tiên'), findsOneWidget);
      expect(player.loads, 2);
      await player.positions.close();
    },
  );

  testWidgets(
    'Owner editor preserves unsaved text on conflict and saves only valid revisions',
    (tester) async {
      final repo = LyricsFixture(), player = LyricsPlayer();
      await showApp(
        tester,
        '/lyrics',
        player: player,
        repository: TestRepository(() async => [recording]),
        overrides: [lyricsRepositoryProvider.overrideWithValue(repo)],
      );
      await pumpPlaybackUi(tester);
      await tester.tap(find.byTooltip(appCopy.v11EditLyrics));
      await pumpPlaybackUi(tester);
      final input = find.byKey(const ValueKey('lrc-input'));
      await tester.enterText(input, '[00:00] Lời mới đang sửa');
      await pumpPlaybackUi(tester);
      repo.conflict = true;
      await tapVisible(tester, find.text(appCopy.v11SaveLyrics));
      expect(find.text(appCopy.v11LyricsChanged), findsOneWidget);
      expect(
        tester.widget<TextField>(input).controller!.text,
        '[00:00] Lời mới đang sửa',
      );
      expect(repo.saves, 0);
      repo.conflict = false;
      repo.revision++;
      repo.content = '[00:00] Bản lời từ phiên khác';
      await tapVisible(tester, find.text(appCopy.v11ReloadLyrics));
      await pumpPlaybackUi(tester);
      expect(tester.widget<TextField>(input).controller!.text, repo.content);
      await tester.enterText(input, '[00:00] Lời mới đang sửa');
      await tapVisible(tester, find.text(appCopy.v11SaveLyrics));
      await pumpPlaybackUi(tester);
      expect(repo.saves, 1);
      expect(find.byType(LyricsEditor), findsNothing);
      expect(find.text('Lời mới đang sửa'), findsOneWidget);
      await tester.tap(find.byTooltip(appCopy.v11EditLyrics));
      await pumpPlaybackUi(tester);
      await tapVisible(tester, find.text(appCopy.v11RemoveLyrics));
      await tester.tap(
        find.widgetWithText(FilledButton, appCopy.v11RemoveLyrics),
      );
      await pumpPlaybackUi(tester);
      expect(find.text(appCopy.playerLyricsUnavailable), findsOneWidget);
      expect(repo.content, isNull);
      expect(player.loads, 0);
      await player.positions.close();
    },
  );

  testWidgets(
    'LRC picker validates UTF-8, size and extension and pasted text is validated before submit',
    (tester) async {
      final picker = TestPicker();
      String? source;
      var valid = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LrcAttachment(
                filePicker: picker,
                onChanged: (s, ok) {
                  source = s;
                  valid = ok;
                },
              ),
            ),
          ),
        ),
      );
      for (final file in [
        PlatformFile(
          name: 'bad.lrc',
          size: 2,
          bytes: Uint8List.fromList([0xff, 0xfe]),
        ),
        PlatformFile(name: 'large.lrc', size: 65537, bytes: Uint8List(1)),
        PlatformFile(
          name: 'wrong.txt',
          size: 10,
          bytes: Uint8List.fromList(utf8.encode(originalLrc)),
        ),
      ]) {
        picker.choose = () async => FilePickerResult([file]);
        await tester.tap(find.text(appCopy.v11ChooseLrc));
        await tester.pumpAndSettle();
        expect(source, isNull);
        expect(find.text(appCopy.v11InvalidLrc), findsOneWidget);
      }
      picker.choose = () async => FilePickerResult([
        PlatformFile(
          name: 'lyrics.lrc',
          size: utf8.encode(originalLrc).length,
          bytes: Uint8List.fromList(utf8.encode(originalLrc)),
        ),
      ]);
      await tester.tap(find.text(appCopy.v11ChooseLrc));
      await tester.pumpAndSettle();
      expect(source, originalLrc);
      await tester.enterText(
        find.byKey(const ValueKey('lrc-input')),
        'untimed',
      );
      await tester.pumpAndSettle();
      expect(valid, isFalse);
    },
  );

  test('New-track upload sends LRC with metadata after media upload, never as an audio file', () async {
    final paths = <String>[];
    final api = ApiClient(
      token: ({bool refresh = false}) async => 'fixture',
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/uploads/audio')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'fixture-audio'},
            }),
            201,
          );
        }
        final body = jsonDecode(request.body) as Map;
        expect(body['lyricsLrc'], originalLrc);
        expect(body['audioAssetId'], 'fixture-audio');
        expect(body.containsKey('owner'), isFalse);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'id': recording.id},
          }),
          201,
        );
      }),
    );
    addTearDown(api.close);
    await ApiSongRepository(api).upload(
      TrackDraft(
        title: recording.title,
        artist: recording.artist,
        genre: 'Indie',
        description: '',
        audioName: 'fixture.mp3',
        audioBytes: Uint8List.fromList([1, 2, 3]),
        lyricsLrc: originalLrc,
      ),
    );
    expect(paths, ['/api/v1/uploads/audio', '/api/v1/songs']);
  });

  for (final (size, scale, mode) in [
    (const Size(320, 640), 2.0, ThemeMode.dark),
    (const Size(390, 844), 1.0, ThemeMode.light),
    (const Size(844, 390), 2.0, ThemeMode.dark),
  ]) {
    testWidgets('Fullscreen lyrics fit $size at $scale text in ${mode.name}', (
      tester,
    ) async {
      final repo = LyricsFixture(), player = LyricsPlayer();
      final container = await showApp(
        tester,
        '/lyrics',
        player: player,
        size: size,
        textScale: scale,
        initialThemeMode: mode,
        repository: TestRepository(() async => [recording]),
        overrides: [lyricsRepositoryProvider.overrideWithValue(repo)],
      );
      await container.read(playbackActionsProvider).play(0);
      await container.read(playbackActionsProvider).pause();
      player.progress(6000);
      await pumpPlaybackUi(tester);
      expect(
        find.byKey(const ValueKey('lyric-line-1')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await captureLyrics(tester, 'lyrics-${size.width.toInt()}-${mode.name}');
      expect(player.loads, 1);
      await player.positions.close();
    });
  }

  testWidgets(
    'LRC editor scrolls controls above the phone keyboard at large text',
    (tester) async {
      final repo = LyricsFixture(), player = LyricsPlayer();
      await showApp(
        tester,
        '/lyrics',
        player: player,
        size: const Size(320, 640),
        textScale: 2,
        repository: TestRepository(() async => [recording]),
        overrides: [lyricsRepositoryProvider.overrideWithValue(repo)],
      );
      await pumpPlaybackUi(tester);
      await tester.tap(find.byTooltip(appCopy.v11EditLyrics));
      await pumpPlaybackUi(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      await pumpPlaybackUi(tester);
      final save = find.widgetWithText(FilledButton, appCopy.v11SaveLyrics);
      final scrollable = find
          .descendant(
            of: find.byType(LyricsEditor),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        save,
        120,
        scrollable: scrollable,
        continuous: true,
      );
      await tester.ensureVisible(save);
      await pumpPlaybackUi(tester);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(390));
      expect(tester.takeException(), isNull);
      await captureLyrics(
        tester,
        'lyrics-editor-keyboard',
        target: find.byType(LyricsEditor),
      );
      await player.positions.close();
    },
  );
}
