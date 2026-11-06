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
import '../../home/application/catalog_provider.dart';
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
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.graphic_eq_rounded,
    title: context.l10n.v3NoContent,
    message: context.l10n.v3NoContentDescription,
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
  bool? following;
  @override
  void didUpdateWidget(covariant FollowButton old) {
    super.didUpdateWidget(old);
    if (old.profile.id != widget.profile.id ||
        old.profile.following != widget.profile.following) {
      following = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profile.isSelf) return const SizedBox.shrink();
    final enabled = following ?? widget.profile.following;
    return OutlinedButton(
      onPressed: busy
          ? null
          : () async {
              setState(() => busy = true);
              try {
                await ref
                    .read(communityRepositoryProvider)
                    .follow(widget.profile, !enabled);
                if (!mounted) return;
                setState(() => following = !enabled);
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
                      style: const TextStyle(color: AppColors.mystic),
                    ),
                    if (profile.bio.isNotEmpty)
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      '${context.l10n.v3Followers}: ${profile.followers} · ${context.l10n.v3Songs}: ${profile.songs}',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        return bounds.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
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
    final provider = kind == 'like'
        ? communityLikesProvider
        : communitySavesProvider;
    final enabled =
        ref.read(provider)[song.identity] ??
        (kind == 'like' ? song.liked : song.saved);
    setState(() => busy = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .interact(song, kind, !enabled);
      if (mounted) {
        ref.read(provider.notifier).state = {
          ...ref.read(provider),
          song.identity: !enabled,
        };
        ref.invalidate(catalogProvider);
        ref.invalidate(communityHomeProvider);
        ref.invalidate(communitySongsProvider);
      }
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final t = context.l10n;
    final active =
        ref.watch(hasSelectedSongProvider) &&
        ref.watch(currentSongProvider)?.identity == song.identity;
    final liked =
        ref.watch(communityLikesProvider)[song.identity] ?? song.liked;
    final saved =
        ref.watch(communitySavesProvider)[song.identity] ?? song.saved;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              widget.onPlay?.call();
              ref
                  .read(playbackActionsProvider)
                  .playFrom(widget.queue, widget.index);
              context.push('/player');
            },
            child: Row(
              children: [
                if (widget.rank != null)
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${widget.rank}'.padLeft(2, '0'),
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                Artwork(url: song.artwork, size: 60, radius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: active ? AppColors.cyan : AppColors.text,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.secondaryText),
                      ),
                      if (widget.showStats)
                        Text(
                          '${song.validPlays} ${t.v3Views} · ${song.likeCount} ${t.v3Likes}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  active ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
                  color: AppColors.mystic,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: widget.rank == null ? 68 : 100),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (song.username != null)
                  TextButton(
                    onPressed: () => context.push(
                      '/u/${Uri.encodeComponent(song.username!)}',
                    ),
                    child: Text('@${song.username}'),
                  ),
                IconButton(
                  tooltip: liked ? t.unlikeSong : t.likeSong,
                  onPressed: busy ? null : () => _interact('like'),
                  icon: Icon(
                    liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: liked ? AppColors.mystic : AppColors.secondaryText,
                  ),
                ),
                IconButton(
                  tooltip: saved ? t.v3RemoveSaved : t.v3SaveTrack,
                  onPressed: busy ? null : () => _interact('save'),
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: t.v3More,
                  onSelected: (value) async {
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
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'queue', child: Text(t.v3AddToQueue)),
                    PopupMenuItem(
                      value: 'playlist',
                      child: Text(t.v3AddToPlaylist),
                    ),
                    PopupMenuItem(value: 'report', child: Text(t.v3Report)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
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
