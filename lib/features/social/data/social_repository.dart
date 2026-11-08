import '../../../core/services/api_client.dart';
import '../../home/domain/song.dart';

typedef SocialJson = Map<String, dynamic>;

class CursorPage<T> {
  CursorPage(this.items, this.next, {this.total});
  factory CursorPage.parse(dynamic data, T Function(SocialJson) parse) =>
      CursorPage(
        (data['items'] as List).map((v) => parse(SocialJson.from(v))).toList(),
        data['nextCursor'] as String?,
        total: (data['total'] as num?)?.toInt(),
      );
  final List<T> items;
  final String? next;
  final int? total;
}

class SocialRepository {
  SocialRepository(this.api);
  final ApiClient api;
  Future<SocialJson> commentContext(String id) async =>
      SocialJson.from(await api.request('GET', '/community/comments/$id'));
  Future<CursorPage<Song>> feed(String mode, String? cursor) async =>
      CursorPage.parse(
        await api.request(
          'GET',
          '/shorts/feed',
          query: {'mode': mode, 'limit': '10', 'cursor': ?cursor},
        ),
        Song.fromJson,
      );
  Future<Song> song(String id) async => Song.fromJson(
    SocialJson.from(await api.request('GET', '/shorts/songs/$id')),
  );
  Future<CursorPage<SocialJson>> comments(
    String id,
    String? cursor, {
    String? parent,
  }) async => CursorPage.parse(
    await api.request(
      'GET',
      '/community/songs/$id/comments',
      query: {'limit': '15', 'cursor': ?cursor, 'parentId': ?parent},
    ),
    (v) => v,
  );
  Future<void> comment(String id, String content, {String? parent}) async {
    await api.request(
      'POST',
      parent == null
          ? '/community/songs/$id/comments'
          : '/community/comments/$parent/replies',
      body: {'content': content},
    );
  }

  Future<void> deleteComment(String id) async {
    await api.request('DELETE', '/community/comments/$id');
  }

  Future<void> likeComment(String id, bool enabled) async {
    await api.request(
      enabled ? 'PUT' : 'DELETE',
      '/community/comments/$id/like',
    );
  }

  Future<void> reportComment(String id, String reason) async {
    await api.request(
      'POST',
      '/community/comments/$id/report',
      body: {'reason': reason},
    );
  }

  Future<CursorPage<SocialJson>> inbox(bool unread, String? cursor) async =>
      CursorPage.parse(
        await api.request(
          'GET',
          '/notifications',
          query: {'limit': '20', 'unread': '$unread', 'cursor': ?cursor},
        ),
        (v) => v,
      );
  Future<int> unread() async =>
      (await api.request('GET', '/notifications/unread-count'))['count'] as int;
  Future<void> read({String? id}) async {
    await api.request(
      'PATCH',
      id == null ? '/notifications/read-all' : '/notifications/$id/read',
    );
  }

  Future<SocialJson> preferences([SocialJson? input]) async => SocialJson.from(
    await api.request(
      input == null ? 'GET' : 'PATCH',
      '/notifications/preferences',
      body: input,
    ),
  );
}
