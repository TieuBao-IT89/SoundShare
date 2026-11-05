import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/clerk_config.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/catalog_widgets.dart';
import '../../home/application/catalog_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ClerkConfig.isConfigured) return _profile(context, ref);
    return ClerkAuthBuilder(
      builder: (context, auth) {
        final user = auth.user;
        return _profile(
          context,
          ref,
          name: user == null
              ? null
              : user.hasName
              ? user.name
              : user.username ?? 'Music lover',
        );
      },
    );
  }

  Widget _profile(BuildContext context, WidgetRef ref, {String? name}) {
    final likes = ref.watch(likedSongIndicesProvider).length;
    return AppScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
        children: [
          const ScreenHeading(
            eyebrow: 'YOUR CORNER',
            title: 'A little more you.',
            subtitle: 'Make room for the music you come back to.',
          ),
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 38,
              backgroundColor: AppColors.surfaceLight,
              child: Icon(
                Icons.person_outline_rounded,
                size: 36,
                color: AppColors.violet,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name ?? 'Listening as a guest',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            name == null
                ? 'You are exploring the sample catalog. Your likes stay in this session.'
                : 'Welcome back. Your likes in this preview stay in this session.',
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 26),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.violet,
            ),
            title: Text('$likes liked ${likes == 1 ? 'track' : 'tracks'}'),
            subtitle: const Text('Open your listening shelf'),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () => context.go('/library'),
          ),
          const Divider(height: 32),
          const Text(
            'Your artist profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Profile editing, uploads and follower counts will appear when account features are ready.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/explore'),
            child: const Text(
              'Find your next favorite',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'SOUNDSHARE',
            style: TextStyle(
              color: AppColors.mint,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Independent sounds. A place to listen.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
