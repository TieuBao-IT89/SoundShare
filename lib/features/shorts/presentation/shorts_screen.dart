import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/share_link.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/artwork_glow.dart';
import '../../../core/widgets/visible_playback_position.dart';
import '../../../l10n/l10n.dart';
import '../../comments/presentation/comments_sheet.dart';
import '../../community/application/community_providers.dart';
import '../../community/presentation/community_widgets.dart';
import '../../home/domain/song.dart';
import '../../social/application/social_providers.dart';

class ShortsScreen extends ConsumerStatefulWidget {
  const ShortsScreen({
    super.key,
    this.songId,
    this.openComments = false,
    this.commentId,
  });
  final String? songId;
  final bool openComments;
  final String? commentId;
  @override
  ConsumerState<ShortsScreen> createState() => _ShortsScreenState();
}

class _ShortsScreenState extends ConsumerState<ShortsScreen>
    with WidgetsBindingObserver {
  final pages = PageController();
  final songs = <Song>[];
  late PlaybackActions actions;
  PreviewContext? lease;
  String mode = 'for-you';
  String? cursor;
  int current = 0, generation = 0;
  bool loading = false,
      started = false,
      autoplay = false,
      autoNext = false,
      foreground = true,
      visible = true,
      seedLoaded = false;
  Object? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      actions = ref.read(playbackActionsProvider);
      lease = actions.beginPreview()..onEnd = onPreviewEnd;
      load(reset: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (visible && !next) {
      final activeLease = lease;
      if (activeLease?.active == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && activeLease!.active) unawaited(actions.pause());
        });
      }
    }
    visible = next;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground && lease?.active == true) unawaited(actions.pause());
  }

  @override
  void dispose() {
    generation++;
    WidgetsBinding.instance.removeObserver(this);
    pages.dispose();
    final context = lease;
    if (context != null) unawaited(actions.restorePreview(context));
    super.dispose();
  }

  Future<void> load({bool reset = false}) async {
    if (loading && !reset) return;
    final request = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    if (reset) {
      if (lease?.active == true) await actions.pause();
      if (!mounted || request != generation) return;
      setState(() {
        songs.clear();
        current = 0;
        cursor = null;
        started = false;
      });
    }
    try {
      final repository = ref.read(socialRepositoryProvider);
      if (reset && widget.songId != null && !seedLoaded) {
        final song = await repository.song(widget.songId!);
        if (!mounted || request != generation) return;
        setState(() {
          songs.add(song);
          seedLoaded = true;
        });
        if (widget.openComments) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showComments(context, ref, song.id!, commentId: widget.commentId);
            }
          });
        }
      } else {
        final page = await repository.feed(mode, cursor);
        if (!mounted || request != generation) return;
        final known = songs.map((v) => v.identity).toSet();
        setState(() {
          songs.addAll(page.items.where((v) => known.add(v.identity)));
          cursor = page.next;
          // Keep at most 50 DTOs and only build the visible page and neighbors.
          if (songs.length > 40 && current >= 20) {
            songs.removeRange(0, 20);
            current -= 20;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && pages.hasClients) pages.jumpToPage(current);
            });
          }
        });
      }
      if (reset && pages.hasClients) pages.jumpToPage(0);
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  Future<void> change(int index) async {
    if (index == current || index >= songs.length) return;
    final player = ref.read(audioPlayerProvider);
    final continuePlaying =
        lease?.active == true &&
        started &&
        autoplay &&
        player.playing &&
        foreground &&
        visible;
    setState(() => current = index);
    if (lease?.active == true) await actions.pause();
    if (!mounted || current != index) return;
    if (continuePlaying && lease?.active == true) {
      await actions.preview(lease!, songs[index]);
    }
    if (cursor != null && index >= songs.length - 3) unawaited(load());
  }

  void onPreviewEnd() {
    if (!mounted ||
        !autoNext ||
        !visible ||
        !foreground ||
        current + 1 >= songs.length) {
      return;
    }
    final next = current + 1;
    pages.jumpToPage(next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          visible &&
          foreground &&
          current == next &&
          lease?.active == true) {
        unawaited(actions.preview(lease!, songs[next]));
      }
    });
  }

  Future<void> toggle(Song song) async {
    if (lease?.active != true) {
      lease = actions.beginPreview()..onEnd = onPreviewEnd;
    }
    final player = ref.read(audioPlayerProvider);
    if (ref.read(currentSongProvider)?.identity == song.identity &&
        lease?.song?.identity == song.identity &&
        player.playing) {
      await actions.pause();
      return;
    }
    setState(() => started = true);
    if (ref.read(currentSongProvider)?.identity == song.identity &&
        lease?.song?.identity == song.identity &&
        player.position > Duration.zero &&
        player.position <
            Duration(milliseconds: lease?.limitMs ?? song.previewDurationMs)) {
      await actions.togglePlayback();
    } else {
      await actions.preview(lease!, song);
    }
  }

  Future<void> mutate(Song song, String kind) async {
    try {
      await ref.read(socialActionsProvider).interact(song, kind);
    } catch (e) {
      if (mounted) communityError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    ref.listen(socialBusyProvider, (before, after) {
      if (mode != 'following' || before == null) return;
      final settled = before.difference(after);
      if (songs.any(
        (song) =>
            settled.contains('follow:${song.uploaderId}') &&
            ref.read(communityFollowsProvider)[song.uploaderId] == false,
      )) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && mode == 'following') unawaited(load(reset: true));
        });
      }
    });
    final player = ref.watch(audioPlayerProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                Row(
                  children: [
                    BackButton(
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/'),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final entry in {
                              'for-you': t.v9ForYou,
                              'following': t.v9Following,
                              'trending': t.v9Trending,
                            }.entries)
                              TextButton(
                                onPressed: () {
                                  if (mode == entry.key) return;
                                  setState(() => mode = entry.key);
                                  load(reset: true);
                                },
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontWeight: mode == entry.key
                                        ? FontWeight.w800
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: t.search,
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                Expanded(
                  child: songs.isEmpty
                      ? Center(
                          child: loading
                              ? const CircularProgressIndicator()
                              : Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        error != null
                                            ? error is ApiException
                                                  ? (error as ApiException)
                                                        .message
                                                  : t.v3Unavailable
                                            : mode == 'following'
                                            ? t.v9EmptyFollowing
                                            : t.v3NoContent,
                                      ),
                                      TextButton(
                                        onPressed: () => load(reset: true),
                                        child: Text(
                                          error != null
                                              ? t.tryAgain
                                              : t.v9RefreshFeed,
                                        ),
                                      ),
                                      if (mode == 'following')
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/explore'),
                                          child: Text(t.explore),
                                        ),
                                    ],
                                  ),
                                ),
                        )
                      : Stack(
                          children: [
                            PageView.builder(
                              controller: pages,
                              scrollDirection: Axis.vertical,
                              itemCount: songs.length,
                              onPageChanged: change,
                              itemBuilder: (context, index) {
                                final song = songs[index];
                                final liked =
                                    ref.watch(
                                      communityLikesProvider,
                                    )[song.identity] ??
                                    song.liked;
                                final saved =
                                    ref.watch(
                                      communitySavesProvider,
                                    )[song.identity] ??
                                    song.saved;
                                final following =
                                    ref.watch(
                                      communityFollowsProvider,
                                    )[song.uploaderId] ??
                                    song.following;
                                final selected =
                                    index == current &&
                                    lease?.active == true &&
                                    lease?.song?.identity == song.identity &&
                                    ref.watch(currentSongProvider)?.identity ==
                                        song.identity;
                                return TickerMode(
                                  enabled:
                                      index == current && visible && foreground,
                                  child: ArtworkGlow(
                                    image: song.artwork.isEmpty
                                        ? null
                                        : artworkImageProvider(song.artwork),
                                    ambientBackground: true,
                                    child: LayoutBuilder(
                                      builder: (context, bounds) => SingleChildScrollView(
                                        physics:
                                            bounds.maxHeight >= 550 &&
                                                MediaQuery.textScalerOf(context)
                                                        .scale(1) <=
                                                    1.3
                                            ? const NeverScrollableScrollPhysics()
                                            : null,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: bounds.maxHeight,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              12,
                                              16,
                                              16,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        onDoubleTap: liked
                                                            ? null
                                                            : () => mutate(
                                                                song,
                                                                'like',
                                                              ),
                                                        child: LayoutBuilder(
                                                          builder: (context, b) => Artwork(
                                                            url: song.artwork,
                                                            size: math
                                                                .min(
                                                                  b.maxWidth,
                                                                  bounds.maxHeight *
                                                                      (bounds.maxHeight >=
                                                                              650
                                                                          ? .48
                                                                          : .30),
                                                                )
                                                                .clamp(80, 430)
                                                                .toDouble(),
                                                            radius: 24,
                                                            semanticLabel:
                                                                song.title,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Column(
                                                      children: [
                                                        IconButton(
                                                          tooltip: liked
                                                              ? t.unlikeSong
                                                              : t.likeSong,
                                                          onPressed: () =>
                                                              mutate(
                                                                song,
                                                                'like',
                                                              ),
                                                          icon: Icon(
                                                            liked
                                                                ? Icons.favorite
                                                                : Icons
                                                                      .favorite_border,
                                                            color: liked
                                                                ? context
                                                                      .colors
                                                                      .action
                                                                : null,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${(song.likeCount + (liked ? 1 : 0) - (song.liked ? 1 : 0)).clamp(0, 1 << 30)}',
                                                        ),
                                                        IconButton(
                                                          tooltip: t.v9Comments,
                                                          onPressed: () =>
                                                              showComments(
                                                                context,
                                                                ref,
                                                                song.id!,
                                                              ),
                                                          icon: const Icon(
                                                            Icons
                                                                .chat_bubble_outline,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${ref.watch(commentCountsProvider)[song.id] ?? song.commentCount}',
                                                        ),
                                                        IconButton(
                                                          tooltip:
                                                              t.v3SaveTrack,
                                                          onPressed: () =>
                                                              mutate(
                                                                song,
                                                                'save',
                                                              ),
                                                          icon: Icon(
                                                            saved
                                                                ? Icons.bookmark
                                                                : Icons
                                                                      .bookmark_border,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          tooltip: t.v9Share,
                                                          onPressed: () =>
                                                              shareLink(
                                                                context,
                                                                '/shorts/${song.id}',
                                                              ),
                                                          icon: const Icon(
                                                            Icons.ios_share,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  song.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineSmall,
                                                ),
                                                Text(
                                                  song.artist,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Row(
                                                  children: [
                                                    InkWell(
                                                      onTap: () async {
                                                        await actions.pause();
                                                        if (context.mounted) {
                                                          context.push(
                                                            '/u/${Uri.encodeComponent(song.username!)}',
                                                          );
                                                        }
                                                      },
                                                      child: Artwork(
                                                        url:
                                                            song.uploaderAvatar,
                                                        size: 32,
                                                        radius: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: TextButton(
                                                        onPressed: () {
                                                          actions.pause();
                                                          context.push(
                                                            '/u/${Uri.encodeComponent(song.username!)}',
                                                          );
                                                        },
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Text(
                                                            '@${song.username}',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (song.uploaderId !=
                                                        ref
                                                            .watch(
                                                              myPublicProfileProvider,
                                                            )
                                                            .valueOrNull
                                                            ?.id)
                                                      TextButton(
                                                        onPressed: () async {
                                                          try {
                                                            await ref
                                                                .read(
                                                                  socialActionsProvider,
                                                                )
                                                                .follow(
                                                                  song.uploaderId!,
                                                                  song.following,
                                                                );
                                                          } catch (e) {
                                                            if (context
                                                                .mounted) {
                                                              communityError(
                                                                context,
                                                                e,
                                                              );
                                                            }
                                                          }
                                                        },
                                                        child: Text(
                                                          following
                                                              ? t.v3Following
                                                              : t.v3Follow,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  song.genre,
                                                  style: TextStyle(
                                                    color: context
                                                        .colors
                                                        .accentText,
                                                  ),
                                                ),
                                                if (song.description.isNotEmpty)
                                                  Text(
                                                    song.description,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                if (!started)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    child: Text(
                                                      t.v9PreviewHint,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    ),
                                                  ),
                                                if (selected)
                                                  VisiblePlaybackPosition(
                                                    player: player,
                                                    builder: (context, position) {
                                                      final previewMs =
                                                          lease?.limitMs ??
                                                          song.previewDurationMs;
                                                      final value =
                                                          (position.inMilliseconds /
                                                                  previewMs)
                                                              .clamp(0.0, 1.0);
                                                      return Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          LinearProgressIndicator(
                                                            value: value,
                                                          ),
                                                          Text(
                                                            '${position.inSeconds.clamp(0, previewMs ~/ 1000)} / ${previewMs ~/ 1000}s',
                                                            style:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .labelSmall,
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  )
                                                else
                                                  const LinearProgressIndicator(
                                                    value: 0,
                                                  ),
                                                Wrap(
                                                  spacing: 10,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    StreamBuilder(
                                                      stream: player
                                                          .playerStateStream,
                                                      builder: (context, _) =>
                                                          FilledButton.tonalIcon(
                                                            onPressed: () =>
                                                                toggle(song),
                                                            icon: Icon(
                                                              selected &&
                                                                      player
                                                                          .playing
                                                                  ? Icons.pause
                                                                  : Icons
                                                                        .play_arrow,
                                                            ),
                                                            label: Text(
                                                              t.v9Preview,
                                                            ),
                                                          ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () async {
                                                        await actions.playFrom([
                                                          song,
                                                        ], 0);
                                                        if (context.mounted) {
                                                          context.push(
                                                            '/player',
                                                          );
                                                        }
                                                      },
                                                      child: Text(
                                                        t.v9FullTrack,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip:
                                                          t.v3AddToPlaylist,
                                                      onPressed: () =>
                                                          choosePlaylist(
                                                            context,
                                                            ref,
                                                            song,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.playlist_add,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (index == songs.length - 1)
                                                  TextButton(
                                                    onPressed: loading
                                                        ? null
                                                        : () => cursor == null
                                                              ? load(
                                                                  reset: true,
                                                                )
                                                              : load(),
                                                    child: Text(
                                                      loading
                                                          ? t.v3Working
                                                          : cursor == null
                                                          ? t.v9RefreshFeed
                                                          : t.v3More,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (error != null)
                              Align(
                                alignment: Alignment.topCenter,
                                child: TextButton(
                                  onPressed: () => load(reset: true),
                                  child: Text(t.tryAgain),
                                ),
                              ),
                          ],
                        ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: t.v3PreviousPage,
                      onPressed: current > 0
                          ? () => pages.previousPage(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            )
                          : null,
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    Expanded(
                      child: Text(
                        t.v9PreviewSeconds,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: t.v3More,
                      onPressed: current + 1 < songs.length
                          ? () => pages.nextPage(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            )
                          : cursor != null && !loading
                          ? () => load()
                          : null,
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                    PopupMenuButton<int>(
                      tooltip: t.v3More,
                      icon: const Icon(Icons.tune),
                      onSelected: (value) => setState(() {
                        if (value == 0) {
                          autoplay = !autoplay;
                        } else {
                          autoNext = !autoNext;
                        }
                      }),
                      itemBuilder: (_) => [
                        CheckedPopupMenuItem(
                          value: 0,
                          checked: autoplay,
                          child: Text(t.v9Autoplay),
                        ),
                        CheckedPopupMenuItem(
                          value: 1,
                          checked: autoNext,
                          child: Text(t.v9AutoNext),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
