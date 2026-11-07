import '../../social/application/social_providers.dart';
import '../../comments/presentation/comments_sheet.dart';
import '../../../core/services/share_link.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../application/community_providers.dart';
import '../data/community_repository.dart';

void communityError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is ApiException ? error.message : context.l10n.v3Unavailable,
        ),
      ),
    );

class CommunityEmpty extends StatelessWidget {
  const CommunityEmpty({super.key});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 16, top: 4),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: context.colors.accentText,
                size: 28,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.v3NoContent,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.v3NoContentDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CommunityAsync<T> extends StatelessWidget {
  const CommunityAsync({
    super.key,
    required this.value,
    required this.data,
    required this.retry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => const SingleChildScrollView(child: LoadingSkeleton(rows: 3)),
    error: (_, _) => SingleChildScrollView(
      child: EmptyState(
        icon: Icons.wifi_off_rounded,
        title: context.l10n.v3Unavailable,
        message: context.l10n.catalogLoadFailedMessage,
        actionLabel: context.l10n.tryAgain,
        onAction: retry,
      ),
    ),
  );
}

class CommunityPager extends StatelessWidget {
  const CommunityPager({
    super.key,
    required this.offset,
    required this.next,
    required this.onPage,
  });
  final int offset;
  final int? next;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    children: [
      if (offset > 0)
        TextButton.icon(
          onPressed: () => onPage((offset - 20).clamp(0, 10000)),
          icon: const Icon(Icons.arrow_back_rounded),
          label: Text(context.l10n.v3PreviousPage),
        ),
      if (next != null)
        TextButton.icon(
          onPressed: () => onPage(next!),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(context.l10n.v3More),
        ),
    ],
  );
}

class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({super.key, required this.profile});
  final PublicProfile profile;
  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    if (widget.profile.isSelf) return const SizedBox.shrink();
    final enabled =
        ref.watch(communityFollowsProvider)[widget.profile.id] ??
        widget.profile.following;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: enabled
            ? context.colors.selected
            : context.colors.action,
        foregroundColor: enabled ? context.colors.mystic : Colors.white,
        side: BorderSide(
          color: enabled ? context.colors.fieldBorder : context.colors.action,
        ),
      ),
      onPressed: busy
          ? null
          : () async {
              setState(() => busy = true);
              try {
                await ref
                    .read(socialActionsProvider)
                    .follow(widget.profile.id, widget.profile.following);
                if (!mounted) return;
                ref.invalidate(publicProfileProvider);
                ref.invalidate(connectionsProvider);
                ref.invalidate(communityHomeProvider);
                ref.invalidate(myPublicProfileProvider);
                ref.invalidate(communityCreatorsProvider);
              } catch (error) {
                if (context.mounted) communityError(context, error);
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
      child: Text(
        busy
            ? context.l10n.v3Working
            : enabled
            ? context.l10n.v3Following
            : context.l10n.v3Follow,
      ),
    );
  }
}

class CreatorRow extends StatelessWidget {
  const CreatorRow({super.key, required this.profile, this.onOpen});
  final PublicProfile profile;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final identity = InkWell(
          onTap: () {
            onOpen?.call();
            context.push('/u/${Uri.encodeComponent(profile.username!)}');
          },
          child: Row(
            children: [
              Artwork(url: profile.avatar, size: 52, radius: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '@${profile.username}',
                      style: TextStyle(color: context.colors.mystic),
                    ),
                    if (profile.bio.isNotEmpty)
                      Text(
                        profile.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final counter in [
                          '${profile.followers} ${context.l10n.v3Followers}',
                          '${profile.songs} ${context.l10n.v3Songs}',
                        ])
                          Text(
                            counter,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        return MediaQuery.textScalerOf(context).scale(14) > 22
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: 8),
                  FollowButton(profile: profile),
                ],
              )
            : Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  FollowButton(profile: profile),
                ],
              );
      },
    ),
  );
}

class CommunitySongRow extends ConsumerStatefulWidget {
  const CommunitySongRow({
    super.key,
    required this.song,
    required this.queue,
    required this.index,
    this.rank,
    this.showStats = false,
    this.onPlay,
  });
  final Song song;
  final List<Song> queue;
  final int index;
  final int? rank;
  final bool showStats;
  final VoidCallback? onPlay;
  @override
  ConsumerState<CommunitySongRow> createState() => _CommunitySongRowState();
}

