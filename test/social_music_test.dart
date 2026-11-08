import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/features/comments/presentation/comments_sheet.dart';
import 'package:soundshare/features/community/application/community_providers.dart';
import 'package:soundshare/features/community/data/community_repository.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/features/social/application/social_providers.dart';
import 'package:soundshare/features/social/data/social_repository.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

const first = Song(
  id: '11111111-1111-4111-8111-111111111111',
  title: 'Fixture — bản thu thứ nhất',
  artist: 'Fixture creator',
  artwork: '',
  duration: '1:00',
  durationSeconds: 60,
  community: true,
  visibility: 'public',
  username: 'fixture',
  uploaderId: 'creator',
  audioUrl: 'https://fixture.invalid/first',
);
const second = Song(
  id: '22222222-2222-4222-8222-222222222222',
  title: 'Fixture — bản thu thứ hai',
  artist: 'Fixture creator',
  artwork: '',
  duration: '1:00',
  community: true,
  visibility: 'public',
  username: 'fixture',
  uploaderId: 'creator',
  audioUrl: 'https://fixture.invalid/second',
);

class PositionPlayer extends TestPlayer {
  Duration at = Duration.zero;
  final positions = StreamController<Duration>.broadcast(sync: true);
  @override
  Duration get position => at;
  @override
  Stream<Duration> get positionStream => positions.stream;
  @override
  Future<void> seek(Duration? position, {int? index}) async {
    at = position ?? Duration.zero;
    positions.add(at);
  }

  void progress(int ms) {
    at = Duration(milliseconds: ms);
    positions.add(at);
  }
}

class SocialFixture extends SocialRepository {
  SocialFixture()
    : super(ApiClient(token: ({bool refresh = false}) async => 'fixture'));
  int feeds = 0, commentsCalls = 0, writes = 0;
  bool failFeed = false, failComments = false, failInbox = false;
  int inboxCalls = 0;
  String? replyParent;
  Completer<CursorPage<Song>>? pending;
  final notices = <SocialJson>[
    {
      'id': 'fixture-notice',
      'type': 'reply',
      'trackId': first.id,
      'commentId': 'fixture-comment',
      'title': first.title,
      'read': false,
      'createdAt': '2026-11-08T12:00:00Z',
      'actor': {
        'id': 'creator',
        'username': 'fixture',
        'displayName': 'Fixture creator',
      },
    },
  ];
  final prefs = <String, dynamic>{
    'followers': true,
    'comments': true,
    'replies': true,
    'likes': true,
    'newTracks': true,
  };
  @override
  Future<CursorPage<Song>> feed(String mode, String? cursor) async {
    feeds++;
    if (failFeed) throw const ApiException(503, 'SOCIAL_UNAVAILABLE');
    if (pending != null) return pending!.future;
    return CursorPage(mode == 'following' ? [] : [first, second], null);
  }

  @override
  Future<Song> song(String id) async => first;
  @override
  Future<CursorPage<SocialJson>> comments(
    String id,
    String? cursor, {
    String? parent,
  }) async {
    commentsCalls++;
    if (failComments) throw const ApiException(503, 'SOCIAL_UNAVAILABLE');
    return CursorPage([], null, total: writes);
  }

  @override
  Future<void> comment(String id, String content, {String? parent}) async {
    writes++;
    replyParent = parent;
  }

  @override
  Future<int> unread() async => notices.where((n) => n['read'] != true).length;
  @override
  Future<CursorPage<SocialJson>> inbox(bool unread, String? cursor) async {
    inboxCalls++;
    if (failInbox) throw const ApiException(503, 'SOCIAL_UNAVAILABLE');
    return CursorPage(
      notices
          .where((n) => !unread || n['read'] != true)
          .map((n) => Map<String, dynamic>.from(n))
          .toList(),
      null,
    );
  }

  @override
  Future<void> read({String? id}) async {
    for (final n in notices) {
      if (id == null || n['id'] == id) n['read'] = true;
    }
  }

