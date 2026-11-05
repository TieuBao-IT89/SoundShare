import '../../../core/services/api_client.dart';
import '../../explore/domain/discovery.dart';
import '../domain/song.dart';
import '../domain/track_draft.dart';
import 'mock_song_repository.dart';

class ApiSongRepository extends SongRepository {
  ApiSongRepository(this.api);
  final ApiClient api;

  Future<List<Song>> _list(Map<String, String> filters) async {
    final songs = <Song>[];
    final seen = <String>{};
    String? cursor;
    do {
      final page = await api.request(
        'GET',
        '/songs',
        query: {...filters, 'limit': '50', 'cursor': ?cursor},
      );
      songs.addAll(
        (page['items'] as List).map(
          (item) => Song.fromJson(Map<String, dynamic>.from(item)),
        ),
      );
      cursor = page['nextCursor'] as String?;
      if (cursor != null && !seen.add(cursor)) {
        throw const ApiException(0, 'INVALID_PAGE');
      }
    } while (cursor != null);
    return songs;
  }

  @override
  Future<List<Song>> featured() => _list({});
  @override
  Future<List<Song>> search(DiscoveryFilters filters) {
    if (filters.collectionId != null &&
        findSampleCollection(filters.collectionId) == null) {
      return Future.value([]);
    }
    return _list({
      if (filters.query.trim().isNotEmpty) 'query': filters.query.trim(),
      if (filters.genre != null) 'genre': filters.genre!,
      if (filters.collectionId != null) 'collection': filters.collectionId!,
    });
  }

  @override
  Future<String> playback(Song song) async =>
      (await api.request('GET', '/songs/${song.id}/playback'))['url'] as String;
  @override
  Future<void> favorite(Song song, bool liked) async {
    await api.request(liked ? 'PUT' : 'DELETE', '/songs/${song.id}/favorite');
  }

  @override
  Future<void> upload(TrackDraft draft) async {
    final audio = await api.upload('audio', draft.audioName, draft.audioBytes);
    final artwork = draft.artworkBytes == null
        ? null
        : await api.upload('artwork', draft.artworkName!, draft.artworkBytes!);
    await api.request(
      'POST',
      '/songs',
      body: {
        'audioAssetId': audio,
        'artworkAssetId': artwork,
        'title': draft.title,
        'artist': draft.artist,
        'genre': draft.genre,
        'description': draft.description,
      },
    );
  }
}
