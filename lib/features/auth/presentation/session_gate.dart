import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';

final verifiedSessionProvider = FutureProvider<void>((ref) async {
  await ref.watch(apiClientProvider).request('GET', '/auth/me');
});

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(verifiedSessionProvider)
      .when(
        data: (_) => child,
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Opening your library',
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException
                        ? error.message
                        : 'Your library could not be opened.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(verifiedSessionProvider),
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(signOutProvider)();
                      } catch (_) {}
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
