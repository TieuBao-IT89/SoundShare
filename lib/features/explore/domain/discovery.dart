import '../../home/domain/song.dart';

class DiscoveryFilters {
  const DiscoveryFilters({this.query = '', this.genre, this.collectionId});

  factory DiscoveryFilters.fromUri(Uri uri) => DiscoveryFilters(
    query: uri.queryParameters['q'] ?? '',
    genre: _nonEmpty(uri.queryParameters['genre']),
    collectionId: _nonEmpty(uri.queryParameters['collection']),
  );

  final String query;
  final String? genre;
  final String? collectionId;
  @override
  bool operator ==(Object other) =>
      other is DiscoveryFilters &&
      other.query == query &&
      other.genre == genre &&
      other.collectionId == collectionId;
  @override
  int get hashCode => Object.hash(query, genre, collectionId);

  bool get isActive =>
      query.isNotEmpty || genre != null || collectionId != null;

  String get location {
    final parameters = {
      if (query.isNotEmpty) 'q': query,
      'genre': ?genre,
      'collection': ?collectionId,
    };
    return Uri(
      path: '/explore',
      queryParameters: parameters.isEmpty ? null : parameters,
    ).toString();
  }

  DiscoveryFilters withQuery(String value) =>
      DiscoveryFilters(query: value, genre: genre, collectionId: collectionId);
  DiscoveryFilters withGenre(String? value) =>
      DiscoveryFilters(query: query, genre: value, collectionId: collectionId);
  DiscoveryFilters withCollection(String? value) =>
      DiscoveryFilters(query: query, genre: genre, collectionId: value);

  static String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();
}

class SampleCollection {
  const SampleCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.genres,
  });
  final String id;
  final String title;
  final String description;
  final List<String> genres;

  bool contains(Song song) =>
      genres.any((genre) => _normalize(genre) == _normalize(song.genre));
}

const sampleCollections = [
  SampleCollection(
    id: 'soft-focus',
    title: 'Softer corners',
    description: 'Dream pop and indie folk for a gentler pace.',
    genres: ['Dream pop', 'Indie folk'],
  ),
  SampleCollection(
    id: 'after-hours',
    title: 'After hours',
    description: 'Alternative and electronic sounds for late listening.',
    genres: ['Alternative', 'Electronic'],
  ),
];

SampleCollection? findSampleCollection(String? id) {
  for (final collection in sampleCollections) {
    if (collection.id == id) return collection;
  }
  return null;
}

List<String> catalogGenres(List<Song> songs) {
  final genres = <String, String>{};
  for (final song in songs) {
    final genre = song.genre.trim();
    if (genre.isNotEmpty) genres.putIfAbsent(_normalize(genre), () => genre);
  }
  return genres.values.toList()
    ..sort((a, b) => _normalize(a).compareTo(_normalize(b)));
}

// Keep indices in the original catalog so a filtered result opens the right song.
List<int> matchingSongIndices(List<Song> songs, DiscoveryFilters filters) {
  final collection = findSampleCollection(filters.collectionId);
  if (filters.collectionId != null && collection == null) return [];
  final query = _normalize(filters.query);
  return [
    for (var i = 0; i < songs.length; i++)
      if ((filters.genre == null ||
              _normalize(songs[i].genre) == _normalize(filters.genre!)) &&
          (collection == null || collection.contains(songs[i])) &&
          _normalize('${songs[i].title} ${songs[i].artist} ${songs[i].genre}')
              .contains(query))
        i,
  ];
}

String _normalize(String value) => value.trim().toLowerCase();
