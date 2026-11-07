import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/catalog_provider.dart';
import '../../home/domain/song.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';

class ManageSongsScreen extends ConsumerWidget {
  const ManageSongsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            t.v3ManageSongs,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CommunityAsync(
            value: ref.watch(catalogProvider),
            retry: () => ref.invalidate(catalogProvider),
            data: (songs) => Column(
              children: [
                if (songs.isEmpty) const CommunityEmpty(),
                for (final song in songs)
                  ListTile(
                    title: Text(song.title),
                    subtitle: Text(
                      '${song.artist} · ${song.visibility == 'public' ? t.v3Public : t.v3Private}',
                    ),
                    trailing: IconButton(
                      tooltip: t.v3EditSong,
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _SongEditor(song: song),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SongEditor extends ConsumerStatefulWidget {
  const _SongEditor({required this.song});
  final Song song;
  @override
  ConsumerState<_SongEditor> createState() => _SongEditorState();
}

class _SongEditorState extends ConsumerState<_SongEditor> {
  late final title = TextEditingController(text: widget.song.title),
      artist = TextEditingController(text: widget.song.artist),
      genre = TextEditingController(text: widget.song.genre),
      description = TextEditingController(text: widget.song.description);
  late bool isPublic = widget.song.visibility == 'public';
  bool rights = false, busy = false;
  @override
  void dispose() {
    title.dispose();
    artist.dispose();
    genre.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> submit(bool remove) async {
    if (!remove && isPublic && !rights) {
      communityError(context, StateError('rights'));
      return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (remove) {
        await repo.deleteSong(widget.song.id!);
      } else {
        await repo.patchSong(widget.song.id!, {
          'title': title.text.trim(),
          'artist': artist.text.trim(),
          'genre': genre.text.trim(),
          'description': description.text.trim(),
          'visibility': isPublic ? 'public' : 'private',
          'rightsConfirmed': rights,
        });
      }
      ref.invalidate(catalogProvider);
      ref.invalidate(communityHomeProvider);
      ref.invalidate(communitySongsProvider);
      ref.invalidate(myPublicProfileProvider);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) communityError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AlertDialog(
      title: Text(t.v3EditSong),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              maxLength: 120,
              decoration: InputDecoration(labelText: t.songTitle),
            ),
            TextField(
              controller: artist,
              maxLength: 120,
              decoration: InputDecoration(labelText: t.artistName),
            ),
            TextField(
              controller: genre,
              maxLength: 100,
              decoration: InputDecoration(labelText: t.genre),
            ),
            TextField(
              controller: description,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(labelText: t.descriptionOptional),
            ),
            SwitchListTile(
              title: Text(t.v3Public),
              value: isPublic,
              onChanged: busy
                  ? null
                  : (value) => setState(() => isPublic = value),
            ),
            if (isPublic)
              CheckboxListTile(
                value: rights,
                title: Text(t.v3Rights),
                onChanged: busy
                    ? null
                    : (value) => setState(() => rights = value ?? false),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(t.v3DeleteSong),
                      content: Text(t.v3DeleteConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(t.v3Cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(t.v3Delete),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await submit(true);
                },
          child: Text(t.v3Delete),
        ),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(t.v3Cancel),
        ),
        FilledButton(
          onPressed: busy || (isPublic && !rights) ? null : () => submit(false),
          child: Text(t.v3Save),
        ),
      ],
    );
  }
}
