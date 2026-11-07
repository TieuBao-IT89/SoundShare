import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/core/widgets/catalog_widgets.dart';
import 'package:soundshare/features/explore/domain/discovery.dart';
import 'package:soundshare/features/explore/presentation/explore_screen.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/l10n/generated/app_localizations_vi.dart';

import 'support/test_app.dart';

final t = AppLocalizationsVi();

String collectionName(SampleCollection collection) =>
    collection.id == 'soft-focus' ? t.softFocusTitle : t.afterHoursTitle;
String collectionDescription(SampleCollection collection) =>
    collection.id == 'soft-focus'
    ? t.softFocusDescription
    : t.afterHoursDescription;

Uri exploreUri(WidgetTester tester) =>
    GoRouterState.of(tester.element(find.byType(ExploreScreen))).uri;
Finder genreChip(String name) => find.widgetWithText(ChoiceChip, name);
Finder collectionChip(String name, int count) =>
    find.widgetWithText(ChoiceChip, '$name · $count');

void main() {
  test(
    'Query, genre and collection intersect without changing catalog indices',
    () {
      expect(matchingSongIndices(sampleSongs, const DiscoveryFilters()), [
        0,
        1,
        2,
        3,
      ]);
      expect(
        matchingSongIndices(
          sampleSongs,
          const DiscoveryFilters(collectionId: 'soft-focus'),
        ),
        [0, 1],
      );
      expect(
        matchingSongIndices(
          sampleSongs,
          const DiscoveryFilters(
            query: ' NIA ',
            genre: ' electronic ',
            collectionId: 'after-hours',
          ),
        ),
        [3],
      );
      expect(
        matchingSongIndices(
          sampleSongs,
          const DiscoveryFilters(
            genre: 'Electronic',
            collectionId: 'soft-focus',
          ),
        ),
        isEmpty,
      );
      expect(
        matchingSongIndices(
          sampleSongs,
          const DiscoveryFilters(query: 'indie FOLK'),
        ),
        [1],
      );
    },
  );

  test('Filter links round trip reserved characters and reset to the default route', () {
    const filters = DiscoveryFilters(
      query: 'A & B / + ?',
      genre: 'R&B / Soul',
      collectionId: 'after-hours',
    );
    final parsed = DiscoveryFilters.fromUri(Uri.parse(filters.location));
    expect(parsed.query, filters.query);
    expect(parsed.genre, filters.genre);
    expect(parsed.collectionId, filters.collectionId);
    expect(const DiscoveryFilters().location, '/explore');
    expect(
      DiscoveryFilters.fromUri(Uri.parse('/explore?genre=&collection=%20'))
          .isActive,
      isFalse,
    );
  });

  test('Clearing one filter group preserves the other choices', () {
    const filters = DiscoveryFilters(
      query: 'Blue',
      genre: 'Electronic',
      collectionId: 'after-hours',
    );
    expect(filters.withQuery('').genre, 'Electronic');
    expect(filters.withQuery('').collectionId, 'after-hours');
    expect(filters.withGenre(null).query, 'Blue');
    expect(filters.withGenre(null).collectionId, 'after-hours');
    expect(filters.withCollection(null).query, 'Blue');
    expect(filters.withCollection(null).genre, 'Electronic');
  });

  test('Genre options reflect catalog values without case or whitespace duplicates', () {
    final songs = [
      for (final genre in [' Jazz ', 'jazz', 'Electronic', ' '])
        Song(
          title: 'Sample',
          artist: 'Sample',
          artwork: '',
          duration: '1:00',
          genre: genre,
        ),
    ];
    expect(catalogGenres(songs), ['Electronic', 'Jazz']);
    expect(matchingSongIndices(songs, const DiscoveryFilters(genre: 'JAZZ')), [
      0,
      1,
    ]);
    expect(catalogGenres([]), isEmpty);
  });

  test(
    'Unknown or empty collections never silently return unrelated tracks',
    () {
      expect(
        matchingSongIndices(
          sampleSongs,
          const DiscoveryFilters(collectionId: 'unknown'),
        ),
        isEmpty,
      );
      expect(
        matchingSongIndices([
          sampleSongs.last,
        ], const DiscoveryFilters(collectionId: 'soft-focus')),
        isEmpty,
      );
      expect(matchingSongIndices([], const DiscoveryFilters()), isEmpty);
    },
  );

  for (final collection in sampleCollections) {
    testWidgets('Home opens the ${collection.title} sample collection', (
      tester,
    ) async {
      await showApp(tester, '/');
      expect(find.text(t.collectionsDemoSubtitle), findsOneWidget);
      await tapVisible(tester, find.text(collectionName(collection)));
      expect(exploreUri(tester).queryParameters['collection'], collection.id);
      expect(
        tester
            .widget<ChoiceChip>(collectionChip(collectionName(collection), 2))
            .selected,
        isTrue,
      );
      expect(find.byType(SongTile), findsNWidgets(2));
      expect(find.text(collectionDescription(collection)), findsOneWidget);
      await tapVisible(tester, find.text(t.clearAll));
      expect(exploreUri(tester).queryParameters, isEmpty);
      expect(find.byType(SongTile), findsNWidgets(4));
    });
  }

  testWidgets(
    'Combined filters select the original song and survive returning from Player',
    (tester) async {
      final container = await showApp(
        tester,
        '/explore?collection=after-hours&genre=Electronic&q=NIA',
      );
      expect(find.byType(SongTile), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'NIA',
      );
      await tapVisible(tester, find.byTooltip(t.playSong('Blue Again')));
      expect(container.read(currentSongIndexProvider), 3);
      await tapVisible(tester, find.byTooltip(t.backToBrowsing));
      expect(exploreUri(tester).queryParameters, {
        'collection': 'after-hours',
        'genre': 'Electronic',
        'q': 'NIA',
      });
      expect(find.byType(SongTile), findsOneWidget);
      await tapVisible(tester, find.text(t.clearAll), scrollDelta: -300);
      expect(exploreUri(tester).queryParameters, isEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byType(SongTile), findsNWidgets(4));
      expect(find.byKey(const ValueKey('mini-player')), findsOneWidget);
    },
  );

  testWidgets(
    'Search, genre and collection can each be removed independently',
    (tester) async {
      await showApp(
        tester,
        '/explore?collection=after-hours&genre=Electronic&q=Blue',
      );
      await tapVisible(tester, find.byTooltip(t.clearSearch));
      expect(exploreUri(tester).queryParameters, {
        'collection': 'after-hours',
        'genre': 'Electronic',
      });
      await tapVisible(tester, genreChip(t.allGenres));
      expect(exploreUri(tester).queryParameters, {'collection': 'after-hours'});
      expect(find.byType(SongTile), findsNWidgets(2));
      await tapVisible(tester, collectionChip(t.afterHoursTitle, 2));
      expect(exploreUri(tester).queryParameters, isEmpty);
      expect(find.text(t.clearAll), findsNothing);
      expect(find.byType(SongTile), findsNWidgets(4));
    },
  );

  testWidgets(
    'Editing an empty search keeps the keyboard focus for the next query',
    (tester) async {
      await showApp(tester, '/explore');
      await tester.enterText(find.byType(TextField), 'Blue');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'Golden');
      await tester.pumpAndSettle();
      expect(find.text('Golden Hour'), findsOneWidget);
      expect(find.byType(SongTile), findsOneWidget);
    },
  );

  testWidgets(
    'Conflicting choices show no results with a way back to all tracks',
    (tester) async {
      await showApp(tester, '/explore?collection=soft-focus&genre=Electronic');
      expect(find.text(t.resultsCount(0)), findsOneWidget);
      expect(find.text(t.noResults), findsOneWidget);
      expect(
        tester.widget<ChoiceChip>(genreChip('Electronic')).selected,
        isTrue,
      );
      expect(
        tester.widget<ChoiceChip>(collectionChip(t.softFocusTitle, 2)).selected,
        isTrue,
      );
      await tapVisible(tester, find.text(t.browseAllTracks));
      expect(find.byType(SongTile), findsNWidgets(4));
      expect(exploreUri(tester).queryParameters, isEmpty);
    },
  );

  testWidgets(
    'A collection with no matching catalog members has its own empty state',
    (tester) async {
      await showApp(
        tester,
        '/explore?collection=soft-focus',
        repository: TestRepository(() async => [sampleSongs.last]),
      );
      expect(collectionChip(t.softFocusTitle, 0), findsOneWidget);
      expect(find.text(t.collectionQuiet), findsOneWidget);
      await tapVisible(tester, find.text(t.browseAllTracks));
      expect(find.text('Blue Again'), findsOneWidget);
    },
  );

  testWidgets(
    'Unavailable collection and genre links remain visible and removable',
    (tester) async {
      await showApp(tester, '/explore?collection=missing&genre=Jazz');
      expect(find.text(t.collectionUnavailable), findsOneWidget);
      expect(find.text(t.unknownCollection), findsOneWidget);
      await tapVisible(tester, find.byTooltip(t.removeUnknownCollection));
      expect(exploreUri(tester).queryParameters, {'genre': 'Jazz'});
      await tapVisible(tester, find.byTooltip(t.removeUnknownGenre));
      expect(exploreUri(tester).queryParameters, isEmpty);
      expect(find.byType(SongTile), findsNWidgets(4));
    },
  );

  testWidgets('Catalog loading, failure and retry retain active choices', (
    tester,
  ) async {
    final pending = Completer<List<Song>>();
    var calls = 0;
    await showApp(
      tester,
      '/explore?collection=after-hours',
      repository: TestRepository(
        () => ++calls == 1 ? pending.future : Future.value(sampleSongs),
      ),
    );
    expect(find.byType(CatalogLoading), findsOneWidget);
    expect(find.text(t.clearAll), findsOneWidget);
    pending.completeError(StateError('private details'));
    await tester.pumpAndSettle();
    expect(find.text(t.catalogLoadFailed), findsOneWidget);
    expect(find.textContaining('private details'), findsNothing);
    await tapVisible(tester, find.text(t.tryAgain));
    expect(exploreUri(tester).queryParameters['collection'], 'after-hours');
    expect(find.byType(SongTile), findsNWidgets(2));
  });

  testWidgets(
    'An empty catalog differs from empty filter results and can reset choices',
    (tester) async {
      await showApp(
        tester,
        '/explore?genre=Jazz&q=anything',
        repository: TestRepository(() async => []),
      );
      expect(find.text(t.sampleEmpty), findsOneWidget);
      expect(find.text(t.noResults), findsNothing);
      await tapVisible(tester, find.text(t.clearAll));
      expect(exploreUri(tester).queryParameters, isEmpty);
      expect(find.text(t.sampleEmpty), findsOneWidget);
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets(
      'Active filters fit ${size.width.toInt()} phones with large text',
      (tester) async {
        final longGenre = List.filled(5, 'Long genre').join(' ');
        await showApp(
          tester,
          DiscoveryFilters(
            query: 'no match',
            genre: longGenre,
            collectionId: 'after-hours',
          ).location,
          size: size,
          textScale: 2,
          repository: TestRepository(
            () async => [
              Song(
                title: 'A sample track',
                artist: 'Sample artist',
                artwork: sampleSongs.first.artwork,
                duration: '1:00',
                genre: longGenre,
              ),
            ],
          ),
        );
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -1800),
        );
        await tester.pumpAndSettle();
        expect(find.text(t.collectionQuiet), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text(t.clearAll), scrollDelta: -300);
        expect(exploreUri(tester).queryParameters, isEmpty);
      },
    );
  }

  testWidgets(
    'Filter choices expose selected semantics and accessible touch targets',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await showApp(
          tester,
          '/explore?genre=Electronic&collection=after-hours',
        );
        final genre = genreChip('Electronic');
        expect(
          tester.getSemantics(genre),
          matchesSemantics(
            label: 'Electronic',
            isSelected: true,
            hasSelectedState: true,
            isEnabled: true,
            hasEnabledState: true,
            isFocusable: true,
            hasTapAction: true,
            hasFocusAction: true,
            isButton: true,
          ),
        );
        expect(tester, meetsGuideline(androidTapTargetGuideline));
        expect(tester, meetsGuideline(labeledTapTargetGuideline));
      } finally {
        handle.dispose();
      }
    },
  );
}
