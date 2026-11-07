import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../../community/presentation/community_widgets.dart';
import '../../social/application/social_providers.dart';
import '../../social/data/social_repository.dart';
import '../../social/presentation/social_load_error.dart';

Future<void> showComments(
  BuildContext context,
  WidgetRef ref,
  String trackId, {
  String? commentId,
}) async {
  await ref.read(playbackActionsProvider).pause();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 720),
    builder: (_) => CommentsSheet(trackId: trackId, commentId: commentId),
  );
}

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.trackId, this.commentId});
  final String trackId;
  final String? commentId;
  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final input = TextEditingController();
  CursorPage<SocialJson>? page;
  Object? error;
  String? cursor, parent;
  SocialJson? thread;
  bool resolved = false;
  final previous = <String?>[];
  bool busy = false, loading = true;
  int generation = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    generation++;
    input.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final request = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (!resolved && widget.commentId != null) {
        final target = await ref
            .read(socialRepositoryProvider)
            .commentContext(widget.commentId!);
        if (!mounted || request != generation) return;
        if (target['trackId'] != widget.trackId) {
          throw StateError('Comment unavailable');
        }
        parent = target['rootId'];
        thread = target;
        resolved = true;
      }
      final result = await ref
          .read(socialRepositoryProvider)
          .comments(widget.trackId, cursor, parent: parent);
      if (!mounted || request != generation) return;
      setState(() => page = result);
      ref.read(commentCountsProvider.notifier).state = {
        ...ref.read(commentCountsProvider),
        widget.trackId: result.total ?? 0,
      };
    } catch (e) {
      if (mounted && request == generation) setState(() => error = e);
    } finally {
      if (mounted && request == generation) setState(() => loading = false);
    }
  }

  Future<void> action(
    Future<void> Function() operation, {
    bool clear = false,
  }) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await operation();
      if (!mounted) return;
      if (clear) input.clear();
      await load();
    } catch (e) {
      if (mounted) communityError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * .78 -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(120, MediaQuery.sizeOf(context).height * .78),
        child: Column(
          children: [
            ListTile(
              leading: parent == null
                  ? const Icon(Icons.chat_bubble_outline)
                  : IconButton(
                      tooltip: t.v9BackComments,
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          parent = null;
                          thread = null;
                          cursor = null;
                          previous.clear();
                        });
                        load();
                      },
                    ),
              title: Text(t.v9Comments),
              trailing: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          if (thread != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                thread!['deleted'] == true
                                    ? t.v9DeletedComment
                                    : thread!['content'],
                              ),
                            ),
                          if (page?.items.isEmpty ?? true)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(t.v9NoComments),
                            ),
                          for (final c in page?.items ?? <SocialJson>[])
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: c['author']['username'] == null
                                        ? null
                                        : () {
                                            Navigator.pop(context);
                                            context.push(
                                              '/u/${Uri.encodeComponent(c['author']['username'])}',
                                            );
                                          },
                                    child: Artwork(
                                      url: c['author']['avatar']?['url'] ?? '',
                                      size: 36,
                                      radius: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${c['author']['displayName']} · @${c['author']['username'] ?? ''}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge,
                                        ),
                                        Text(
                                          MaterialLocalizations.of(context)
                                              .formatShortDate(
                                                DateTime.parse(c['createdAt'])
                                                    .toLocal(),
                                              ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          c['deleted'] == true
                                              ? t.v9DeletedComment
                                              : c['content'],
                                        ),
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            if (c['deleted'] != true)
                                              TextButton.icon(
                                                onPressed: busy
                                                    ? null
                                                    : () => action(
                                                        () => ref
                                                            .read(
                                                              socialRepositoryProvider,
                                                            )
                                                            .likeComment(
                                                              c['id'],
                                                              c['liked'] !=
                                                                  true,
                                                            ),
                                                      ),
                                                icon: Icon(
                                                  c['liked'] == true
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  '${c['likeCount']}',
                                                ),
                                              ),
                                            if (parent == null &&
                                                (c['replyCount'] > 0 ||
                                                    c['deleted'] != true))
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    parent = c['id'];
                                                    cursor = null;
                                                    previous.clear();
                                                  });
                                                  load();
                                                },
                                                child: Text(
                                                  '${t.v9Replies} (${c['replyCount']})',
                                                ),
                                              ),
                                            if (c['deleted'] != true)
                                              PopupMenuButton<String>(
                                                onSelected: (value) => action(() async {
                                                  if (value == 'delete') {
                                                    await ref
                                                        .read(
                                                          socialRepositoryProvider,
                                                        )
                                                        .deleteComment(c['id']);
                                                  } else {
                                                    await ref
                                                        .read(
                                                          socialRepositoryProvider,
                                                        )
                                                        .reportComment(
                                                          c['id'],
                                                          value,
                                                        );
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            t.v9ReportSent,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                }),
                                                itemBuilder: (_) => [
                                                  if (c['isSelf'] == true)
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text(
                                                        t.v9DeleteComment,
                                                      ),
                                                    ),
                                                  PopupMenuItem(
                                                    value: 'spam',
                                                    child: Text(t.v3Spam),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'abuse',
                                                    child: Text(t.v3Report),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: parent == null
                              ? t.v9WriteComment
                              : t.v9Reply,
                          counterText: '',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: t.v9Send,
                      onPressed: busy
                          ? null
                          : () => action(() async {
                              await ref
                                  .read(socialRepositoryProvider)
                                  .comment(
                                    widget.trackId,
                                    input.text.trim(),
                                    parent: parent,
                                  );
                              cursor = null;
                              previous.clear();
                            }, clear: true),
                      icon: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
