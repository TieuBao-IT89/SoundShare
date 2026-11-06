import 'dart:typed_data';

import '../../../core/services/api_client.dart';
import '../../home/domain/song.dart';

class PublicProfile {
  PublicProfile.fromJson(Map<String, dynamic> data)
    : id = data['id'] as String,
      username = data['username'] as String?,
      displayName = data['displayName'] as String? ?? '',
      bio = data['bio'] as String? ?? '',
      avatar = data['avatar']?['url'] as String? ?? '',
      cover = data['cover']?['url'] as String? ?? '',
      followers = (data['followerCount'] as num? ?? 0).toInt(),
      followingCount = (data['followingCount'] as num? ?? 0).toInt(),
      songs = (data['songCount'] as num? ?? 0).toInt(),
      following = data['following'] == true,
      isSelf = data['isSelf'] == true;
  final String id, displayName, bio, avatar, cover;
  final String? username;
  final int followers, followingCount, songs;
  final bool following, isSelf;
}

class CommunityPage<T> {
  const CommunityPage(this.items, this.nextOffset);
  factory CommunityPage.fromJson(
    dynamic data,
    T Function(Map<String, dynamic>) parse,
  ) => CommunityPage(
    (data['items'] as List)
        .map((value) => parse(Map<String, dynamic>.from(value)))
        .toList(),
    data['nextOffset'] as int?,
  );
  final List<T> items;
  final int? nextOffset;
}

class CommunityRepository {
  CommunityRepository(this.api);
  final ApiClient api;
  Future<({String id, String url})> uploadArtwork(
    String name,
    Uint8List bytes,
  ) async {
    final id = await api.upload('artwork', name, bytes);
    final result = await api.request('GET', '/uploads/$id/access');
    return (id: id, url: result['access']['url'] as String);
  }

  Map<String, String> _page(int offset) => {'limit': '20', 'offset': '$offset'};
  Future<PublicProfile> me() async =>
      PublicProfile.fromJson(await api.request('GET', '/users/me'));
  Future<PublicProfile> profile(String username) async =>
      PublicProfile.fromJson(
        await api.request('GET', '/users/${Uri.encodeComponent(username)}'),
      );
  Future<PublicProfile> updateProfile(Map<String, dynamic> input) async =>
      PublicProfile.fromJson(
        await api.request('PATCH', '/users/me', body: input),
      );
  Future<void> follow(PublicProfile user, bool enabled) async {
    await api.request(enabled ? 'POST' : 'DELETE', '/users/${user.id}/follow');
  }

  Future<Map<String, dynamic>> home() async =>
      Map<String, dynamic>.from(await api.request('GET', '/discover/home'));
  Future<List<String>> genres() async =>
      ((await api.request('GET', '/genres')) as List)
          .map((item) => item['name'] as String)
          .toList();
  Future<CommunityPage<Song>> songs(
    String path, {
    int offset = 0,
    Map<String, String> filters = const {},
  }) async => CommunityPage.fromJson(
    await api.request('GET', path, query: {..._page(offset), ...filters}),
    Song.fromJson,
  );
  Future<CommunityPage<PublicProfile>> creators(
    String mode,
    int offset,
  ) async => CommunityPage.fromJson(
    await api.request(
      'GET',
      '/discover/featured-creators',
      query: {..._page(offset), 'mode': mode},
    ),
    PublicProfile.fromJson,
  );
  Future<CommunityPage<PublicProfile>> connections(
    String id,
    String kind,
    int offset,
  ) async => CommunityPage.fromJson(
    await api.request('GET', '/users/$id/$kind', query: _page(offset)),
    PublicProfile.fromJson,
  );
  Future<Map<String, dynamic>> search(
    String query,
    String type,
    int offset,
  ) async => Map<String, dynamic>.from(
    await api.request(
      'GET',
      '/community/search',
      query: {..._page(offset), 'q': query, 'type': type},
    ),
  );
  Future<void> interact(Song song, String kind, bool enabled) async {
    await api.request(
      enabled ? 'PUT' : 'DELETE',
      '/community/songs/${song.id}/$kind',
    );
  }

  Future<void> patchSong(String id, Map<String, dynamic> patch) async {
    await api.request('PATCH', '/community/songs/$id', body: patch);
  }

  Future<void> deleteSong(String id) async {
    await api.request('DELETE', '/community/songs/$id');
  }

  Future<Map<String, dynamic>> playlists({
    String? username,
    int offset = 0,
  }) async => Map<String, dynamic>.from(
    await api.request(
      'GET',
      username == null
          ? '/community/playlists'
          : '/users/${Uri.encodeComponent(username)}/playlists',
      query: _page(offset),
    ),
  );
  Future<Map<String, dynamic>> playlist(String id, int offset) async =>
      Map<String, dynamic>.from(
        await api.request(
          'GET',
          '/community/playlists/$id',
          query: _page(offset),
        ),
      );
  Future<String> createPlaylist(String title, bool isPublic) async =>
      (await api.request(
            'POST',
            '/community/playlists',
            body: {
              'title': title,
              'visibility': isPublic ? 'public' : 'private',
            },
          ))['id']
          as String;
  Future<void> addToPlaylist(String id, Song song) async {
    await api.request(
      'POST',
      '/community/playlists/$id/tracks',
      body: {'trackId': song.id},
    );
  }

  Future<void> removeFromPlaylist(String id, Song song) async {
    await api.request('DELETE', '/community/playlists/$id/tracks/${song.id}');
  }

  Future<void> deletePlaylist(String id) async {
    await api.request('DELETE', '/community/playlists/$id');
  }

  Future<void> report({
    String? trackId,
    String? profileId,
    required String reason,
    String details = '',
  }) async {
    await api.request(
      'POST',
      '/community/reports',
      body: {
        'trackId': ?trackId,
        'profileId': ?profileId,
        'reason': reason,
        'details': details,
      },
    );
  }
}
