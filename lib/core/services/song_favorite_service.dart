import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/community/application/community_providers.dart';
import '../../features/home/application/catalog_provider.dart';
import '../../features/home/domain/song.dart';

final favoriteBusyProvider = StateProvider<Set<String>>((ref) => {});
final _favoriteOverridesProvider = StateProvider<Map<String, bool>>(
  (ref) => {},
);

final songLikedProvider = Provider.family<bool, Song>((ref, song) {
  if (song.community) {
    return ref.watch(communityLikesProvider)[song.identity] ?? song.liked;
  }
  final override = ref.watch(_favoriteOverridesProvider)[song.identity];
  if (override != null) return override;
  final catalog = ref.watch(catalogProvider).valueOrNull ?? [];
  final index = catalog.indexWhere((item) => item.identity == song.identity);
  return index < 0
      ? song.liked
      : ref.watch(likedSongIndicesProvider).contains(index);
});

final songFavoriteActionsProvider = Provider((ref) {
  final actions = SongFavoriteActions(ref);
  ref.onDispose(() => actions._disposed = true);
  return actions;
});

/// One mutation path for the button and record gesture. Busy is keyed by song
/// identity, so a late response cannot favorite the next track by queue index.
class SongFavoriteActions {
  SongFavoriteActions(this.ref);
  final Ref ref;
  bool _disposed = false;

  Future<bool?> toggle(Song song) async {
    if (ref.read(favoriteBusyProvider).contains(song.identity)) return null;
    final next = !ref.read(songLikedProvider(song));
    ref.read(favoriteBusyProvider.notifier).state = {
      ...ref.read(favoriteBusyProvider),
      song.identity,
    };
    try {
      await ref.read(songRepositoryProvider).favorite(song, next);
      if (_disposed) return null;
      if (song.community) {
        ref.read(communityLikesProvider.notifier).state = {
          ...ref.read(communityLikesProvider),
          song.identity: next,
        };
        ref.invalidate(catalogProvider);
        ref.invalidate(communityHomeProvider);
        ref.invalidate(communitySongsProvider);
      } else {
        ref.read(_favoriteOverridesProvider.notifier).state = {
          ...ref.read(_favoriteOverridesProvider),
          song.identity: next,
        };
        final songs = ref.read(catalogProvider).valueOrNull ?? [];
        final index = songs.indexWhere(
          (item) => item.identity == song.identity,
        );
        if (index >= 0) {
          final likes = {...ref.read(likedSongIndicesProvider)};
          next ? likes.add(index) : likes.remove(index);
          ref.read(likedSongIndicesProvider.notifier).state = likes;
        }
      }
      return next;
    } finally {
      if (!_disposed) {
        ref.read(favoriteBusyProvider.notifier).state = {
          ...ref.read(favoriteBusyProvider),
        }..remove(song.identity);
      }
    }
  }
}
