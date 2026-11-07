import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/soundshare_search_field.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../application/community_providers.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';
import 'music_components.dart';
import 'search_suggestions.dart';

class CommunitySearchScreen extends ConsumerStatefulWidget {
  const CommunitySearchScreen({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override
  ConsumerState<CommunitySearchScreen> createState() =>
      _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends ConsumerState<CommunitySearchScreen> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialQuery,
  );
  late String query = widget.initialQuery;
  String type = 'all';
  int offset = 0;
  Timer? timer;
  @override
  void didUpdateWidget(covariant CommunitySearchScreen old) {
    super.didUpdateWidget(old);
    if (old.initialQuery != widget.initialQuery) {
      timer?.cancel();
      controller.text = widget.initialQuery;
      query = widget.initialQuery;
      offset = 0;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void change(String value) {
    timer?.cancel();
    setState(() {});
    timer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          query = value.trim();
          offset = 0;
        });
      }
    });
  }

  void remember() {
    final value = query.trim();
    if (value.isEmpty) return;
    ref.read(recentCommunitySearchesProvider.notifier).state = [
      value,
      ...ref.read(recentCommunitySearchesProvider).where((q) => q != value),
    ].take(8).toList();
  }

  void submit(String value) {
    timer?.cancel();
    setState(() {
      query = value.trim();
      offset = 0;
    });
    remember();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final key = (query, type, offset);
    final result = query.isEmpty
        ? null
        : ref.watch(communitySearchProvider(key));
    final recentSearches = ref.watch(recentCommunitySearchesProvider);
    return AppScaffold(
      child: ListView(
        // Build the search header even in a short landscape viewport; its
        // shortcut remains available when the kept-alive field scrolls away.
        scrollCacheExtent: const ScrollCacheExtent.pixels(600),
        key: const PageStorageKey('community-search'),
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(
            t.search.toUpperCase(),
            style: TextStyle(
              color: context.colors.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.v4SearchIntro,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          SoundShareSearchField(
            controller: controller,
            onChanged: change,
            onSubmitted: submit,
            hintText: t.v3SearchHint,
            enableShortcut: true,
          ),
          const SizedBox(height: 20),
          ContentTabs(
            icons: const {
              'all': Icons.grid_view_rounded,
              'songs': Icons.music_note_rounded,
              'users': Icons.alternate_email_rounded,
              'playlists': Icons.queue_music_rounded,
            },
            items: [
              ('all', t.v3All),
              ('songs', t.v3Songs),
              ('users', t.v3Accounts),
              ('playlists', t.v3Playlists),
            ],
            selected: type,
            onSelected: (value) => setState(() {
              type = value;
              offset = 0;
            }),
          ),
          const SizedBox(height: 24),
          if (result == null) ...[
            if (recentSearches.isNotEmpty) ...[
              SectionHeading(
                t.v3RecentSearches,
                actionLabel: t.clearSearchHistory,
                onAction: () =>
                    ref.read(recentCommunitySearchesProvider.notifier).state =
                        [],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final recent in recentSearches)
                    InputChip(
                      avatar: const Icon(Icons.history_rounded, size: 18),
                      label: Text(
                        recent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        controller.value = TextEditingValue(
                          text: recent,
                          selection: TextSelection.collapsed(
                            offset: recent.length,
                          ),
                        );
                        submit(recent);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                t.v3SearchDescription,
                style: TextStyle(
                  color: context.colors.secondaryText,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              t.v3SearchPrivacy,
              style: TextStyle(
                color: context.colors.secondaryText,
                fontSize: 12,
              ),
            ),
            const SearchSuggestions(),
          ] else
            CommunityAsync(
              value: result,
              retry: () => ref.invalidate(communitySearchProvider(key)),
              data: (data) {
                final users = CommunityPage.fromJson(
                  data['users'],
                  PublicProfile.fromJson,
                );
                final songs = CommunityPage.fromJson(
                  data['songs'],
                  Song.fromJson,
                );
                final playlists =
                    data['playlists'] as Map<String, dynamic>? ??
                    {'items': <dynamic>[], 'nextOffset': null};
                final next =
                    users.nextOffset ??
                    songs.nextOffset ??
                    playlists['nextOffset'] as int?;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (users.items.isEmpty &&
                        songs.items.isEmpty &&
                        (playlists['items'] as List).isEmpty)
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: t.noResults,
                        message: query.startsWith('@')
                            ? t.v3SearchDescription
                            : t.v3NoContentDescription,
                      ),
                    if (users.items.isNotEmpty) ...[
                      SectionHeading(t.v3Accounts),
                      for (final user in users.items)
                        CreatorRow(profile: user, onOpen: remember),
                    ],
                    if (songs.items.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SectionHeading(t.v3Songs),
                      for (var i = 0; i < songs.items.length; i++)
                        CommunitySongRow(
                          onPlay: remember,
                          song: songs.items[i],
                          queue: songs.items,
                          index: i,
                        ),
                    ],
                    if ((playlists['items'] as List).isNotEmpty) ...[
                      SectionHeading(t.v3Playlists),
                      for (final item in playlists['items'] as List)
                        ListTile(
                          leading: const Icon(Icons.queue_music_rounded),
                          title: Text(item['title'] as String),
                          subtitle: Text('${item['songCount']} ${t.v3Songs}'),
                          onTap: () {
                            remember();
                            context.push('/playlists/${item['id']}');
                          },
                        ),
                    ],
                    CommunityPager(
                      offset: offset,
                      next: next,
                      onPage: (value) => setState(() => offset = value),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
