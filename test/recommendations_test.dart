import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/core/services/audio_service.dart';
import 'package:soundshare/features/community/data/community_repository.dart';
import 'package:soundshare/features/community/presentation/music_components.dart';
import 'package:soundshare/features/community/presentation/recommendation_copy.dart';
import 'package:soundshare/features/home/domain/music_recommendation.dart';
import 'package:soundshare/features/home/domain/song.dart';
import 'package:soundshare/l10n/l10n.dart';

import 'community_test.dart' show CommunityFixture, showCommunity;
import 'support/test_app.dart' show TestPlayer;

Map<String, dynamic> recommendationContext({
  String strategy = 'personalized',
}) => {
  'version': 'taste-v1',
  'strategy': strategy,
  'daypart': 'night',
  'utcOffsetMinutes': 420,
  'experimental': true,
};

CommunityFixture recommendationFixture({String strategy = 'personalized'}) {
  final fixture = CommunityFixture()..following = true;
  fixture.homeExtras = {
    'recommendation': recommendationContext(strategy: strategy),
    'recommended': [
      {
        ...fixture.song,
        'id': 'recommended-track',
        'title': 'Đêm trong phòng thu',
        'genre': 'Lo-fi',
        'recommendationReason': {
          'code': strategy == 'personalized' ? 'listening-time' : 'new-release',
          'genre': 'Lo-fi',
          'daypart': 'night',
        },
      },
    ],
  };
  return fixture;
}

