import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import 'aurora_widgets.dart';
import 'floating_mini_player.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.showMiniPlayer = true,
  });
  final Widget child;
  final bool showMiniPlayer;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = switch (location) {
      '/explore' => 1,
      '/search' => 2,
      '/library' ||
      '/library/search' ||
      '/saved' ||
      '/liked' ||
      '/manage-songs' => 3,
      final path when path.startsWith('/playlists') => 3,
      final path
          when path.startsWith('/profile') ||
              path.startsWith('/u/') ||
              path.startsWith('/connections/') =>
        4,
      _ => 0,
    };
    return LayoutBuilder(
      builder: (context, bounds) {
        final desktop = bounds.maxWidth >= 900;
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: child,
          ),
        );
        return Scaffold(
          body: AuroraBackground(
            child: SafeArea(
              child: desktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AuroraRail(selectedIndex: index),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(child: content),
                              if (showMiniPlayer) const _WideMiniPlayer(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : content,
            ),
          ),
          bottomNavigationBar: desktop
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground.withValues(alpha: .97),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: .6),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showMiniPlayer) const FloatingMiniPlayer(),
                        SoundShareBottomNavigation(selectedIndex: index),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _WideMiniPlayer extends StatelessWidget {
  const _WideMiniPlayer();
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: const FloatingMiniPlayer(),
    ),
  );
}

const _routes = ['/', '/explore', '/search', '/library', '/profile'];
const _icons = [
  Icons.home_outlined,
  Icons.explore_outlined,
  Icons.search_rounded,
  Icons.library_music_outlined,
  Icons.person_outline_rounded,
];
const _selectedIcons = [
  Icons.home_rounded,
  Icons.explore_rounded,
  Icons.search_rounded,
  Icons.library_music_rounded,
  Icons.person_rounded,
];
List<String> _labels(BuildContext context) => [
  context.l10n.home,
  context.l10n.explore,
  context.l10n.search,
  context.l10n.library,
  context.l10n.profile,
];

class SoundShareBottomNavigation extends StatelessWidget {
  const SoundShareBottomNavigation({super.key, required this.selectedIndex});
  final int selectedIndex;
  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
    final large = MediaQuery.textScalerOf(context).scale(11) > 18;
    return SizedBox(
      height: large ? 116 : 82,
      child: Row(
        children: [
          for (var i = 0; i < _routes.length; i++)
            Expanded(
              child: Semantics(
                selected: selectedIndex == i,
                button: true,
                label: labels[i],
                onTap: () => context.go(_routes[i]),
                child: ExcludeSemantics(
                  child: InkWell(
                    onTap: () => context.go(_routes[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selectedIndex == i
                                  ? AppColors.surfaceLight
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              selectedIndex == i
                                  ? _selectedIcons[i]
                                  : _icons[i],
                              size: 23,
                              color: selectedIndex == i
                                  ? AppColors.mystic
                                  : AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Flexible(
                            child: Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selectedIndex == i
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selectedIndex == i
                                    ? AppColors.text
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuroraRail extends StatelessWidget {
  const _AuroraRail({required this.selectedIndex});
  final int selectedIndex;
  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        border: Border(right: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: AuroraLogo(size: 34, wordmark: true),
            ),
            const SizedBox(height: 48),
            Text(
              context.l10n.privateListening,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < _routes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  selected: selectedIndex == i,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: selectedIndex == i ? AppGradients.soft : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: Icon(
                          selectedIndex == i ? _selectedIcons[i] : _icons[i],
                          color: selectedIndex == i
                              ? AppColors.cyan
                              : AppColors.secondaryText,
                        ),
                        title: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selectedIndex == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        onTap: () => context.go(_routes[i]),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            GradientButton(
              label: context.l10n.uploadMusic,
              icon: Icons.add_rounded,
              onPressed: () => context.push('/upload'),
            ),
            const SizedBox(height: 40),
            Text(
              context.l10n.brandTagline,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
