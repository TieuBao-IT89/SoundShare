import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soundshare/app/app.dart';
import 'package:soundshare/core/config/app_mode.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';
import 'package:soundshare/features/auth/domain/auth_session.dart';
import 'package:soundshare/features/community/data/community_repository.dart';
import 'package:soundshare/features/community/presentation/community_widgets.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

import 'package:soundshare/features/shorts/presentation/shorts_discovery_entry.dart';

const creatorId = '00000000-0000-4000-8000-000000000002';
const trackId = '00000000-0000-4000-8000-000000000003';

class CompletingPlayer extends TestPlayer {
  bool completed = false;
  final initialPositions = <Duration?>[];
  @override
  ProcessingState get processingState =>
      completed ? ProcessingState.completed : super.processingState;
  @override
  Future<Duration?> setUrl(
    String url, {
    Map<String, String>? headers,
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) {
    completed = false;
    initialPositions.add(initialPosition);
    return super.setUrl(url, initialPosition: initialPosition);
  }

  void complete() {
    completed = true;
    states.add(playerState);
  }
}

class CommunityFixture {
  bool following = false;
  bool failFollow = false;
  Map<String, dynamic> homeExtras = {};
  final requests = <http.Request>[];
  Map<String, dynamic> get profile => {
    'id': creatorId,
    'username': 'tqd.music',
    'displayName': 'Trần Quốc Dũng',
    'bio': 'Bản thu độc lập',
    'isSelf': false,
    'following': following,
    'followerCount': following ? 1 : 0,
    'followingCount': 0,
    'songCount': 1,
  };
  Map<String, dynamic> get song => {
    'id': trackId,
    'title': 'Một bản thu mới',
    'artist': 'Người sáng tạo',
    'genre': 'Indie',
    'community': true,
    'visibility': 'public',
    'uploader': {'id': creatorId, 'username': 'tqd.music'},
    'validPlayCount': 1,
    'likeCount': 2,
  };
  Map<String, dynamic> page(List<dynamic> items) => {
    'items': items,
    'nextOffset': null,
  };
  late final api = ApiClient(
    token: ({refresh = false}) async => 'fixture-token',
    client: MockClient((request) async {
      requests.add(request);
      final path = request.url.path;
      if (path.endsWith('/follow')) {
        if (failFollow) {
          return http.Response(
            jsonEncode({
              'error': {'code': 'COMMUNITY_UNAVAILABLE'},
            }),
            503,
          );
        }
        following = request.method == 'POST';
        return http.Response('', 204);
      }
      dynamic data;
      if (path.endsWith('/shorts/feed')) {
        data = {
          'items': [song],
          'nextCursor': null,
        };
      } else if (path.endsWith('/notifications/unread-count')) {
        data = {'count': 0};
      } else if (path.endsWith('/users/me')) {
        data = {
          ...profile,
          'username': 'listener_a',
          'displayName': 'Người nghe',
          'isSelf': true,
        };
      } else if (path.endsWith('/users/tqd.music')) {
        data = profile;
      } else if (path.endsWith('/community/search')) {
        data = {
          'users': page([profile]),
          'songs': page(
            request.url.queryParameters['q']!.startsWith('@') ? [] : [song],
          ),
          'playlists': page([]),
        };
      } else if (path.endsWith('/discover/home')) {
        data = {
          'newReleases': [song],
          'following': following ? [song] : [],
          'recent': [],
          'recommended': [song],
          ...homeExtras,
        };
      } else if (path.endsWith('/genres')) {
        data = [
          {'name': 'Indie', 'songCount': 1},
        ];
      } else if (path.endsWith('/discover/featured-creators') ||
          path.endsWith('/followers') ||
          path.endsWith('/following')) {
        data = page([profile]);
      } else if (path.endsWith('/playback')) {
        data = {'url': 'https://fixture.invalid/audio'};
      } else if (path.endsWith('/community/playlists/list-one')) {
        data = {
          'id': 'list-one',
          'title': 'Tuyển chọn',
          'description': '',
          'isSelf': true,
          'tracks': page([song]),
        };
      } else if (path.contains('/playlists')) {
        data = page([
          {
            'id': 'list-one',
            'title': 'Tuyển chọn',
            'songCount': 1,
            'visibility': 'private',
          },
        ]);
      } else if (path.endsWith('/songs') && !path.contains('/users/')) {
        data = {'items': [], 'nextCursor': null};
      } else {
        data = page([song]);
      }
      return http.Response(
        jsonEncode({'success': true, 'data': data}),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );
}

Future<ProviderContainer> showCommunity(
  WidgetTester tester,
  String route, {
  Size size = const Size(390, 844),
  double scale = 1,
  CommunityFixture? fixture,
  TestPlayer? player,
}) async {
  final data = fixture ?? CommunityFixture();
  final audio = player ?? TestPlayer();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final router = createAppRouter(initialLocation: route);
  final overrides = [
    demoModeProvider.overrideWithValue(false),
    authSessionProvider.overrideWithValue(
      const AuthSession(
        subject: 'user_a',
        name: 'Người nghe',
        sessionId: 'fixture',
      ),
    ),
    apiClientProvider.overrideWithValue(data.api),
    audioPlayerProvider.overrideWithValue(audio),
  ];
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    data.api.close();
    await audio.states.close();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: SoundShareApp(router: router, authenticationRequired: false),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(SoundShareApp)));
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_V9')) return;
    final font = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  testWidgets('Shorts entry belongs to discovery and opens the REST feed', (
    tester,
  ) async {
    final fixture = CommunityFixture();
    await showCommunity(tester, '/explore', fixture: fixture);
    expect(find.byType(ShortsDiscoveryEntry), findsOneWidget);
    if (const bool.fromEnvironment('CAPTURE_V9')) {
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('../.local/v9-shorts-entry-discovery.png'),
      );
    }
    await tester.tap(find.byType(ShortsDiscoveryEntry));
    await pumpPlaybackUi(tester);
    expect(
      fixture.requests.any((r) => r.url.path.endsWith('/shorts/feed')),
      true,
    );
    expect(find.text(fixture.song['title']), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(BackButton));
    await pumpPlaybackUi(tester);
  });
  test('Community profile and search parse API responses', () async {
    final fixture = CommunityFixture();
    final repo = CommunityRepository(fixture.api);
    final profile = await repo.profile('tqd.music');
    expect(profile.username, 'tqd.music');
    final search = await repo.search('@TQD', 'all', 0);
    expect((search['users']['items'] as List).length, 1);
    fixture.api.close();
  });
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1280, 900),
  ]) {
    for (final route in [
      '/',
      '/explore',
      '/search',
      '/u/tqd.music',
      '/profile',
      '/profile/edit',
      '/playlists',
      '/playlists/list-one',
    ]) {
      testWidgets('V3 $route fits $size at 2x text', (tester) async {
        await showCommunity(tester, route, size: size, scale: 2);
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -1800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    '@username search debounces and follow survives profile navigation',
    (tester) async {
      final fixture = CommunityFixture();
      await showCommunity(tester, '/search', fixture: fixture);
      await tester.enterText(find.byType(TextField), '@TQD');
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/community/search')),
        isEmpty,
      );
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();
      expect(find.text('@tqd.music'), findsOneWidget);
      expect(
        fixture.requests
            .where((r) => r.url.path.endsWith('/community/search'))
            .length,
        1,
      );
      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, appCopy.v3Follow),
      );
      expect(fixture.following, isTrue);
      await tapVisible(tester, find.text('@tqd.music'));
      await tester.pumpAndSettle();
      expect(find.text(appCopy.v3Following), findsWidgets);
      expect(
        fixture.requests.where((r) => r.url.path.endsWith('/follow')).length,
        1,
      );
    },
  );
  testWidgets(
    'Community playback uses the existing player across tabs and queue edits',
    (tester) async {
      final audio = TestPlayer();
      final fixture = CommunityFixture();
      final container = await showCommunity(
        tester,
        '/explore',
        player: audio,
        fixture: fixture,
      );
      await container.read(playbackActionsProvider).playFrom([
        Song.fromJson(fixture.song),
        Song.fromJson({
          ...fixture.song,
          'id': 'other',
          'title': 'Bản tiếp theo',
        }),
      ], 0);
      await tester.pumpAndSettle();
      expect(audio.loads, 1);
      expect(audio.active, isTrue);
      await tester.tap(
        find.descendant(
          of: find.byType(SoundShareBottomNavigation),
          matching: find.text(appCopy.profile),
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.loads, 1);
      expect(audio.active, isTrue);
      expect(find.byKey(const ValueKey('mini-player')), findsOneWidget);
      await container.read(playbackActionsProvider).skip(1);
      await tester.pumpAndSettle();
      expect(container.read(currentSongProvider)?.title, 'Bản tiếp theo');
      container.read(playbackActionsProvider).removeFromQueue(0);
      expect(container.read(playbackQueueProvider)?.length, 1);
      expect(audio.loads, 2);
    },
  );
  testWidgets(
    'Queue advances at completion and restores real listening progress',
    (tester) async {
      final audio = CompletingPlayer();
      final fixture = CommunityFixture();
      final container = await showCommunity(
        tester,
        '/explore',
        player: audio,
        fixture: fixture,
      );
      final actions = container.read(playbackActionsProvider);
      await actions.playFrom([
        Song.fromJson({...fixture.song, 'resumePositionMs': 12000}),
        Song.fromJson({...fixture.song, 'id': 'next-track'}),
      ], 0);
      expect(audio.initialPositions.first, const Duration(seconds: 12));
      audio.complete();
      await tester.pumpAndSettle();
      expect(container.read(currentSongIndexProvider), 1);
      expect(audio.loads, 2);
      audio.complete();
      await tester.pumpAndSettle();
      expect(
        audio.loads,
        2,
        reason: 'The queue stops at its end without looping silently.',
      );
      expect(container.read(currentSongIndexProvider), 1);
    },
  );
  testWidgets('Failed follow leaves the previous relationship intact', (
    tester,
  ) async {
    final fixture = CommunityFixture();
    await showCommunity(tester, '/u/tqd.music', fixture: fixture);
    expect(find.byType(FollowButton), findsOneWidget);
    expect(fixture.following, isFalse);
    fixture.failFollow = true;
    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, appCopy.v3Follow),
    );
    expect(fixture.following, isFalse);
    expect(find.text(appCopy.v3Unavailable), findsWidgets);
  });
}
