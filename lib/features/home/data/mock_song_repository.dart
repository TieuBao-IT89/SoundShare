import '../domain/song.dart';
import '../../explore/domain/discovery.dart';
import '../domain/track_draft.dart';

abstract class SongRepository {
  Future<List<Song>> featured();
  Future<List<Song>> search(DiscoveryFilters filters) async {
    final songs = await featured();
    return [
      for (final index in matchingSongIndices(songs, filters)) songs[index],
    ];
  }

  Future<String> playback(Song song) async => song.audioUrl;
  Future<Map<String, dynamic>> playbackInfo(Song song) async => {
    'url': await playback(song),
  };
  Future<bool> heartbeat(
    String sessionId,
    int positionMs,
    bool playing,
  ) async => false;
  Future<void> favorite(Song song, bool liked) async {}
  Future<void> upload(TrackDraft draft) async =>
      throw UnsupportedError('Upload is unavailable in demo mode.');
}

class MockSongRepository extends SongRepository {
  @override
  Future<List<Song>> featured() async => sampleSongs;
}
