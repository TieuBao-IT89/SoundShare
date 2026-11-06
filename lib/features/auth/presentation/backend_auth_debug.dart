import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/backend_auth_provider.dart';
import '../../../l10n/l10n.dart';

class BackendAuthDebug extends ConsumerWidget {
  const BackendAuthDebug({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(backendCurrentUserProvider);

    return userState.when(
      loading: () => Text(context.l10n.backendVerifying),
      error: (error, stack) => Text(
        context.l10n.sessionInvalid,
        style: const TextStyle(color: Colors.red),
      ),
      data: (user) => Text(
        user == null
            ? context.l10n.backendNotVerified
            : context.l10n.backendVerified,
        style: const TextStyle(color: Colors.green),
      ),
    );
  }
}
