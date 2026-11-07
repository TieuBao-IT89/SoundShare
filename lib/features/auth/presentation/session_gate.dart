import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/api_client.dart';
import '../../../core/widgets/aurora_widgets.dart';
import '../../../core/widgets/authentication_header.dart';
import '../../../l10n/l10n.dart';

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
        loading: () => AuthenticationScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthenticationHeader(compact: true),
              const SizedBox(height: 32),
              if (MediaQuery.disableAnimationsOf(context))
                Icon(
                  Icons.hourglass_top_rounded,
                  color: context.colors.accentText,
                )
              else
                CircularProgressIndicator(
                  semanticsLabel: context.l10n.openingLibrary,
                ),
              const SizedBox(height: 20),
              Text(context.l10n.verifyingSession, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _signOut(context, ref),
                child: Text(context.l10n.signOut),
              ),
            ],
          ),
        ),
        error: (error, _) => AuthenticationScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthenticationHeader(compact: true),
              const SizedBox(height: 28),
              GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: context.colors.error,
                      size: 30,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error is ApiException
                            ? error.message
                            : context.l10n.libraryOpenFailed,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      onPressed: () => ref.invalidate(verifiedSessionProvider),
                      label: context.l10n.tryAgain,
                      icon: Icons.refresh_rounded,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _signOut(context, ref),
                      child: Text(context.l10n.signOut),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(signOutProvider)().timeout(const Duration(seconds: 15));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.signOutFailed)));
      }
    }
  }
}
