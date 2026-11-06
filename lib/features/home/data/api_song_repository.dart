import 'dart:typed_data';

import '../../../core/services/api_client.dart';
import '../../explore/domain/discovery.dart';
import '../domain/song.dart';
import '../domain/track_draft.dart';
import 'mock_song_repository.dart';

class ApiSongRepository extends SongRepository {
  ApiSongRepository(this.api);
  final ApiClient api;
  (String, Uint8List, String?, Uint8List?)? _pendingSource;
  String? _audioAssetId;
  String? _artworkAssetId;

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
      (await playbackInfo(song))['url'] as String;
  @override
  Future<Map<String, dynamic>> playbackInfo(Song song) async =>
      Map<String, dynamic>.from(
        await api.request('GET', '/community/songs/${song.id}/playback'),
      );
  @override
  Future<bool> heartbeat(String sessionId, int positionMs, bool playing) async {
    final result = await api.request(
      'POST',
      '/playback-sessions/$sessionId/heartbeat',
      body: {'positionMs': positionMs, 'playing': playing},
    );
    return result['isValid'] == true;
  }

  @override
  Future<void> favorite(Song song, bool liked) async {
    await api.request(
      liked ? 'PUT' : 'DELETE',
      song.community
          ? '/community/songs/${song.id}/like'
          : '/songs/${song.id}/favorite',
    );
  }

  @override
  Future<void> upload(TrackDraft draft) async {
    if (draft.visibility == 'public') {
      final profile = await api.request('GET', '/users/me');
      if (profile['username'] == null) {
        throw const ApiException(400, 'PROFILE_REQUIRED');
      }
    }
    final source = (
      draft.audioName,
      draft.audioBytes,
      draft.artworkName,
      draft.artworkBytes,
    );
    if (_pendingSource != source) {
      _pendingSource = source;
      _audioAssetId = null;
      _artworkAssetId = null;
    }
    // Keep confirmed asset IDs until metadata succeeds. A lost POST response
    // can then be retried through the server's existing idempotency check.
    final audio = _audioAssetId ??= await api.upload(
      'audio',
      draft.audioName,
      draft.audioBytes,
      control: draft.transfer,
    );
    final artwork = draft.artworkBytes == null
        ? null
        : _artworkAssetId ??= await api.upload(
            'artwork',
            draft.artworkName!,
            draft.artworkBytes!,
            control: draft.transfer,
          );
    draft.transfer?.confirming();
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
        'visibility': draft.visibility,
        'rightsConfirmed': draft.rightsConfirmed,
      },
    );
    draft.transfer?.completed();
    _pendingSource = null;
    _audioAssetId = null;
    _artworkAssetId = null;
  }
}
