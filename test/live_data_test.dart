import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soundshare/app/theme/app_theme.dart';
import 'package:soundshare/core/services/api_client.dart';
import 'package:soundshare/features/auth/domain/auth_session.dart';
import 'package:soundshare/features/auth/presentation/session_scope.dart';
import 'package:soundshare/features/explore/domain/discovery.dart';
import 'package:soundshare/features/home/application/catalog_provider.dart';
import 'package:soundshare/features/home/data/api_song_repository.dart';
import 'package:soundshare/features/home/domain/track_draft.dart';
import 'package:soundshare/features/upload/presentation/upload_screen.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'support/test_app.dart';

import 'package:file_picker/file_picker.dart';

http.Response ok(dynamic data, [int status = 200]) =>
    http.Response(jsonEncode({'success': true, 'data': data}), status);
Future<String> fixtureToken({bool refresh = false}) async =>
    refresh ? 'fresh-fixture' : 'old-fixture';

void main() {
  testWidgets(
    'Clerk name edits update UI without resetting session data or client',
    (tester) async {
      var clients = 0;
      var verifications = 0;
      ProviderContainer? identity;
      Widget account(String name) => ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: SessionScope(
            key: const ValueKey('same-active-session'),
            session: AuthSession(
              subject: 'one',
              name: name,
              sessionId: 'session-one',
            ),
            token: fixtureToken,
            signOut: () async {},
            createClient: (token) {
              clients++;
              return ApiClient(
                token: token,
                client: MockClient((_) async {
                  verifications++;
                  return ok({'id': 'one'});
                }),
              );
            },
            child: Consumer(
              builder: (context, ref, _) {
                identity = ProviderScope.containerOf(context);
                return Text(
                  '${ref.watch(authSessionProvider)!.name}:${ref.watch(likedSongIndicesProvider).length}',
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpWidget(account('Tên cũ'));
      await tester.pumpAndSettle();
      final original = identity!;
      original.read(likedSongIndicesProvider.notifier).state = {0, 1};
      await tester.pumpAndSettle();
      await tester.pumpWidget(account('Tên mới'));
      await tester.pumpAndSettle();
      expect(find.text('Tên mới:2'), findsOneWidget);
      expect(identity, same(original));
      expect(clients, 1);
      expect(verifications, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'API refreshes a rejected token once and never returns provider details',
    () async {
      var calls = 0;
      final api = ApiClient(
        token: fixtureToken,
        client: MockClient((request) async {
          calls++;
          expect(
            request.headers['Authorization'],
            'Bearer ${calls == 1 ? 'old' : 'fresh'}-fixture',
          );
          return calls == 1
              ? http.Response(
                  jsonEncode({
                    'error': {
                      'code': 'UNAUTHORIZED',
                      'message': 'private-sentinel',
                    },
                  }),
                  401,
                )
              : ok({'id': 'account'});
        }),
      );
      expect((await api.request('GET', '/auth/me'))['id'], 'account');
      expect(calls, 2);
      api.close();
      final denied = ApiClient(
        token: fixtureToken,
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'code': 'UNAUTHORIZED', 'message': 'private-sentinel'},
            }),
            401,
          ),
        ),
      );
      await expectLater(
        denied.request('GET', '/auth/me'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having(
                (e) => e.message.contains('private-sentinel'),
                'safe message',
                false,
              ),
        ),
      );
      denied.close();
    },
  );

  test('Catalog follows cursors, searches at the server and fetches fresh playback access', () async {
    final requests = <http.Request>[];
    final api = ApiClient(
      token: fixtureToken,
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/playback')) {
          return ok({
            'url': 'https://example.com/temporary-audio',
            'expiresAt': '2026-11-05T12:00:00Z',
          });
        }
        if (request.url.path.endsWith('/favorite')) {
          return http.Response('', 204);
        }
        return ok({
          'items': [
            {
              'id': request.url.queryParameters['cursor'] == null
                  ? 'one'
                  : 'two',
              'title': 'Own song',
              'artist': 'Owner',
              'genre': 'Jazz',
              'liked': true,
              'artwork': null,
            },
          ],
          'nextCursor': request.url.queryParameters['cursor'] == null
              ? 'page-two'
              : null,
        });
      }),
    );
    final repository = ApiSongRepository(api);
    final songs = await repository.featured();
    expect(songs.map((song) => song.id), ['one', 'two']);
    expect(songs.first.audioUrl, isEmpty);
    expect(songs.first.liked, isTrue);
    expect(
      await repository.playback(songs.first),
      'https://example.com/temporary-audio',
    );
    await repository.favorite(songs.first, true);
    await repository.favorite(songs.first, false);
    expect(requests.map((request) => request.method), [
      'GET',
      'GET',
      'GET',
      'PUT',
      'DELETE',
    ]);
    await repository.search(
      const DiscoveryFilters(query: 'Own song', genre: 'Jazz'),
    );
    expect(requests.last.url.queryParameters['query'], 'Own song');
    expect(requests.last.url.queryParameters['genre'], 'Jazz');
    expect(requests.last.url.queryParameters.containsKey('owner'), isFalse);
    api.close();
  });

  test(
    'A repeated server cursor fails safely instead of fetching forever',
    () async {
      final api = ApiClient(
        token: fixtureToken,
        client: MockClient(
          (_) async => ok({'items': [], 'nextCursor': 'repeated'}),
        ),
      );
      await expectLater(
        ApiSongRepository(api).featured(),
        throwsA(isA<ApiException>()),
      );
      api.close();
    },
  );

  test(
    'Upload uses typed multipart then persists only asset IDs and metadata',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        token: fixtureToken,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.contains('/uploads/')) {
            expect(
              request.headers['content-type'],
              contains('multipart/form-data'),
            );
            expect(
              request.body,
              contains(
                request.url.path.endsWith('/audio')
                    ? 'audio/mpeg'
                    : 'image/png',
              ),
            );
            return ok({
              'id': request.url.path.endsWith('/audio')
                  ? 'audio-id'
                  : 'artwork-id',
            }, 201);
          }
          expect(jsonDecode(request.body), {
            'audioAssetId': 'audio-id',
            'artworkAssetId': 'artwork-id',
            'title': 'My track',
            'artist': 'Me',
            'genre': 'Jazz',
            'description': '',
            'visibility': 'private',
            'rightsConfirmed': false,
          });
          return ok({'id': 'track-id'}, 201);
        }),
      );
      await ApiSongRepository(api).upload(
        TrackDraft(
          title: 'My track',
          artist: 'Me',
          genre: 'Jazz',
          description: '',
          audioName: 'mine.mp3',
          audioBytes: Uint8List.fromList([1, 2, 3]),
          artworkName: 'cover.png',
          artworkBytes: Uint8List.fromList([4, 5]),
        ),
      );
      expect(requests.length, 3);
      api.close();
    },
  );

  test(
    'Metadata retry reuses confirmed assets after a lost response',
    () async {
      var uploads = 0;
      var commits = 0;
      final ids = <String>[];
      final api = ApiClient(
        token: fixtureToken,
        client: MockClient((request) async {
          if (request.url.path.contains('/uploads/')) {
            uploads++;
            return ok({'id': 'confirmed-audio'}, 201);
          }
          commits++;
          ids.add(jsonDecode(request.body)['audioAssetId'] as String);
          if (commits == 1) throw http.ClientException('Lost fixture response');
          return ok({'id': 'same-track'}, 200);
        }),
      );
      addTearDown(api.close);
      final repository = ApiSongRepository(api);
      final draft = TrackDraft(
        title: 'Bản thu',
        artist: 'Tôi',
        genre: 'Ambient',
        description: '',
        audioName: 'own.mp3',
        audioBytes: Uint8List.fromList([1, 2, 3]),
      );
      await expectLater(repository.upload(draft), throwsA(isA<ApiException>()));
      await repository.upload(draft);
      expect(uploads, 1);
      expect(commits, 2);
      expect(ids, ['confirmed-audio', 'confirmed-audio']);
    },
  );

  test(
    'Publishing requires a chosen profile before transferring files',
    () async {
      final api = ApiClient(
        token: fixtureToken,
        client: MockClient((request) async {
          expect(request.url.path, endsWith('/users/me'));
          return ok({'username': null});
        }),
      );
      addTearDown(api.close);
      await expectLater(
        ApiSongRepository(api).upload(
          TrackDraft(
            title: 'Bản thu',
            artist: 'Tôi',
            genre: 'Ambient',
            description: '',
            audioName: 'own.mp3',
            audioBytes: Uint8List(3),
            visibility: 'public',
            rightsConfirmed: true,
          ),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'PROFILE_REQUIRED'),
        ),
      );
    },
  );

  testWidgets(
    'A stalled session stops loading, ignores late success and can retry on a narrow screen',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });
      final pendingToken = Completer<String>();
      var stalled = true;
      var signOuts = 0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: SessionScope(
              session: const AuthSession(subject: 'one', name: 'Owner'),
              token: ({bool refresh = false}) => stalled
                  ? pendingToken.future
                  : fixtureToken(refresh: refresh),
              signOut: () async {
                signOuts++;
              },
              createClient: (token) => ApiClient(
                token: token,
                client: MockClient((_) async => ok({'id': 'account'})),
              ),
              child: const Text('Private library content'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.ensureVisible(find.text(appCopy.signOut));
      await tester.tap(find.text(appCopy.signOut));
      await tester.pump();
      expect(signOuts, 1);
      await tester.pump(const Duration(seconds: 26));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(appCopy.sessionTimeout), findsOneWidget);
      expect(find.text('Private library content'), findsNothing);
      pendingToken.complete('late-fixture');
      await tester.pumpAndSettle();
      expect(find.text('Private library content'), findsNothing);
      expect(find.text(appCopy.sessionTimeout), findsOneWidget);
      stalled = false;
      await tester.ensureVisible(find.text(appCopy.tryAgain));
      await tester.tap(find.text(appCopy.tryAgain));
      await tester.pumpAndSettle();
      expect(find.text('Private library content'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Backend rejection gates the library and retry opens it only after verification',
    (tester) async {
      var allow = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark,
            home: SessionScope(
              session: const AuthSession(subject: 'one', name: 'Owner'),
              token: fixtureToken,
              signOut: () async {},
              createClient: (token) => ApiClient(
                token: token,
                client: MockClient(
                  (_) async => allow
                      ? ok({'id': 'account'})
                      : http.Response(
                          jsonEncode({
                            'error': {'code': 'UNAUTHORIZED'},
                          }),
                          401,
                        ),
                ),
              ),
              child: const Text('Private library content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private library content'), findsNothing);
      expect(find.text(appCopy.sessionInvalid), findsOneWidget);
      allow = true;
      await tester.tap(find.text(appCopy.tryAgain));
      await tester.pumpAndSettle();
      expect(find.text('Private library content'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Switching accounts discards previous likes and uses the new identity',
    (tester) async {
      Widget account(String subject) => ProviderScope(
        child: MaterialApp(
          home: SessionScope(
            key: ValueKey(subject),
            session: AuthSession(subject: subject, name: subject),
            token: fixtureToken,
            signOut: () async {},
            createClient: (token) => ApiClient(
              token: token,
              client: MockClient((_) async => ok({'id': subject})),
            ),
            child: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  Text(
                    '${ref.watch(authSessionProvider)!.subject}:${ref.watch(likedSongIndicesProvider).length}',
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(likedSongIndicesProvider.notifier).state = {1},
                    child: const Text('Like fixture'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(account('first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Like fixture'));
      await tester.pump();
      expect(find.text('first:1'), findsOneWidget);
      await tester.pumpWidget(account('second'));
      await tester.pumpAndSettle();
      expect(find.text('second:0'), findsOneWidget);
      expect(find.text('first:1'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Real upload never reports success before metadata commit and can retry',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1800);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });
      final picker = TestPicker()
        ..choose = () async => FilePickerResult([
          PlatformFile(
            name: 'own.mp3',
            size: 3,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        ]);
      var fail = true;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: UploadScreen(
            filePicker: picker,
            onUpload: (_) async {
              if (fail) throw const ApiException(503, 'DATABASE_UNAVAILABLE');
            },
          ),
        ),
      );
      await tapVisible(tester, find.text(appCopy.chooseMp3));
      await tester.enterText(find.byType(TextFormField).at(0), 'My song');
      await tester.enterText(find.byType(TextFormField).at(1), 'Me');
      await tapVisible(tester, find.text(appCopy.uploadButton));
      expect(find.text(appCopy.uploadSaved), findsNothing);
      expect(find.text(appCopy.previewReady), findsNothing);
      fail = false;
      await tapVisible(tester, find.text(appCopy.uploadButton));
      expect(find.text(appCopy.uploadSaved), findsOneWidget);
    },
  );
}
