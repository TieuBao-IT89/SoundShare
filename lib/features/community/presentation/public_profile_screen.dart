import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../../auth/presentation/account_management.dart';
import '../application/community_providers.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

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
        if (p.cover.isNotEmpty)
          LayoutBuilder(
            builder: (context, bounds) => Artwork(
              url: p.cover,
              size: bounds.maxWidth,
              height: 200,
              radius: 8,
            ),
          ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Artwork(url: p.avatar, size: 96, radius: 50),
        ),
        const SizedBox(height: 20),
        Text(
          p.displayName.isEmpty
              ? ref.watch(authSessionProvider)?.name ?? t.accountName
              : p.displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (p.username != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '@${p.username}',
              style: const TextStyle(color: AppColors.mystic, fontSize: 16),
            ),
          ),
        if (p.bio.isNotEmpty)
          Text(p.bio, style: const TextStyle(color: AppColors.secondaryText)),
        const SizedBox(height: 16),
        if (p.username != null)
          Wrap(
            spacing: 20,
            children: [
              TextButton(
                onPressed: () => context.push('/connections/${p.id}/followers'),
                child: Text('${p.followers} ${t.v3Followers}'),
              ),
              TextButton(
                onPressed: () => context.push('/connections/${p.id}/following'),
                child: Text('${p.followingCount} ${t.v3Following}'),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${p.songs} ${t.v3Songs}'),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (p.isSelf)
              FilledButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  p.username == null ? t.v3CreateProfile : t.v3EditProfile,
                ),
              )
            else
              FollowButton(profile: p),
            if (p.username != null)
              OutlinedButton.icon(
                onPressed: () async {
                  final origin = Uri.base.hasAuthority
                      ? Uri.base.origin
                      : ApiConfig.baseUrl;
                  await Clipboard.setData(
                    ClipboardData(text: '$origin/#/u/${p.username}'),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(t.v3Copied)));
                  }
                },
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(t.v3ShareProfile),
              ),
            if (!p.isSelf)
              TextButton(
                onPressed: () => reportContent(context, ref, profileId: p.id),
                child: Text(t.v3Report),
              ),
          ],
        ),
        if (p.isSelf) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/manage-songs'),
                icon: const Icon(Icons.library_music_outlined),
                label: Text(t.v3ManageSongs),
              ),
              const AccountManagementButton(),
              TextButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(signOutProvider)();
                  } catch (error) {
                    if (context.mounted) communityError(context, error);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(t.signOut),
              ),
            ],
          ),
        ],
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
                  for (final item in data['items'] as List)
                    ListTile(
                      leading: const Icon(Icons.queue_music_rounded),
                      title: Text(item['title'] as String),
                      subtitle: Text('${item['songCount']} ${t.v3Songs}'),
                      onTap: () => context.push('/playlists/${item['id']}'),
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
