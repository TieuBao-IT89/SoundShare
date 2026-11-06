import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/music_recommendation.dart';

String recommendationDescription(
  AppLocalizations copy,
  HomeRecommendation? recommendation,
) => switch (recommendation?.strategy) {
  RecommendationStrategy.personalized => copy.recommendationPersonalized,
  RecommendationStrategy.newReleases => copy.recommendationNewListener,
  null => copy.v3RecommendationNote,
};

String recommendationReasonLabel(
  AppLocalizations copy,
  SongRecommendationReason reason,
) => switch (reason.code) {
  SongRecommendationCode.listeningTime =>
    reason.genre != null && reason.daypart != null
        ? copy.recommendationListeningTimeGenre(
            reason.genre!,
            switch (reason.daypart!) {
              RecommendationDaypart.night => copy.recommendationAtNight,
              RecommendationDaypart.morning => copy.recommendationInMorning,
              RecommendationDaypart.afternoon => copy.recommendationInAfternoon,
              RecommendationDaypart.evening => copy.recommendationInEvening,
            },
          )
        : copy.recommendationListeningTime,
  SongRecommendationCode.likedGenre =>
    reason.genre != null
        ? copy.recommendationLikedGenre(reason.genre!)
        : copy.recommendationLikedGenreFallback,
  SongRecommendationCode.listeningHistory =>
    copy.recommendationListeningHistory,
  SongRecommendationCode.following => copy.recommendationFollowing,
  SongRecommendationCode.savedGenre =>
    reason.genre != null
        ? copy.recommendationSavedGenre(reason.genre!)
        : copy.recommendationSavedGenreFallback,
  SongRecommendationCode.newRelease => copy.recommendationNewRelease,
};
