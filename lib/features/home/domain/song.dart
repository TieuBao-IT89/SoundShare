import 'music_recommendation.dart';

class Song {
  const Song({
    this.id,
    this.liked = false,
    this.community = false,
    this.saved = false,
    this.username,
    this.uploaderId,
    this.visibility = 'private',
    this.description = '',
    this.validPlays = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.previewDurationMs = 30000,
    this.durationSeconds,
    this.following = false,
    this.uploaderAvatar = '',
    this.resumePositionMs = 0,
    this.recommendationReason,
    required this.title,
    required this.artist,
    required this.artwork,
    required this.duration,
    this.genre = 'Indie',
    this.audioUrl =
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  });

  final String title;
  final String? id;
  final bool liked;
  final bool community, saved;
  final String? username, uploaderId;
  final String visibility, description;
  final int validPlays, likeCount, resumePositionMs;
  final int commentCount, previewDurationMs;
  final double? durationSeconds;
  final bool following;
  final String uploaderAvatar;
  final SongRecommendationReason? recommendationReason;
  String get identity => id ?? '$title|$artist';

  factory Song.fromJson(Map<String, dynamic> data) => Song(
    id: data['id'] as String,
    title: data['title'] as String,
    artist: data['artist'] as String,
    genre: data['genre'] as String,
    artwork: (data['artwork']?['url'] as String?) ?? '',
    duration: '--:--',
    audioUrl: '',
    liked: data['liked'] == true,
    community: data['community'] == true,
    saved: data['saved'] == true,
    username: data['uploader']?['username'] as String?,
    uploaderId: data['uploader']?['id'] as String?,
    visibility: data['visibility'] as String? ?? 'private',
    description: data['description'] as String? ?? '',
    validPlays: (data['validPlayCount'] as num? ?? 0).toInt(),
    likeCount: (data['likeCount'] as num? ?? 0).toInt(),
    commentCount: (data['commentCount'] as num? ?? 0).toInt(),
    previewDurationMs: (data['previewDurationMs'] as num? ?? 30000)
        .toInt()
        .clamp(1, 30000),
    durationSeconds: (data['durationSeconds'] as num?)?.toDouble(),
    following: data['following'] == true,
    uploaderAvatar: data['uploader']?['avatar']?['url'] as String? ?? '',
    resumePositionMs: (data['resumePositionMs'] as num? ?? 0).toInt(),
    recommendationReason: SongRecommendationReason.tryParse(
      data['recommendationReason'],
    ),
  );
  final String artist;
  final String artwork;
  final String duration;
  final String genre;
  final String audioUrl;
}

const sampleSongs = <Song>[
  Song(
    title: 'Slow Motion',
    artist: 'Mila Sol',
    artwork:
        'https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=800',
    duration: '3:42',
    genre: 'Dream pop',
  ),
  Song(
    title: 'Golden Hour',
    artist: 'Juniper Lane',
    artwork:
        'https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?w=800',
    duration: '4:08',
    genre: 'Indie folk',
  ),
  Song(
    title: 'Afterglow',
    artist: 'Theo Rivers',
    artwork:
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
    duration: '3:26',
    genre: 'Alternative',
  ),
  Song(
    title: 'Blue Again',
    artist: 'Nia Bloom',
    artwork:
        'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=800',
    duration: '2:58',
    genre: 'Electronic',
  ),
];
