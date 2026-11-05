import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';

final verifiedSessionProvider = FutureProvider<void>((ref) async {
  await ref
      .watch(apiClientProvider)
      .request('GET', '/auth/me')
      .timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw const ApiException(0, 'SESSION_TIMEOUT'),
      );
});

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(verifiedSessionProvider)
      .when(
        data: (_) => child,
        loading: () => Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        semanticsLabel: 'Opening your library',
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Verifying your session and opening your library…',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => _signOut(context, ref),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        error: (error, _) => Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
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
                        onPressed: () =>
                            ref.invalidate(verifiedSessionProvider),
                        child: const Text('Try again'),
                      ),
                      TextButton(
                        onPressed: () => _signOut(context, ref),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(signOutProvider)().timeout(const Duration(seconds: 15));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign out could not be completed. Try again.'),
          ),
        );
      }
    }
  }
}
