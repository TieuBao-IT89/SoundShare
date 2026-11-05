import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_song_repository.dart';
import '../domain/song.dart';

final songRepositoryProvider = Provider<SongRepository>(
  (ref) => MockSongRepository(),
);
final catalogProvider = FutureProvider<List<Song>>(
  (ref) => ref.watch(songRepositoryProvider).featured(),
);

// Session-only preferences; these are not a synchronized account library.
final likedSongIndicesProvider = StateProvider<Set<int>>((ref) => {});
