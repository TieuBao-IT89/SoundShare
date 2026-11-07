import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_song_repository.dart';
import '../domain/song.dart';
import '../../../core/config/app_mode.dart';
import '../../../core/services/api_client.dart';
import '../data/api_song_repository.dart';

final songRepositoryProvider = Provider<SongRepository>(
  (ref) => ref.watch(demoModeProvider)
      ? MockSongRepository()
      : ApiSongRepository(ref.watch(apiClientProvider)),
);
final catalogProvider = FutureProvider<List<Song>>((ref) async {
  var disposed = false;
  ref.onDispose(() => disposed = true);
  final songs = await ref.watch(songRepositoryProvider).featured();
  if (!disposed && !ref.read(demoModeProvider)) {
    ref.read(likedSongIndicesProvider.notifier).state = {
      for (var i = 0; i < songs.length; i++)
        if (songs[i].liked) i,
    };
  }
  return songs;
});

// UI projection of saved favorites; demo mode keeps this set only in memory.
final likedSongIndicesProvider = StateProvider<Set<int>>((ref) => {});
