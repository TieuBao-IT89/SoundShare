import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/services/share_link.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/services/audio_service.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';
import '../../home/domain/song.dart';
import '../application/community_providers.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';
import 'playlist_preview.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});
  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  int offset = 0;
  bool busy = false;
  Future<void> create() async {
    var draftTitle = '';
    bool isPublic = false;
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(ctx.l10n.v3CreatePlaylist),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => draftTitle = value,
                  maxLength: 150,
                  decoration: InputDecoration(
                    labelText: ctx.l10n.v3PlaylistTitle,
                  ),
                ),
                SwitchListTile(
                  title: Text(ctx.l10n.v3Public),
                  value: isPublic,
                  onChanged: (value) => update(() => isPublic = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.v3Cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, draftTitle.trim()),
              child: Text(ctx.l10n.v3Save),
            ),
          ],
        ),
      ),
    );
    if (title == null || title.isEmpty) return;
    if (mounted) setState(() => busy = true);
    try {
      final id = await ref
          .read(communityRepositoryProvider)
          .createPlaylist(title, isPublic);
      ref.invalidate(myPlaylistsProvider);
      if (mounted) context.push('/playlists/$id');
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            t.v3Playlists,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: busy ? null : create,
              icon: const Icon(Icons.add_rounded),
              label: Text(t.v3CreatePlaylist),
            ),
          ),
          const SizedBox(height: 24),
          CommunityAsync(
            value: ref.watch(myPlaylistsProvider(offset)),
            retry: () => ref.invalidate(myPlaylistsProvider(offset)),
            data: (data) => Column(
              children: [
                if ((data['items'] as List).isEmpty) const CommunityEmpty(),
                if ((data['items'] as List).isNotEmpty)
                  PlaylistGrid(
                    items: (data['items'] as List).cast<Map<String, dynamic>>(),
                  ),
                CommunityPager(
                  offset: offset,
                  next: data['nextOffset'] as int?,
                  onPage: (value) => setState(() => offset = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  int offset = 0;
  bool busy = false;
  Future<void> playAll({bool shuffle = false}) async {
    setState(() => busy = true);
    try {
      final songs = await ref
          .read(communityRepositoryProvider)
          .playlistQueue(widget.id);
      if (!mounted || songs.isEmpty) return;
      final actions = ref.read(playbackActionsProvider);
      if (ref.read(shuffleEnabledProvider) != shuffle) {
        await actions.toggleShuffle();
      }
      if (!mounted) return;
      if (ref.read(shuffleEnabledProvider) != shuffle) {
        throw StateError('Playback setting unavailable');
      }
      await actions.playFrom(
        songs,
        shuffle ? Random().nextInt(songs.length) : 0,
      );
      if (mounted) context.push('/player');
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> change(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      ref.invalidate(playlistDetailProvider);
      ref.invalidate(myPlaylistsProvider);
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> add() async {
    final songs = await ref.read(catalogProvider.future);
    if (!mounted) return;
    final song = await showDialog<Song>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(ctx.l10n.v3AddToPlaylist),
        children: [
          if (songs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(ctx.l10n.v3NoContent),
            ),
          for (final song in songs)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, song),
              child: Text('${song.title} · ${song.artist}'),
            ),
        ],
      ),
    );
    if (song != null) {
      await change(
        () => ref
            .read(communityRepositoryProvider)
            .addToPlaylist(widget.id, song),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (widget.id, offset);
    final t = context.l10n;
    return AppScaffold(
      child: CommunityAsync(
        value: ref.watch(playlistDetailProvider(key)),
        retry: () => ref.invalidate(playlistDetailProvider(key)),
        data: (data) {
          final page = CommunityPage.fromJson(data['tracks'], Song.fromJson);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                data['title'] as String,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if ((data['description'] as String?)?.isNotEmpty == true)
                Text(data['description'] as String),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy || page.items.isEmpty
                        ? null
                        : () => playAll(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(t.v4PlayAll),
                  ),
                  if (data['visibility'] == 'public')
                    IconButton(
                      tooltip: t.v9Share,
                      onPressed: () =>
                          shareLink(context, '/playlists/${widget.id}'),
                      icon: const Icon(Icons.ios_share),
                    ),
                  OutlinedButton.icon(
                    onPressed: busy || page.items.isEmpty
                        ? null
                        : () => playAll(shuffle: true),
                    icon: const Icon(Icons.shuffle_rounded),
                    label: Text(t.v4ShufflePlay),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data['isSelf'] == true)
                Wrap(
                  spacing: 16,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : add,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t.v3AddToPlaylist),
                    ),
                    TextButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(t.v3DeletePlaylist),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(t.v3Cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(t.v3Delete),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await change(() async {
                                  await ref
                                      .read(communityRepositoryProvider)
                                      .deletePlaylist(widget.id);
                                  if (context.mounted) context.go('/playlists');
                                });
                              }
                            },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(t.v3DeletePlaylist),
                    ),
                  ],
                ),
              if (page.items.isEmpty) const CommunityEmpty(),
              for (var i = 0; i < page.items.length; i++)
                Column(
                  children: [
                    CommunitySongRow(
                      song: page.items[i],
                      queue: page.items,
                      index: i,
                    ),
                    if (data['isSelf'] == true)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () => change(
                                  () => ref
                                      .read(communityRepositoryProvider)
                                      .removeFromPlaylist(
                                        widget.id,
                                        page.items[i],
                                      ),
                                ),
                          child: Text(t.v3RemoveFromPlaylist),
                        ),
                      ),
                  ],
                ),
              CommunityPager(
                offset: offset,
                next: page.nextOffset,
                onPage: (value) => setState(() => offset = value),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SavedTracksScreen extends ConsumerStatefulWidget {
  const SavedTracksScreen({super.key, this.liked = false});
  final bool liked;
  @override
  ConsumerState<SavedTracksScreen> createState() => _SavedTracksScreenState();
}

class _SavedTracksScreenState extends ConsumerState<SavedTracksScreen> {
  int offset = 0;
  @override
  Widget build(BuildContext context) {
    final query = (
      path: widget.liked ? '/community/liked' : '/community/saved',
      offset: offset,
      period: null as String?,
      genre: null as String?,
    );
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.liked
                ? context.l10n.yourFavorites
                : context.l10n.v3SavedTracks,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CommunityAsync(
            value: ref.watch(communitySongsProvider(query)),
            retry: () => ref.invalidate(communitySongsProvider(query)),
            data: (page) => Column(
              children: [
                if (page.items.isEmpty) const CommunityEmpty(),
                for (var i = 0; i < page.items.length; i++)
                  CommunitySongRow(
                    song: page.items[i],
                    queue: page.items,
                    index: i,
                  ),
                CommunityPager(
                  offset: offset,
                  next: page.nextOffset,
                  onPage: (value) => setState(() => offset = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
