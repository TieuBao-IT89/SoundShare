import '../domain/song.dart';

abstract interface class SongRepository {
  Future<List<Song>> featured();
}

class MockSongRepository implements SongRepository {
  @override
  Future<List<Song>> featured() async => sampleSongs;
}