void main() {
  test(
    'Home sends the current device offset and bounds explicit context',
    () async {
      final fixture = CommunityFixture();
      addTearDown(fixture.api.close);
      final repository = CommunityRepository(fixture.api);
      await repository.home();
      expect(fixture.requests.last.url.queryParameters, {
        'utcOffsetMinutes':
            '${DateTime.now().timeZoneOffset.inMinutes.clamp(-720, 840)}',
      });
      for (final offset in [-900, -720, 0, 345, 840, 1000]) {
        await repository.home(utcOffsetMinutes: offset);
        expect(
          fixture.requests.last.url.queryParameters['utcOffsetMinutes'],
          '${offset.clamp(-720, 840)}',
        );
      }
    },
  );

  test(
    'Home context parses the supported version and safely ignores unknown data',
    () {
      final context = HomeRecommendation.tryParse(recommendationContext())!;
      expect(context.strategy, RecommendationStrategy.personalized);
      expect(context.daypart, RecommendationDaypart.night);
      expect(context.utcOffsetMinutes, 420);
      expect(context.experimental, isTrue);
      expect(
        HomeRecommendation.tryParse(
          recommendationContext(strategy: 'new-releases'),
        )?.strategy,
        RecommendationStrategy.newReleases,
      );
      for (final invalid in [
        null,
        'old-reason',
        <String, dynamic>{},
        {...recommendationContext(), 'version': 'future-v2'},
        {...recommendationContext(), 'strategy': 'unknown'},
        {...recommendationContext(), 'daypart': 'unknown'},
        {...recommendationContext(), 'utcOffsetMinutes': -721},
        {...recommendationContext(), 'utcOffsetMinutes': 841},
        {...recommendationContext(), 'utcOffsetMinutes': '420'},
      ]) {
        expect(HomeRecommendation.tryParse(invalid), isNull);
      }
    },
  );

  test(
    'Song reasons retain known public fields without requiring metadata',
    () {
      final fixture = CommunityFixture();
      final song = Song.fromJson({
        ...fixture.song,
        'recommendationReason': {
          'code': 'listening-time',
          'genre': 'Lo-fi',
          'daypart': 'night',
        },
      });
      expect(
        song.recommendationReason?.code,
        SongRecommendationCode.listeningTime,
      );
      expect(song.recommendationReason?.genre, 'Lo-fi');
      expect(song.recommendationReason?.daypart, RecommendationDaypart.night);
      expect(Song.fromJson(fixture.song).recommendationReason, isNull);
      expect(
        Song.fromJson({
          ...fixture.song,
          'recommendationReason': {'code': 'future-code'},
        }).recommendationReason,
        isNull,
      );
      expect(SongRecommendationReason.tryParse('raw backend copy'), isNull);
    },
  );

  test('Each reason uses Vietnamese copy tied to the actual signal', () {
    final expected = {
      'listening-time': appCopy.recommendationListeningTimeGenre(
        'Lo-fi',
        appCopy.recommendationAtNight,
      ),
      'liked-genre': appCopy.recommendationLikedGenre('Lo-fi'),
      'listening-history': appCopy.recommendationListeningHistory,
      'following': appCopy.recommendationFollowing,
      'saved-genre': appCopy.recommendationSavedGenre('Lo-fi'),
      'new-release': appCopy.recommendationNewRelease,
    };
    for (final entry in expected.entries) {
      final reason = SongRecommendationReason.tryParse({
        'code': entry.key,
        'genre': 'Lo-fi',
        'daypart': 'night',
      })!;
      expect(recommendationReasonLabel(appCopy, reason), entry.value);
    }
    for (final entry in {
      'morning': appCopy.recommendationInMorning,
      'afternoon': appCopy.recommendationInAfternoon,
      'evening': appCopy.recommendationInEvening,
    }.entries) {
      expect(
        recommendationReasonLabel(
          appCopy,
          SongRecommendationReason.tryParse({
            'code': 'listening-time',
            'genre': 'Lo-fi',
            'daypart': entry.key,
          })!,
        ),
        appCopy.recommendationListeningTimeGenre('Lo-fi', entry.value),
      );
    }
    expect(
      recommendationReasonLabel(
        appCopy,
        SongRecommendationReason.tryParse({'code': 'listening-time'})!,
      ),
      appCopy.recommendationListeningTime,
    );
  });

  testWidgets(
    'Personal recommendations explain habits and play with the existing player',
    (tester) async {
      final fixture = recommendationFixture();
      final audio = TestPlayer();
      final container = await showCommunity(
        tester,
        '/',
        fixture: fixture,
        player: audio,
      );
      expect(find.text(appCopy.v3ForYou), findsOneWidget);
      expect(find.text(appCopy.recommendationPersonalized), findsOneWidget);
      final rail = find.byType(SongArtworkRail);
      final reason = appCopy.recommendationListeningTimeGenre(
        'Lo-fi',
        appCopy.recommendationAtNight,
      );
      expect(
        find.descendant(of: rail, matching: find.text(reason)),
        findsOneWidget,
      );
      await tester.ensureVisible(rail);
      await tester.pumpAndSettle();
      final artwork = find
          .descendant(of: rail, matching: find.byType(InkWell))
          .first;
      await tester.tap(artwork);
      await tester.pumpAndSettle();
      expect(audio.loads, 1);
      expect(audio.active, isTrue);
      expect(
        container.read(currentSongProvider)?.identity,
        'recommended-track',
      );
      expect(
        container.read(playbackQueueProvider)?.single.identity,
        'recommended-track',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Cold start states new releases honestly', (tester) async {
    await showCommunity(
      tester,
      '/',
      fixture: recommendationFixture(strategy: 'new-releases'),
    );
    expect(find.text(appCopy.recommendationNewListener), findsOneWidget);
    expect(find.text(appCopy.recommendationPersonalized), findsNothing);
    expect(find.text(appCopy.recommendationNewRelease), findsOneWidget);
  });

  testWidgets(
    'Older responses retain a generic note without invented reasons',
    (tester) async {
      await showCommunity(tester, '/');
      expect(find.text(appCopy.v3RecommendationNote), findsOneWidget);
      expect(find.text(appCopy.recommendationPersonalized), findsNothing);
      expect(find.text(appCopy.recommendationNewListener), findsNothing);
      final rail = tester.widget<SongArtworkRail>(find.byType(SongArtworkRail));
      expect(rail.songs.single.recommendationReason, isNull);
    },
  );

  testWidgets(
    'Reasons fit 320px at 2x text and stay out of the following feed',
    (tester) async {
      final fixture = recommendationFixture();
      // Long genre metadata must wrap/truncate within the existing artwork rail.
      fixture.homeExtras['recommended'][0]['recommendationReason']['genre'] =
          'Lo-fi và những bản thu thể nghiệm về đêm';
      await showCommunity(
        tester,
        '/',
        fixture: fixture,
        size: const Size(320, 640),
        scale: 2,
      );
      await tester.ensureVisible(find.byType(SongArtworkRail));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final tabs = find.byType(ContentTabs);
      await tester.ensureVisible(tabs);
      await tester.pumpAndSettle();
      await tester.drag(tabs, const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ChoiceChip, appCopy.v3FollowingFeed),
      );
      await tester.pumpAndSettle();
      final rail = tester.widget<SongArtworkRail>(find.byType(SongArtworkRail));
      expect(rail.showRecommendationReasons, isFalse);
      expect(find.text(appCopy.recommendationPersonalized), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
