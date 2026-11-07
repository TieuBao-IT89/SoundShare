import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/listening_panel.dart';
import 'package:soundshare/core/widgets/app_scaffold.dart';
import 'package:soundshare/features/community/data/community_repository.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'community_test.dart' show CommunityFixture, showCommunity;
import 'support/test_app.dart';

void main() {
  for (final width in [320.0, 390.0, 430.0, 768.0, 1024.0, 1280.0, 1440.0]) {
    for (final route in [
      '/',
      '/explore',
      '/search',
      '/library',
      '/profile',
      '/player',
    ]) {
      testWidgets('Obsidian $route at $width with active playback', (
        tester,
      ) async {
        final fixture = CommunityFixture();
        final player = TestPlayer();
        final container = await showCommunity(
          tester,
          route,
          fixture: fixture,
          player: player,
          size: Size(width, 900),
        );
        await container.read(playbackActionsProvider).playFrom([
          Song.fromJson(fixture.song),
        ], 0);
        await pumpPlaybackUi(tester);
        expect(player.active, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'Play all reads every page in order and deduplicates overlapping items',
    () async {
      final offsets = <int>[];
      final fixture = CommunityFixture();
      final api = ApiClient(
        token: ({refresh = false}) async => 'fixture-token',
        client: MockClient((request) async {
          final offset = int.parse(request.url.queryParameters['offset']!);
          offsets.add(offset);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'tracks': {
                  'items': offset == 0
                      ? [fixture.song]
                      : [
                          fixture.song,
                          {...fixture.song, 'id': 'second-song'},
                        ],
                  'nextOffset': offset == 0 ? 20 : null,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(api.close);
      final songs = await CommunityRepository(api)
          .playlistQueue('playlist-one');
      expect(offsets, [0, 20]);
      expect(songs.map((s) => s.id), [fixture.song['id'], 'second-song']);
    },
  );

  test('Play all rejects a failed page and non-advancing pagination', () async {
    for (final failedPage in [false, true]) {
      final api = ApiClient(
        token: ({refresh = false}) async => 'fixture-token',
        client: MockClient((request) async {
          final offset = int.parse(request.url.queryParameters['offset']!);
          if (offset > 0 && failedPage) {
            return http.Response(
              jsonEncode({
                'error': {'code': 'COMMUNITY_UNAVAILABLE'},
              }),
              503,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'tracks': {'items': [], 'nextOffset': offset == 0 ? 20 : 20},
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      await expectLater(
        CommunityRepository(api).playlistQueue('playlist-one'),
        throwsA(anything),
      );
    }
  });

  testWidgets('Playlist play all and shuffle use the existing player', (
    tester,
  ) async {
    final player = TestPlayer();
    final container = await showCommunity(
      tester,
      '/playlists/list-one',
      player: player,
    );
    await tester.tap(find.text(appCopy.v4ShufflePlay));
    await pumpPlaybackUi(tester);
    expect(player.active, isTrue);
    expect(player.shuffleOn, isTrue);
    expect(container.read(playbackQueueProvider), hasLength(1));
    expect(player.loads, 1);
  });

  for (final viewport in [
    (1024.0, 1.0),
    (1440.0, 1.0),
    (768.0, 2.0),
    (1440.0, 2.0),
  ]) {
    final (width, scale) = viewport;
    testWidgets(
      'Queue drawer/panel and volume control work at $width with ${scale}x text',
      (tester) async {
        final fixture = CommunityFixture();
        final player = TestPlayer();
        final container = await showCommunity(
          tester,
          '/',
          fixture: fixture,
          player: player,
          size: Size(width, 900),
          scale: scale,
        );
        await container.read(playbackActionsProvider).playFrom([
          Song.fromJson(fixture.song),
          Song.fromJson({...fixture.song, 'id': 'second-song'}),
        ], 0);
        await tester.pumpAndSettle();
        if (width >= 1280 && scale == 1) {
          final volume = tester.widgetList<Slider>(find.byType(Slider)).last;
          volume.onChanged!(.35);
          await tester.pumpAndSettle();
          expect(player.volume, closeTo(.35, .001));
        }
        final dock = find.byKey(const ValueKey('mini-player'));
        expect(tester.getSize(dock).height, lessThan(220));
        final router = GoRouter.of(tester.element(find.byType(AppScaffold)));
        for (final route in ['/explore', '/profile', '/']) {
          router.go(route);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip(appCopy.v3Queue));
        await tester.pumpAndSettle();
        expect(container.read(queuePanelVisibleProvider), isTrue);
        expect(find.byType(ListeningPanel), findsOneWidget);
        if (scale == 1) {
          tester.view.physicalSize = Size(width == 1440 ? 1024 : 1440, 900);
          await tester.pumpAndSettle();
          expect(find.byType(ListeningPanel), findsOneWidget);
          expect(container.read(queuePanelVisibleProvider), isTrue);
        }
        await tester.tap(find.byTooltip(appCopy.v4CloseQueue));
        await tester.pumpAndSettle();
        expect(container.read(queuePanelVisibleProvider), isFalse);
        router.go('/explore');
        await tester.pumpAndSettle();
        expect(find.byType(ListeningPanel), findsNothing);
        expect(player.active, isTrue);
        expect(player.loads, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
