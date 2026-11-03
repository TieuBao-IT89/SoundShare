import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/backend_auth_provider.dart';

class BackendAuthDebug extends ConsumerWidget {
  const BackendAuthDebug({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(backendCurrentUserProvider);

    return userState.when(
      loading: () => const Text('Backend: Verifying...'),
      error: (error, stack) => Text(
        'Backend authentication failed: $error',
        style: const TextStyle(color: Colors.red),
      ),
      data: (user) => Text(
        user == null
            ? 'Backend: Not verified'
            : 'Backend: Authenticated (${user.clerkUserId})',
        style: const TextStyle(color: Colors.green),
      ),
    );
  }
}
