import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/clerk_config.dart';
import '../core/config/app_mode.dart';
import '../features/auth/presentation/web_auth_stub.dart'
    if (dart.library.js_interop) '../features/auth/presentation/web_auth.dart';
import '../features/auth/presentation/session_scope.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/home/application/catalog_provider.dart';
import '../features/explore/domain/discovery.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/player/presentation/player_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/upload/presentation/upload_screen.dart';
import 'theme/app_theme.dart';

GoRouter createAppRouter({String initialLocation = '/splash'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/explore',
      builder: (context, state) =>
          ExploreScreen(filters: DiscoveryFilters.fromUri(state.uri)),
    ),
    GoRoute(path: '/player', builder: (context, state) => const PlayerScreen()),
    GoRoute(
      path: '/upload',
      builder: (context, state) => Consumer(
        builder: (context, ref, _) => UploadScreen(
          onUpload: ref.watch(demoModeProvider)
              ? null
              : (draft) async {
                  await ref.read(songRepositoryProvider).upload(draft);
                  ref.invalidate(catalogProvider);
                },
        ),
      ),
    ),
    GoRoute(
      path: '/library',
      builder: (context, state) => const LibraryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

final _router = createAppRouter();

class SoundShareApp extends ConsumerWidget {
  const SoundShareApp({
    super.key,
    this.router,
    this.authenticationRequired = true,
  });
  final GoRouter? router;
  final bool authenticationRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'SoundShare',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    routerConfig: router ?? _router,
    builder: (context, child) {
      final appContent = child ?? const SizedBox.shrink();
      if (!authenticationRequired || ref.watch(demoModeProvider)) {
        return appContent;
      }
      if (!ClerkConfig.isConfigured) {
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Sign-in is not configured for this build. Use the documented web setup to connect your account.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      if (kIsWeb) return WebAuthGate(child: appContent);

      return ClerkAuthBuilder(
        signedInBuilder: (context, authState) => SessionScope(
          key: ValueKey(authState.user!.id),
          session: AuthSession(
            subject: authState.user!.id,
            name: authState.user!.hasName
                ? authState.user!.name
                : authState.user!.username ?? 'Music lover',
          ),
          token: ({bool refresh = false}) async =>
              (await authState.sessionToken()).jwt,
          signOut: authState.signOut,
          child: appContent,
        ),
        signedOutBuilder: (context, _) => Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ClerkErrorListener(child: ClerkAuthentication()),
              ),
            ),
          ),
        ),
      );
    },
  );
}
