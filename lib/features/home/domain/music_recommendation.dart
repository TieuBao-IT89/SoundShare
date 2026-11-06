enum RecommendationDaypart {
  night,
  morning,
  afternoon,
  evening;

  static RecommendationDaypart? tryParse(Object? value) => switch (value) {
    'night' => night,
    'morning' => morning,
    'afternoon' => afternoon,
    'evening' => evening,
    _ => null,
  };
}

enum RecommendationStrategy { personalized, newReleases }

/// Optional, versioned context. Missing metadata keeps generic discovery copy.
class HomeRecommendation {
  const HomeRecommendation({
    required this.strategy,
    required this.daypart,
    required this.utcOffsetMinutes,
    required this.experimental,
  });

  final RecommendationStrategy strategy;
  final RecommendationDaypart daypart;
  final int utcOffsetMinutes;
  final bool experimental;

  static HomeRecommendation? tryParse(Object? value) {
    if (value is! Map || value['version'] != 'taste-v1') return null;
    final strategy = switch (value['strategy']) {
      'personalized' => RecommendationStrategy.personalized,
      'new-releases' => RecommendationStrategy.newReleases,
      _ => null,
    };
    final daypart = RecommendationDaypart.tryParse(value['daypart']);
    final offset = value['utcOffsetMinutes'];
    if (strategy == null ||
        daypart == null ||
        offset is! int ||
        offset < -720 ||
        offset > 840 ||
        value['experimental'] is! bool) {
      return null;
    }
    return HomeRecommendation(
      strategy: strategy,
      daypart: daypart,
      utcOffsetMinutes: offset,
      experimental: value['experimental'] as bool,
    );
  }
}

enum SongRecommendationCode {
  listeningTime,
  likedGenre,
  listeningHistory,
  following,
  savedGenre,
  newRelease,
}

/// Only known public reason fields are retained; unknown versions stay hidden.
class SongRecommendationReason {
  const SongRecommendationReason({
    required this.code,
    this.genre,
    this.daypart,
  });

  final SongRecommendationCode code;
  final String? genre;
  final RecommendationDaypart? daypart;

  static SongRecommendationReason? tryParse(Object? value) {
    if (value is! Map) return null;
    final code = switch (value['code']) {
      'listening-time' => SongRecommendationCode.listeningTime,
      'liked-genre' => SongRecommendationCode.likedGenre,
      'listening-history' => SongRecommendationCode.listeningHistory,
      'following' => SongRecommendationCode.following,
      'saved-genre' => SongRecommendationCode.savedGenre,
      'new-release' => SongRecommendationCode.newRelease,
      _ => null,
    };
    if (code == null) return null;
    final genre = value['genre'];
    return SongRecommendationReason(
      code: code,
      genre: genre is String && genre.trim().isNotEmpty ? genre.trim() : null,
      daypart: RecommendationDaypart.tryParse(value['daypart']),
    );
  }
}
