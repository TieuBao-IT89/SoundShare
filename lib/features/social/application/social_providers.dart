import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../community/application/community_providers.dart';
import '../../home/domain/song.dart';
import '../data/social_repository.dart';

final socialRepositoryProvider = Provider(
  (ref) => SocialRepository(ref.watch(apiClientProvider)),
);
final commentCountsProvider = StateProvider<Map<String, int>>((ref) => {});
final communityFollowsProvider = StateProvider<Map<String, bool>>((ref) => {});
final socialBusyProvider = StateProvider<Set<String>>((ref) => {});
final unreadNotificationsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(socialRepositoryProvider).unread(),
);
final notificationPreferencesProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(socialRepositoryProvider).preferences(),
);

/// Shared optimistic state, including rollback; one mutation per resource.
final socialActionsProvider = Provider((ref) {
  final actions = SocialActions(ref);
  ref.onDispose(() => actions.alive = false);
  return actions;
});

class SocialActions {
  SocialActions(this.ref);
  final Ref ref;
  bool alive = true;
  Future<void> interact(Song song, String kind) async {
    final key = '$kind:${song.identity}';
    if (ref.read(socialBusyProvider).contains(key)) return;
    final provider = kind == 'like'
        ? communityLikesProvider
        : communitySavesProvider;
    final before =
        ref.read(provider)[song.identity] ??
        (kind == 'like' ? song.liked : song.saved);
    ref.read(socialBusyProvider.notifier).state = {
      ...ref.read(socialBusyProvider),
      key,
    };
    ref.read(provider.notifier).state = {
      ...ref.read(provider),
      song.identity: !before,
    };
    try {
      await ref.read(communityRepositoryProvider).interact(song, kind, !before);
      if (alive) {
        ref.invalidate(communityHomeProvider);
        ref.invalidate(communitySongsProvider);
      }
    } catch (_) {
      if (alive) {
        ref.read(provider.notifier).state = {
          ...ref.read(provider),
          song.identity: before,
        };
      }
      rethrow;
    } finally {
      if (alive) {
        ref.read(socialBusyProvider.notifier).state = {
          ...ref.read(socialBusyProvider),
        }..remove(key);
      }
    }
  }

  Future<void> follow(String id, bool initial) async {
    final key = 'follow:$id';
    if (ref.read(socialBusyProvider).contains(key)) return;
    final before = ref.read(communityFollowsProvider)[id] ?? initial;
    ref.read(socialBusyProvider.notifier).state = {
      ...ref.read(socialBusyProvider),
      key,
    };
    ref.read(communityFollowsProvider.notifier).state = {
      ...ref.read(communityFollowsProvider),
      id: !before,
    };
    try {
      await ref
          .read(apiClientProvider)
          .request(before ? 'DELETE' : 'POST', '/users/$id/follow');
      if (alive) {
        ref.invalidate(publicProfileProvider);
        ref.invalidate(myPublicProfileProvider);
        ref.invalidate(communityCreatorsProvider);
        ref.invalidate(connectionsProvider);
        ref.invalidate(communityHomeProvider);
      }
    } catch (_) {
      if (alive) {
        ref.read(communityFollowsProvider.notifier).state = {
          ...ref.read(communityFollowsProvider),
          id: before,
        };
      }
      rethrow;
    } finally {
      if (alive) {
        ref.read(socialBusyProvider.notifier).state = {
          ...ref.read(socialBusyProvider),
        }..remove(key);
      }
    }
  }
}
