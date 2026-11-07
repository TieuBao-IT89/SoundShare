import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/config/clerk_config.dart';
import '../core/config/app_mode.dart';
import '../core/services/api_client.dart';
import '../features/auth/presentation/web_auth_stub.dart'
    if (dart.library.js_interop) '../features/auth/presentation/web_auth.dart';
import '../features/auth/presentation/session_scope.dart';
import '../features/auth/presentation/native_auth_screen.dart';
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
import '../features/community/presentation/discover_screen.dart';
import '../features/community/presentation/community_search_screen.dart';
import '../features/community/presentation/public_profile_screen.dart';
import '../features/community/presentation/profile_editor_screen.dart';
import '../features/community/presentation/playlists_screen.dart';
import '../features/community/presentation/manage_songs_screen.dart';
import '../features/community/application/community_providers.dart';
import '../features/community/presentation/queue_screen.dart';
import '../features/shorts/presentation/shorts_screen.dart';
import '../features/notifications/presentation/notification_center.dart';
import '../l10n/l10n.dart';
import '../core/widgets/aurora_widgets.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_bridge_stub.dart'
    if (dart.library.js_interop) 'theme/theme_bridge_web.dart';

GoRouter createAppRouter({String initialLocation = '/splash'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/shorts', builder: (context, state) => const ShortsScreen()),
    GoRoute(
      path: '/shorts/:id',
      builder: (context, state) => ShortsScreen(
        songId: state.pathParameters['id'],
        openComments: state.uri.queryParameters['comments'] == '1',
        commentId: state.uri.queryParameters['comment'],
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationCenter(),
    ),
    GoRoute(
      path: '/notifications/preferences',
      builder: (context, state) => const NotificationPreferencesScreen(),
    ),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/queue', builder: (context, state) => const QueueScreen()),
    GoRoute(
      path: '/library/search',
      builder: (context, state) => ExploreScreen(
        privateLibrary: true,
        filters: DiscoveryFilters.fromUri(state.uri),
      ),
    ),
    GoRoute(
      path: '/liked',
      builder: (context, state) => const SavedTracksScreen(liked: true),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => shell,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => Consumer(
                builder: (context, ref, _) => ref.watch(demoModeProvider)
                    ? ExploreScreen(
                        filters: DiscoveryFilters.fromUri(state.uri),
                      )
                    : DiscoverScreen(
                        initialGenre: state.uri.queryParameters['genre'],
                      ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => Consumer(
                builder: (context, ref, _) => ref.watch(demoModeProvider)
                    ? ExploreScreen(
                        filters: DiscoveryFilters.fromUri(state.uri),
                      )
                    : CommunitySearchScreen(
                        initialQuery: state.uri.queryParameters['q'] ?? '',
                      ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/player',
      pageBuilder: (context, state) =>
          _auroraPage(context, state, const PlayerScreen()),
    ),
    GoRoute(
      path: '/upload',
      builder: (context, state) => Consumer(
        builder: (context, ref, _) => UploadScreen(
          onUpload: ref.watch(demoModeProvider)
              ? null
              : (draft) async {
                  await ref.read(songRepositoryProvider).upload(draft);
                  ref.invalidate(catalogProvider);
                  ref.invalidate(communityHomeProvider);
                  ref.invalidate(communitySongsProvider);
                  ref.invalidate(myPublicProfileProvider);
                },
        ),
      ),
    ),
    GoRoute(
      path: '/u/:username',
      builder: (context, state) =>
          PublicProfileScreen(username: state.pathParameters['username']!),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const ProfileEditorScreen(),
    ),
    GoRoute(
      path: '/connections/:id/:kind',
      builder: (context, state) => ConnectionsScreen(
        id: state.pathParameters['id']!,
        kind: state.pathParameters['kind']!,
      ),
    ),
    GoRoute(
      path: '/playlists',
      builder: (context, state) => const PlaylistsScreen(),
    ),
    GoRoute(
      path: '/playlists/:id',
      builder: (context, state) =>
          PlaylistScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/saved',
      builder: (context, state) => const SavedTracksScreen(),
    ),
    GoRoute(
      path: '/manage-songs',
      builder: (context, state) => const ManageSongsScreen(),
    ),
  ],
);

final _router = createAppRouter();

CustomTransitionPage<void> _auroraPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 280),
  reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 220),
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
);

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
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ref.watch(themeModeProvider),
    themeAnimationDuration: Duration.zero,
    routerConfig: router ?? _router,
    builder: (context, child) {
      final mode = ref.watch(themeModeProvider);
      syncBrowserTheme(mode.name);
      final dark = Theme.of(context).brightness == Brightness.dark;
      final appContent = child ?? const SizedBox.shrink();
      Widget gatedContent() {
        if (!authenticationRequired || ref.watch(demoModeProvider)) {
          return appContent;
        }
        if (!ClerkConfig.isConfigured) {
          return Scaffold(
            body: AuroraBackground(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    context.l10n.signInNotConfigured,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
        if (kIsWeb) return WebAuthGate(child: appContent);

        return ClerkAuthBuilder(
          signedInBuilder: (context, authState) => SessionScope(
            key: ValueKey((authState.user!.id, authState.session?.id)),
            session: AuthSession(
              subject: authState.user!.id,
              sessionId: authState.session?.id,
              name: authState.user!.hasName
                  ? authState.user!.name
                  : authState.user!.username ?? context.l10n.accountName,
            ),
            token: ({bool refresh = false}) async {
              if (refresh) await authState.refreshClient();
              final active = authState.session;
              if (active == null ||
                  !active.isActive ||
                  !DateTime.now().isBefore(active.expireAt)) {
                throw const ApiException(401, 'UNAUTHORIZED');
              }
              return (await authState.sessionToken()).jwt;
            },
            signOut: authState.signOut,
            child: appContent,
          ),
          signedOutBuilder: (context, _) => const NativeAuthScreen(),
        );
      }

      return ThemePreferenceScope(
        mode: mode,
        select: ref.read(themeModeProvider.notifier).select,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: context.colors.secondaryBackground,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: gatedContent(),
        ),
      );
    },
  );
}