  @override
  Future<SocialJson> preferences([SocialJson? input]) async {
    if (input != null) prefs.addAll(input);
    return Map.from(prefs);
  }

  @override
  Future<SocialJson> commentContext(String id) async => {
    'trackId': first.id,
    'rootId': 'fixture-root',
    'targetId': id,
    'content': 'Fixture notification thread',
    'deleted': false,
  };
}

List<Override> socialOverrides(SocialFixture repo) => [
  socialRepositoryProvider.overrideWithValue(repo),
  myPublicProfileProvider.overrideWith(
    (ref) async => PublicProfile.fromJson({
      'id': 'listener',
      'displayName': 'Fixture listener',
    }),
  ),
];
void main() {
  testWidgets(
    'service failure is explained and retry recovers the Shorts feed',
    (tester) async {
      final repo = SocialFixture()..failFeed = true;
      await showApp(tester, '/shorts', overrides: socialOverrides(repo));
      await pumpPlaybackUi(tester);
      expect(find.text(appCopy.v3Unavailable), findsOneWidget);
      expect(find.text(appCopy.v9Unavailable), findsNothing);
      repo.failFeed = false;
      await tester.tap(find.text(appCopy.tryAgain));
      await pumpPlaybackUi(tester);
      expect(find.text(first.title), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await pumpPlaybackUi(tester);
    },
  );
  testWidgets(
    'comment load failure shows a reason and retry loads the discussion',
    (tester) async {
      final repo = SocialFixture()..failComments = true;
      await showApp(tester, '/shorts', overrides: socialOverrides(repo));
      await pumpPlaybackUi(tester);
      await tester.tap(find.byTooltip(appCopy.v9Comments).first);
      await pumpPlaybackUi(tester);
      expect(find.text(appCopy.v3Unavailable), findsOneWidget);
      repo.failComments = false;
      await tester.tap(find.text(appCopy.tryAgain));
      await pumpPlaybackUi(tester);
      expect(find.text(appCopy.v9NoComments), findsOneWidget);
    },
  );
  testWidgets(
    'visible inbox refreshes new activity and stops polling under preferences',
    (tester) async {
      final repo = SocialFixture();
      await showApp(tester, '/notifications', overrides: socialOverrides(repo));
      await pumpPlaybackUi(tester);
      expect(repo.inboxCalls, 1);
      await tester.pump(const Duration(seconds: 31));
      await pumpPlaybackUi(tester);
      expect(repo.inboxCalls, 2);
      await tester.tap(find.byTooltip(appCopy.v9Preferences));
      await pumpPlaybackUi(tester);
      await tester.pump(const Duration(seconds: 61));
      await pumpPlaybackUi(tester);
      expect(repo.inboxCalls, 2);
      expect(tester.takeException(), isNull);
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'Shorts responsive ${mode.name}: long text and no automatic ticket',
      (tester) async {
        final repo = SocialFixture();
        final player = PositionPlayer();
        await showApp(
          tester,
          '/shorts',
          size: const Size(390, 844),
          initialThemeMode: mode,
          player: player,
          overrides: socialOverrides(repo),
        );
        await pumpPlaybackUi(tester);
        expect(tester.takeException(), isNull);
        expect(player.loads, 0);
        if (const bool.fromEnvironment('CAPTURE_V9')) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile('../.local/v9-shorts-${mode.name}.png'),
          );
        }
        await tester.tap(find.byType(BackButton));
        await pumpPlaybackUi(tester);
        await player.positions.close();
      },
    );
  }
  testWidgets(
    'notification inbox filters unread and marks all via the repository',
    (tester) async {
      final repo = SocialFixture();
      await showApp(tester, '/notifications', overrides: socialOverrides(repo));
      await pumpPlaybackUi(tester);
      expect(find.textContaining('Fixture creator'), findsOneWidget);
      await tester.tap(find.text('Chưa đọc'));
      await pumpPlaybackUi(tester);
      if (const bool.fromEnvironment('CAPTURE_V9')) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile('../.local/v9-notifications.png'),
        );
      }
      await tester.tap(find.text('Đánh dấu tất cả đã đọc'));
      await pumpPlaybackUi(tester);
      expect(repo.notices.single['read'], true);
      expect(find.textContaining('Fixture creator'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('notification preferences save and survive reopening the route', (
    tester,
  ) async {
    final repo = SocialFixture();
    await showApp(tester, '/notifications', overrides: socialOverrides(repo));
    await pumpPlaybackUi(tester);
    await tester.tap(find.byTooltip('Tùy chọn thông báo'));
    await pumpPlaybackUi(tester);
    expect(find.byType(SwitchListTile), findsNWidgets(5));
    await tester.tap(find.byType(SwitchListTile).first);
    await pumpPlaybackUi(tester);
    expect(repo.prefs['followers'], false);
    await tester.tap(find.byType(BackButton));
    await pumpPlaybackUi(tester);
    await tester.tap(find.byTooltip('Tùy chọn thông báo'));
    await pumpPlaybackUi(tester);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      false,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'opening a reply notification resolves the correct thread without autoplay',
    (tester) async {
      final repo = SocialFixture(), player = PositionPlayer();
      await showApp(
        tester,
        '/notifications',
        player: player,
        overrides: socialOverrides(repo),
      );
      await pumpPlaybackUi(tester);
      await tester.tap(find.textContaining('Fixture creator'));
      await pumpPlaybackUi(tester);
      expect(find.byType(CommentsSheet), findsOneWidget);
      expect(find.text('Fixture notification thread'), findsOneWidget);
      expect(repo.notices.single['read'], true);
      expect(player.loads, 0);
      await tester.tap(find.byIcon(Icons.close));
      await pumpPlaybackUi(tester);
      await tester.tap(find.byType(BackButton));
      await pumpPlaybackUi(tester);
      expect(tester.takeException(), isNull);
      await player.positions.close();
    },
  );
  testWidgets(
    'one engine: preview bounded; previous queue and position restored paused',
    (tester) async {
      final player = PositionPlayer();
      final container = await showApp(
        tester,
        '/library',
        player: player,
        repository: TestRepository(() async => [first, second]),
      );
      final actions = container.read(playbackActionsProvider);
      await actions.playFrom([first, second], 1);
      player.progress(17000);
      await actions.setRepeat(true);
      await actions.setShuffle(true);
      final lease = actions.beginPreview();
      expect(player.active, false);
      expect(player.loads, 1);
      await actions.preview(lease, first);
      expect(player.loads, 2);
      expect(player.loop.name, 'off');
      expect(container.read(playbackQueueProvider), [first]);
      player.progress(30001);
      await tester.pump();
      expect(player.active, false);
      await actions.restorePreview(lease);
      expect(container.read(playbackQueueProvider), [first, second]);
      expect(container.read(currentSongProvider)?.identity, second.identity);
      expect(player.position, const Duration(seconds: 17));
      expect(player.active, false);
      expect(player.loop.name, 'one');
      expect(player.shuffleOn, true);
      await player.positions.close();
    },
  );
  testWidgets('play full and Stop revoke preview restoration', (tester) async {
    final player = PositionPlayer();
    final container = await showApp(
      tester,
      '/library',
      player: player,
      repository: TestRepository(() async => [first, second]),
    );
    final actions = container.read(playbackActionsProvider);
    await actions.playFrom([first], 0);
    final lease = actions.beginPreview();
    await actions.preview(lease, second);
    await actions.playFrom([second], 0);
    await actions.restorePreview(lease);
    expect(container.read(currentSongProvider)?.identity, second.identity);
    expect(player.active, true);
    final nextLease = actions.beginPreview();
    await actions.preview(nextLease, first);
    await actions.stop();
    await actions.restorePreview(nextLease);
    expect(container.read(hasSelectedSongProvider), false);
    expect(player.active, false);
    await player.positions.close();
  });
  testWidgets(
    'Shorts first entry does not load audio; explicit play, swipe pauses, comments do not restart',
    (tester) async {
      final repo = SocialFixture(), player = PositionPlayer();
      await showApp(
        tester,
        '/shorts',
        player: player,
        overrides: socialOverrides(repo),
      );
      await pumpPlaybackUi(tester);
      expect(player.loads, 0);
      expect(player.active, false);
      await tester.tap(find.text('Nghe thử').first);
      await pumpPlaybackUi(tester);
      expect(player.loads, 1);
      expect(player.active, true);
      await tester.drag(find.byType(PageView), const Offset(0, -650));
      await pumpPlaybackUi(tester);
      await tester
          .pumpAndSettle(); // The preview is paused; finish the page fling.
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        closeTo(1, .01),
      );
      expect(player.active, false);
      expect(player.loads, 1);
      if (const bool.fromEnvironment('CAPTURE_V9')) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile('../.local/v9-after-swipe.png'),
        );
      }
      await tester.tap(find.byTooltip('Bình luận').hitTestable().first);
      await pumpPlaybackUi(tester);
      expect(find.byType(CommentsSheet), findsOneWidget);
      expect(player.active, false);
      expect(repo.feeds, 1);
      await tester.tap(find.byIcon(Icons.close).last);
      await pumpPlaybackUi(tester);
      expect(player.loads, 1);
      expect(player.active, false);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await pumpPlaybackUi(tester);
      await player.positions.close();
    },
  );
  testWidgets(
    'comments composer stays usable with a keyboard at 320px and sends once',
    (tester) async {
      final repo = SocialFixture();
      await showApp(
        tester,
        '/shorts',
        size: const Size(320, 720),
        textScale: 1.3,
        overrides: socialOverrides(repo),
      );
      await pumpPlaybackUi(tester);
      await tester.tap(find.byTooltip('Bình luận').first);
      await pumpPlaybackUi(tester);
      await tester.enterText(find.byType(TextField), 'Fixture comment');
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await pumpPlaybackUi(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Gửi'));
      await pumpPlaybackUi(tester);
      expect(repo.writes, 1);
      expect(find.text('Fixture comment'), findsNothing);
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
    },
  );
  testWidgets(
    'a late feed response after leaving Shorts cannot restart or alter playback',
    (tester) async {
      final repo = SocialFixture()..pending = Completer<CursorPage<Song>>();
      final player = PositionPlayer();
      await showApp(
        tester,
        '/shorts',
        player: player,
        overrides: socialOverrides(repo),
      );
      await tester.tap(find.byType(BackButton));
      await pumpPlaybackUi(tester);
      repo.pending!.complete(CursorPage([first], null));
      await pumpPlaybackUi(tester);
      expect(player.loads, 0);
      expect(player.active, false);
      expect(tester.takeException(), isNull);
      await player.positions.close();
    },
  );
  test('shared optimistic interactions rollback, serialize and are scoped to the account', () async {
    final response = Completer<http.Response>();
    int calls = 0;
    final api = ApiClient(
      token: ({bool refresh = false}) async => 'fixture',
      client: MockClient((request) {
        calls++;
        return response.future;
      }),
    );
    final a = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(api)],
    );
    final b = ProviderContainer();
    addTearDown(() {
      a.dispose();
      b.dispose();
      api.close();
    });
    final operation = a.read(socialActionsProvider).interact(first, 'like');
    expect(a.read(communityLikesProvider)[first.id], true);
    await a.read(socialActionsProvider).interact(first, 'like');
    expect(b.read(communityLikesProvider), isEmpty);
    response.complete(
      http.Response(
        jsonEncode({
          'error': {'code': 'RESOURCE_NOT_FOUND'},
        }),
        404,
      ),
    );
    await expectLater(operation, throwsA(isA<ApiException>()));
    expect(a.read(communityLikesProvider)[first.id], false);
    expect(a.read(socialBusyProvider), isEmpty);
    expect(calls, 1);
  });
}
