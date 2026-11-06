import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/section_heading.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final key = (query, type, offset);
    final result = query.isEmpty
        ? null
        : ref.watch(communitySearchProvider(key));
    return AppScaffold(
      child: ListView(
        key: const PageStorageKey('community-search'),
        padding: const EdgeInsets.all(24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Text(t.search, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            t.v4SearchIntro,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            onChanged: change,
            onSubmitted: (_) => remember(),
            maxLength: 120,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t.v3SearchHint,
              counterText: '',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: t.clearSearch,
                      onPressed: () {
                        controller.clear();
                        change('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          ContentTabs(
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
            SectionHeading(t.v3RecentSearches),
            for (final recent in ref.watch(recentCommunitySearchesProvider))
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(recent),
                onTap: () {
                  controller.text = recent;
                  change(recent);
                },
              ),
            Text(
              t.v3SearchPrivacy,
              style: const TextStyle(
                color: AppColors.secondaryText,
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