class _CommunitySongRowState extends ConsumerState<CommunitySongRow> {
  bool busy = false;
  Future<void> _interact(String kind) async {
    final song = widget.song;
    setState(() => busy = true);
    try {
      await ref.read(socialActionsProvider).interact(song, kind);
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song, t = context.l10n;
    final active =
        ref.watch(hasSelectedSongProvider) &&
        ref.watch(currentSongProvider)?.identity == song.identity;
    final liked =
        ref.watch(communityLikesProvider)[song.identity] ?? song.liked;
    final saved =
        ref.watch(communitySavesProvider)[song.identity] ?? song.saved;
    return LayoutBuilder(
      builder: (context, bounds) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: active ? context.colors.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              widget.onPlay?.call();
              ref
                  .read(playbackActionsProvider)
                  .playFrom(widget.queue, widget.index);
              context.push('/player');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  if (widget.rank != null)
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${widget.rank}'.padLeft(2, '0'),
                        style: TextStyle(
                          color: widget.rank! <= 3
                              ? context.colors.mystic
                              : context.colors.secondaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Artwork(url: song.artwork, size: 48, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: active
                                ? context.colors.cyan
                                : context.colors.text,
                          ),
                        ),
                        if (song.username == null)
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.secondaryText,
                            ),
                          )
                        else
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: () => context.push(
                              '/u/${Uri.encodeComponent(song.username!)}',
                            ),
                            child: Text(
                              '${song.artist} \u00b7 @${song.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (widget.showStats)
                          Text(
                            '${song.validPlays} ${t.v3Views} \u00b7 ${song.likeCount} ${t.v3Likes}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.colors.secondaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (bounds.maxWidth >= 600)
                    IconButton(
                      tooltip: liked ? t.unlikeSong : t.likeSong,
                      onPressed: busy ? null : () => _interact('like'),
                      icon: Icon(
                        liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                    ),
                  if (bounds.maxWidth >= 340)
                    IconButton(
                      tooltip: saved ? t.v3RemoveSaved : t.v3SaveTrack,
                      onPressed: busy ? null : () => _interact('save'),
                      icon: Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                    ),
                  SongActionMenu(song: song),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SongActionMenu extends ConsumerStatefulWidget {
  const SongActionMenu({super.key, required this.song});
  final Song song;
  @override
  ConsumerState<SongActionMenu> createState() => _SongActionMenuState();
}

class _SongActionMenuState extends ConsumerState<SongActionMenu> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final song = widget.song, t = context.l10n;
    final liked =
        ref.watch(communityLikesProvider)[song.identity] ?? song.liked;
    final saved =
        ref.watch(communitySavesProvider)[song.identity] ?? song.saved;
    return PopupMenuButton<String>(
      tooltip: t.v3More,
      enabled: !busy,
      onSelected: (value) async {
        if (value == 'comments') {
          await showComments(context, ref, song.id!);
          return;
        }
        if (value == 'share') {
          await shareLink(context, '/shorts/${song.id}');
          return;
        }
        if (value == 'queue') {
          ref.read(playbackActionsProvider).addToQueue(song);
          return;
        }
        if (value == 'playlist') {
          await choosePlaylist(context, ref, song);
          return;
        }
        if (value == 'report') {
          await reportContent(context, ref, trackId: song.id);
          return;
        }
        if (value == 'profile') {
          context.push('/u/${Uri.encodeComponent(song.username!)}');
          return;
        }
        setState(() => busy = true);
        try {
          await ref.read(socialActionsProvider).interact(song, value);
        } catch (error) {
          if (context.mounted) communityError(context, error);
        } finally {
          if (mounted) setState(() => busy = false);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'like',
          child: Text(liked ? t.unlikeSong : t.likeSong),
        ),
        PopupMenuItem(
          value: 'save',
          child: Text(saved ? t.v3RemoveSaved : t.v3SaveTrack),
        ),
        if (song.visibility == 'public')
          PopupMenuItem(value: 'comments', child: Text(t.v9Comments)),
        if (song.visibility == 'public')
          PopupMenuItem(value: 'share', child: Text(t.v9Share)),
        PopupMenuItem(value: 'queue', child: Text(t.v3AddToQueue)),
        PopupMenuItem(value: 'playlist', child: Text(t.v3AddToPlaylist)),
        if (song.username != null)
          PopupMenuItem(value: 'profile', child: Text('@${song.username}')),
        PopupMenuItem(value: 'report', child: Text(t.v3Report)),
      ],
    );
  }
}

Future<void> choosePlaylist(
  BuildContext context,
  WidgetRef ref,
  Song song,
) async {
  try {
    final page = await ref.read(communityRepositoryProvider).playlists();
    if (!context.mounted) return;
    final entries = page['items'] as List;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.v3AddToPlaylist),
        children: [
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(ctx.l10n.v3NoContent),
            ),
          for (final item in entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, item['id'] as String),
              child: Text(item['title'] as String),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'new'),
            child: Text(ctx.l10n.v3CreatePlaylist),
          ),
        ],
      ),
    );
    if (selected == 'new' && context.mounted) {
      context.push('/playlists');
      return;
    }
    if (selected != null) {
      await ref.read(communityRepositoryProvider).addToPlaylist(selected, song);
      ref.invalidate(playlistDetailProvider);
    }
  } catch (error) {
    if (context.mounted) communityError(context, error);
  }
}

Future<void> reportContent(
  BuildContext context,
  WidgetRef ref, {
  String? trackId,
  String? profileId,
}) async {
  final t = context.l10n;
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(t.v3Report),
      children: [
        for (final item in [
          ('copyright', t.v3Copyright),
          ('abuse', t.v3Abuse),
          ('spam', t.v3Spam),
          ('other', t.v3Other),
        ])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, item.$1),
            child: Text(item.$2),
          ),
      ],
    ),
  );
  if (reason == null) return;
  try {
    await ref
        .read(communityRepositoryProvider)
        .report(trackId: trackId, profileId: profileId, reason: reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.v3ReportReceived)));
    }
  } catch (error) {
    if (context.mounted) communityError(context, error);
  }
}
