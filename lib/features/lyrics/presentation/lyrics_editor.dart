import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../data/lyrics_repository.dart';
import 'lrc_attachment.dart';

Future<void> showLyricsEditor(BuildContext context, Song song) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) {
        final inset = MediaQuery.viewInsetsOf(context).bottom;
        final height =
            (MediaQuery.sizeOf(context).height - inset)
                .clamp(0.0, double.infinity)
                .toDouble() *
            .85;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SizedBox(
            height: height,
            child: SafeArea(top: false, child: LyricsEditor(song: song)),
          ),
        );
      },
    );

class LyricsEditor extends ConsumerStatefulWidget {
  const LyricsEditor({super.key, required this.song});
  final Song song;
  @override
  ConsumerState<LyricsEditor> createState() => _LyricsEditorState();
}

class _LyricsEditorState extends ConsumerState<LyricsEditor> {
  bool initialized = false, valid = true, busy = false, conflict = false;
  String? source, error;
  int revision = 0;

  Future<void> submit({bool remove = false}) async {
    if (busy || (!remove && (!valid || source == null))) return;
    final id = widget.song.id;
    if (id == null) return;
    if (remove) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.v11RemoveConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.v11RemoveLyrics),
            ),
          ],
        ),
      );
      if (!mounted || yes != true) return;
    }
    setState(() {
      busy = true;
      error = null;
      conflict = false;
    });
    try {
      final repo = ref.read(lyricsRepositoryProvider);
      if (remove) {
        await repo.remove(id, revision);
      } else {
        await repo.save(id, source!, revision);
      }
      if (!mounted) return;
      ref.invalidate(lyricsDocumentProvider(id));
      setState(() => busy = false);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e is ApiException ? e.message : context.l10n.v11SaveFailed;
          conflict = e is ApiException && e.code == 'LYRICS_CHANGED';
        });
      }
    } finally {
      if (mounted && busy) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return PopScope(
      canPop: !busy,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.v11EditLyrics,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ref
                .watch(lyricsDocumentProvider(widget.song.id))
                .when(
                  skipLoadingOnRefresh: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.v11LoadFailed),
                        TextButton(
                          onPressed: () => ref.invalidate(
                            lyricsDocumentProvider(widget.song.id),
                          ),
                          child: Text(t.tryAgain),
                        ),
                      ],
                    ),
                  ),
                  data: (doc) {
                    if (!doc.canEdit || widget.song.id == null) {
                      return Center(child: Text(t.v11OwnerOnly));
                    }
                    if (!initialized) {
                      source = doc.lrc?.source;
                      revision = doc.revision;
                      initialized = true;
                    }
                    return ListView(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        Text(
                          widget.song.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        LrcAttachment(
                          key: ValueKey('${widget.song.id}-$revision'),
                          initialValue: doc.lrc?.source,
                          enabled: !busy,
                          onChanged: (value, ok) => setState(() {
                            source = value;
                            valid = ok;
                            error = null;
                          }),
                        ),
                        const SizedBox(height: 24),
                        if (error != null) ...[
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (conflict)
                          TextButton(
                            onPressed: busy
                                ? null
                                : () {
                                    setState(() {
                                      initialized = false;
                                      conflict = false;
                                      error = null;
                                      valid = true;
                                    });
                                    ref.invalidate(
                                      lyricsDocumentProvider(widget.song.id),
                                    );
                                  },
                            child: Text(t.v11ReloadLyrics),
                          ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: busy || !valid || source == null
                                  ? null
                                  : () => submit(),
                              child: Text(busy ? t.v11Saving : t.v11SaveLyrics),
                            ),
                            if (doc.lrc != null)
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => submit(remove: true),
                                child: Text(t.v11RemoveLyrics),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
