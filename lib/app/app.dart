import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/clerk_config.dart';
import '../features/auth/presentation/backend_auth_bootstrap.dart';
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
    GoRoute(path: '/upload', builder: (context, state) => const UploadScreen()),
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

class SoundShareApp extends StatelessWidget {
  const SoundShareApp({super.key, this.router});
  final GoRouter? router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'SoundShare',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    routerConfig: router ?? _router,
    builder: (context, child) {
      final appContent = child ?? const SizedBox.shrink();
      if (!ClerkConfig.isConfigured) return appContent;

      return ClerkAuthBuilder(
        signedInBuilder: (context, authState) =>
            BackendAuthBootstrap(authState: authState, child: appContent),
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
