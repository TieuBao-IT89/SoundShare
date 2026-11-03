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
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
      children: [
        const Text(
          'Your profile',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
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
            'Collecting little moments and turning them into songs.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile editing is coming soon.')),
          ),
          child: const Text('Edit profile'),
        ),
        const SizedBox(height: 28),
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
          'A place for independent artists and curious listeners.',
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
