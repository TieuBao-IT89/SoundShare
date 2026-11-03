import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/config/clerk_config.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/presentation/backend_auth_debug.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const Text(
          'Profile preview',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Example profile content while account features are in progress.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 34),
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.surfaceLight,
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: AppColors.violet,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Alex Morgan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 5),
        const Center(
          child: Text(
            '@alexmakesmusic',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'A place to follow independent artists and keep the songs you love.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile editing is not available in this preview.',
              ),
            ),
          ),
          child: const Text('Edit sample profile'),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Sample profile statistics',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(value: '8', label: 'Uploads'),
            _Stat(value: '240', label: 'Followers'),
            _Stat(value: '186', label: 'Following'),
          ],
        ),
        const SizedBox(height: 34),
        const Text(
          'About SoundShare',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'SoundShare brings music discovery and listening together in one place.',
          style: TextStyle(color: AppColors.muted),
        ),
        if (ClerkConfig.isConfigured) ...[
          const SizedBox(height: 24),
          const BackendAuthDebug(),
        ],
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}
