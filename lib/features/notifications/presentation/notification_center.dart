import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_mode.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../../community/presentation/community_widgets.dart';
import '../../social/application/social_providers.dart';
import '../../social/data/social_repository.dart';
import '../../social/presentation/social_load_error.dart';

/// Poll only while visible and foreground. Sequential requests, bounded backoff,
/// no JWT in URLs, no listeners surviving the account's ProviderContainer.
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});
  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with WidgetsBindingObserver {
  Timer? timer;
  bool active = true, visible = false;
  int generation = 0, failures = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    active =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (next != visible) {
      visible = next;
      sync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    sync();
  }

  void sync() {
    timer?.cancel();
    generation++;
    if (active && visible && !ref.read(demoModeProvider)) {
      final ticket = generation;
      timer = Timer(const Duration(seconds: 30), () => poll(ticket));
    }
  }

  Future<void> poll(int ticket) async {
    try {
      final count = await ref.refresh(unreadNotificationsProvider.future);
      if (count < 0) throw StateError('Invalid unread count');
      failures = 0;
    } catch (_) {
      failures = (failures + 1).clamp(0, 4);
    }
    if (!mounted || ticket != generation || !active || !visible) return;
    timer = Timer(
      Duration(seconds: (30 * (1 << failures)).clamp(30, 300)),
      () => poll(ticket),
    );
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(demoModeProvider)) return const SizedBox.shrink();
    final unread = ref.watch(unreadNotificationsProvider);
    final count = unread.valueOrNull ?? 0;
    return IconButton(
      tooltip: unread.hasError
          ? '${context.l10n.v9Notifications}: ${context.l10n.v3Unavailable}'
          : context.l10n.v9Notifications,
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: count > 0 || unread.hasError,
        label: Text(
          unread.hasError
              ? '!'
              : count > 99
              ? '99+'
              : '$count',
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class NotificationCenter extends ConsumerStatefulWidget {
  const NotificationCenter({super.key});
  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter>
    with WidgetsBindingObserver {
  CursorPage<SocialJson>? page;
  String? cursor;
  final previous = <String?>[];
  bool unread = false, loading = true, busy = false;
  Object? error;
  int generation = 0;
  Timer? refreshTimer;
  bool foreground = true, visible = false;
  int refreshFailures = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (next != visible) {
      visible = next;
      scheduleRefresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    scheduleRefresh();
  }

  void scheduleRefresh() {
    refreshTimer?.cancel();
    if (!foreground || !visible) return;
    refreshTimer = Timer(
      Duration(seconds: (30 * (1 << refreshFailures)).clamp(30, 300)),
      () async {
        if (mounted &&
            foreground &&
            visible &&
            cursor == null &&
            !loading &&
            !busy) {
          await load(quiet: true);
        }
        if (mounted) scheduleRefresh();
      },
    );
  }

  @override
  void dispose() {
    generation++;
    refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load({bool quiet = false}) async {
    final request = ++generation;
    setState(() {
      if (!quiet || page == null) loading = true;
      error = null;
    });
    try {
      final result = await ref
          .read(socialRepositoryProvider)
          .inbox(unread, cursor);
      if (mounted && request == generation) setState(() => page = result);
      refreshFailures = 0;
    } catch (e) {
      refreshFailures = (refreshFailures + 1).clamp(0, 4);
      if (mounted && request == generation && (!quiet || page == null)) {
        setState(() => error = e);
      }
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  Future<void> open(SocialJson n) async {
    try {
      await ref.read(socialRepositoryProvider).read(id: n['id']);
      if (!mounted) return;
      ref.invalidate(unreadNotificationsProvider);
      if (n['trackId'] != null) {
        await context.push(
          '/shorts/${n['trackId']}${n['commentId'] != null ? '?comments=1&comment=${n['commentId']}' : ''}',
        );
      } else if (n['actor']['username'] != null) {
        await context.push('/u/${Uri.encodeComponent(n['actor']['username'])}');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.v9Unavailable)));
        }
      }
      if (mounted) await load();
    } catch (e) {
      if (mounted) communityError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    String action(String type) => switch (type) {
      'follower' => t.v9NewFollower,
      'comment' => t.v9NewComment,
      'reply' => t.v9NewReply,
      'song_like' => t.v9SongLike,
      'new_track' => t.v9NewTrack,
      _ => t.v9CommentLike,
    };
    return AppScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                BackButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
                Expanded(
                  child: Text(
                    t.v9Notifications,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: t.v9Preferences,
                  onPressed: () => context.push('/notifications/preferences'),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: Text(t.v9All),
                selected: !unread,
                onSelected: (_) {
                  setState(() {
                    unread = false;
                    cursor = null;
                    previous.clear();
                  });
                  load();
                },
              ),
              ChoiceChip(
                label: Text(t.v9Unread),
                selected: unread,
                onSelected: (_) {
                  setState(() {
                    unread = true;
                    cursor = null;
                    previous.clear();
                  });
                  load();
                },
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await ref.read(socialRepositoryProvider).read();
                          if (mounted) {
                            ref.invalidate(unreadNotificationsProvider);
                            await load();
                          }
                        } catch (e) {
                          if (context.mounted) communityError(context, e);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: Text(t.v9ReadAll),
              ),
            ],
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? SocialLoadError(error: error!, retry: load)
                : RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      children: [
                        if (page?.items.isEmpty ?? true)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(t.v9NoNotifications),
                          ),
                        for (final n in page?.items ?? <SocialJson>[])
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            onTap: () => open(n),
                            leading: Artwork(
                              url: n['actor']['avatar']?['url'] ?? '',
                              size: 44,
                              radius: 24,
                            ),
                            title: Text(
                              '${n['actor']['displayName']} ${action(n['type'])}',
                              style: TextStyle(
                                fontWeight: n['read'] == true
                                    ? FontWeight.normal
                                    : FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${n['title'] ?? '@${n['actor']['username']}'} · ${MaterialLocalizations.of(context).formatShortDate(DateTime.parse(n['createdAt']).toLocal())}',
                            ),
                            trailing: n['read'] == true
                                ? null
                                : const Icon(Icons.circle, size: 8),
                          ),
                        Wrap(
                          spacing: 16,
                          children: [
                            if (previous.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(
                                    () => cursor = previous.removeLast(),
                                  );
                                  load();
                                },
                                child: Text(t.v3PreviousPage),
                              ),
                            if (page?.next != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    previous.add(cursor);
                                    cursor = page!.next;
                                  });
                                  load();
                                },
                                child: Text(t.v3More),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppScaffold(
      child: Column(
        children: [
          AppBar(title: Text(t.v9Preferences)),
          Expanded(
            child: CommunityAsync(
              value: ref.watch(notificationPreferencesProvider),
              retry: () => ref.invalidate(notificationPreferencesProvider),
              data: (data) => ListView(
                children: [
                  for (final entry in {
                    'followers': t.v9FollowersPreference,
                    'comments': t.v9CommentsPreference,
                    'replies': t.v9RepliesPreference,
                    'likes': t.v9LikesPreference,
                    'newTracks': t.v9TracksPreference,
                  }.entries)
                    SwitchListTile(
                      title: Text(entry.value),
                      value: data[entry.key] == true,
                      onChanged: busy
                          ? null
                          : (value) async {
                              setState(() => busy = true);
                              try {
                                await ref
                                    .read(socialRepositoryProvider)
                                    .preferences({entry.key: value});
                                if (mounted) {
                                  ref.invalidate(
                                    notificationPreferencesProvider,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) communityError(context, e);
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
