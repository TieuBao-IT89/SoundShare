import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../data/community_repository.dart';

Future<T> _minuteCache<T>(Ref ref, Future<T> value) {
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return value;
}

final communityRepositoryProvider = Provider(
  (ref) => CommunityRepository(ref.watch(apiClientProvider)),
);
final myPublicProfileProvider = FutureProvider(
  (ref) => ref.watch(communityRepositoryProvider).me(),
);
final publicProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile, String>(
      (ref, username) =>
          ref.watch(communityRepositoryProvider).profile(username),
    );
final communityHomeProvider = FutureProvider(
  (ref) => _minuteCache(ref, ref.watch(communityRepositoryProvider).home()),
);
final communityGenresProvider = FutureProvider(
  (ref) => _minuteCache(ref, ref.watch(communityRepositoryProvider).genres()),
);
final communitySongsProvider = FutureProvider.autoDispose.family(
  (ref, ({String path, int offset, String? period, String? genre}) query) =>
      _minuteCache(
        ref,
        ref
            .watch(communityRepositoryProvider)
            .songs(
              query.path,
              offset: query.offset,
              filters: {
                if (query.period != null) 'period': query.period!,
                if (query.genre != null) 'genre': query.genre!,
              },
            ),
      ),
);
final communityCreatorsProvider = FutureProvider.autoDispose.family(
  (ref, (String, int) query) => _minuteCache(
    ref,
    ref.watch(communityRepositoryProvider).creators(query.$1, query.$2),
  ),
);
final communitySearchProvider = FutureProvider.autoDispose.family(
  (ref, (String, String, int) query) => ref
      .watch(communityRepositoryProvider)
      .search(query.$1, query.$2, query.$3),
);
final connectionsProvider = FutureProvider.autoDispose.family(
  (ref, (String, String, int) query) => ref
      .watch(communityRepositoryProvider)
      .connections(query.$1, query.$2, query.$3),
);
final myPlaylistsProvider = FutureProvider.autoDispose.family(
  (ref, int offset) =>
      ref.watch(communityRepositoryProvider).playlists(offset: offset),
);
final publicPlaylistsProvider = FutureProvider.autoDispose.family(
  (ref, (String, int) query) => ref
      .watch(communityRepositoryProvider)
      .playlists(username: query.$1, offset: query.$2),
);
final playlistDetailProvider = FutureProvider.autoDispose.family(
  (ref, (String, int) query) =>
      ref.watch(communityRepositoryProvider).playlist(query.$1, query.$2),
);
// Search history is session-only, cleared with the account's ProviderContainer.
final recentCommunitySearchesProvider = StateProvider<List<String>>(
  (ref) => [],
);
final communityLikesProvider = StateProvider<Map<String, bool>>((ref) => {});
final communitySavesProvider = StateProvider<Map<String, bool>>((ref) => {});
