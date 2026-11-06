import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../l10n/l10n.dart';
import '../application/community_providers.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';
import 'profile_header.dart';
import 'playlist_preview.dart';

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({super.key, this.username});
  final String? username;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = username == null
        ? myPublicProfileProvider
        : publicProfileProvider(username!);
    return AppScaffold(
      child: CommunityAsync(
        value: ref.watch(provider),
        retry: () => ref.invalidate(provider),
        data: (profile) => _ProfileContent(profile: profile),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.profile});
  final PublicProfile profile;
  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  int tab = 0, offset = 0;
  @override
  Widget build(BuildContext context) {
    final t = context.l10n, p = widget.profile;
    final query = (
      path: '/users/${Uri.encodeComponent(p.username ?? '')}/songs',
      offset: offset,
      period: null as String?,
      genre: null as String?,
    );
    return ListView(
      key: PageStorageKey('profile-${p.id}'),
      padding: const EdgeInsets.all(24),
      children: [
        ProfileHeader(profile: p),
        const SizedBox(height: 32),
        if (p.username == null)
          Text(
            t.v3ProfileIntro,
            style: const TextStyle(color: AppColors.secondaryText),
          )
        else ...[
          Wrap(
            spacing: 12,
            children: [
              for (final item in [
                (0, t.v3Songs),
                (1, t.v3Playlists),
                (2, t.v3About),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: tab == item.$1,
                  onSelected: (_) => setState(() {
                    tab = item.$1;
                    offset = 0;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (tab == 0)
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
          if (tab == 1)
            CommunityAsync(
              value: ref.watch(publicPlaylistsProvider((p.username!, offset))),
              retry: () => ref.invalidate(
                publicPlaylistsProvider((p.username!, offset)),
              ),
              data: (data) => Column(
                children: [
                  if ((data['items'] as List).isEmpty) const CommunityEmpty(),
                  if ((data['items'] as List).isNotEmpty)
                    PlaylistGrid(
                      items: (data['items'] as List)
                          .cast<Map<String, dynamic>>(),
                    ),
                  CommunityPager(
                    offset: offset,
                    next: data['nextOffset'] as int?,
                    onPage: (value) => setState(() => offset = value),
                  ),
                ],
              ),
            ),
          if (tab == 2) Text(p.bio.isEmpty ? t.v3NoContent : p.bio),
        ],
      ],
    );
  }
}

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key, required this.id, required this.kind});
  final String id, kind;
  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  int offset = 0;
  @override
  Widget build(BuildContext context) {
    final key = (widget.id, widget.kind, offset);
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            widget.kind == 'followers'
                ? context.l10n.v3Followers
                : context.l10n.v3Following,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          CommunityAsync(
            value: ref.watch(connectionsProvider(key)),
            retry: () => ref.invalidate(connectionsProvider(key)),
            data: (page) => Column(
              children: [
                if (page.items.isEmpty) const CommunityEmpty(),
                for (final profile in page.items) CreatorRow(profile: profile),
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
