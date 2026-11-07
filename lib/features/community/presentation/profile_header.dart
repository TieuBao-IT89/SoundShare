import '../../../core/widgets/theme_mode_menu.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/api_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';
import 'profile_account_menu.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.profile});
  final PublicProfile profile;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile, t = context.l10n;
    final name = p.displayName.isEmpty
        ? ref.watch(authSessionProvider)?.name ?? t.accountName
        : p.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, bounds) => ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: bounds.maxWidth >= 650 ? 172 : 120,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  p.cover.isNotEmpty
                      ? Artwork(
                          url: p.cover,
                          size: bounds.maxWidth,
                          height: bounds.maxWidth >= 650 ? 172 : 120,
                          radius: 0,
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: context.colors.featuredGradient,
                          ),
                          child: Align(
                            alignment: p.isSelf
                                ? Alignment.center
                                : Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                size: 72,
                                color: context.colors.text.withValues(
                                  alpha: .16,
                                ),
                              ),
                            ),
                          ),
                        ),
                  if (p.isSelf)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [ThemeModeMenu(), ProfileAccountMenu()],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colors.background,
                      width: 5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Artwork(url: p.avatar, size: 80, radius: 50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (p.username != null)
                          Text(
                            '@${p.username}',
                            style: TextStyle(color: context.colors.mystic),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (p.bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              p.bio,
              style: TextStyle(color: context.colors.secondaryText),
            ),
          ),
        if (p.username != null)
          Wrap(
            spacing: 12,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                child: Text(
                  '${p.songs} ${t.v3Songs}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (p.isSelf) ...[
              FilledButton.icon(
                onPressed: () => context.push('/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  p.username == null ? t.v3CreateProfile : t.v3EditProfile,
                ),
              ),
              IconButton(
                tooltip: t.v3ManageSongs,
                onPressed: () => context.push('/manage-songs'),
                icon: const Icon(Icons.library_music_outlined),
              ),
            ] else
              FollowButton(profile: p),
            if (p.username != null)
              IconButton(
                tooltip: t.v3ShareProfile,
                icon: const Icon(Icons.ios_share_rounded),
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
              ),
            if (!p.isSelf)
              IconButton(
                tooltip: t.v3Report,
                onPressed: () => reportContent(context, ref, profileId: p.id),
                icon: const Icon(Icons.flag_outlined),
              ),
          ],
        ),
      ],
    );
  }
}
