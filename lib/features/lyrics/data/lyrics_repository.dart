import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../domain/lrc.dart';

class LyricsDocument {
  const LyricsDocument({this.lrc, this.revision = 0, this.canEdit = false});
  final ParsedLrc? lrc;
  final int revision;
  final bool canEdit;
  factory LyricsDocument.fromJson(Map<String, dynamic> json) {
    final raw = json['lrc'] as String?;
    final revision = json['revision'] as int;
    if (revision < 0) throw const FormatException('INVALID_LRC');
    return LyricsDocument(
      lrc: raw == null ? null : parseLrc(raw),
      revision: revision,
      canEdit: json['canEdit'] == true,
    );
  }
}

class LyricsRepository {
  LyricsRepository(this.api);
  final ApiClient api;
  Future<LyricsDocument> read(String id) async => LyricsDocument.fromJson(
    Map<String, dynamic>.from(await api.request('GET', '/songs/$id/lyrics')),
  );
  Future<void> save(String id, String lrc, int revision) => api.request(
    'PUT',
    '/songs/$id/lyrics',
    body: {'lrc': lrc, 'revision': revision},
  );
  Future<void> remove(String id, int revision) =>
      api.request('DELETE', '/songs/$id/lyrics', body: {'revision': revision});
}

final lyricsRepositoryProvider = Provider<LyricsRepository>(
  (ref) => LyricsRepository(ref.watch(apiClientProvider)),
);
final lyricsDocumentProvider = FutureProvider.autoDispose
    .family<LyricsDocument, String?>(
      (ref, id) => id == null
          ? Future.value(const LyricsDocument())
          : ref.watch(lyricsRepositoryProvider).read(id),
    );
