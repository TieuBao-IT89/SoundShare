import 'theme_mode_menu.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';
import '../../features/community/application/community_providers.dart';
import '../../l10n/l10n.dart';
import '../config/app_mode.dart';
import '../services/audio_service.dart';
import 'artwork.dart';
import 'aurora_widgets.dart';
import 'floating_mini_player.dart';
import 'listening_panel.dart';
import 'playback_dock.dart';
import 'soundshare_search_field.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.showMiniPlayer = true,
  });
  final Widget child;
  final bool showMiniPlayer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        final desktop = bounds.maxWidth >= 1100,
            tablet = bounds.maxWidth >= 768;
        final panel =
            bounds.maxWidth >= 1360 &&
            ref.watch(queuePanelVisibleProvider) &&
            ref.watch(hasSelectedSongProvider);
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1560),
            child: child,
          ),
        );
        return Scaffold(
          onEndDrawerChanged: (open) {
            if (!open && bounds.maxWidth < 1360) {
              ref.read(queuePanelVisibleProvider.notifier).state = false;
            }
          },
          endDrawer: tablet && !panel && ref.watch(hasSelectedSongProvider)
              ? Drawer(
                  width: 340,
                  child: SafeArea(
                    child: ListeningPanel(
                      onClose: () {
                        ref.read(queuePanelVisibleProvider.notifier).state =
                            false;
                        Navigator.pop(context);
                      },
                    ),
                  ),
                )
              : null,
          body: Material(
            color: context.colors.background,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  if (tablet)
                    _Navigation(selectedIndex: index, compact: !desktop),
                  Expanded(
                    child: Column(
                      children: [
                        if (tablet) const _Topbar(),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                  if (panel)
                    SizedBox(
                      width: 310,
                      child: ListeningPanel(
                        onClose: () =>
                            ref.read(queuePanelVisibleProvider.notifier).state =
                                false,
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: tablet
              ? _DockWithQueueDrawer(showDock: showMiniPlayer)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.secondaryBackground,
                    border: Border(
                      top: BorderSide(color: context.colors.border),
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

class _DockWithQueueDrawer extends ConsumerStatefulWidget {
  const _DockWithQueueDrawer({required this.showDock});
  final bool showDock;
  @override
  ConsumerState<_DockWithQueueDrawer> createState() =>
      _DockWithQueueDrawerState();
}

class _DockWithQueueDrawerState extends ConsumerState<_DockWithQueueDrawer> {
  bool? lastDrawerMode, lastActive;

  void syncDrawer(bool open) {
    if (open &&
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.of(context)?.isCurrent == true &&
        MediaQuery.sizeOf(context).width < 1360 &&
        ref.read(hasSelectedSongProvider)) {
      final scaffold = Scaffold.of(context);
      if (!scaffold.isEndDrawerOpen) scaffold.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(queuePanelVisibleProvider, (_, open) => syncDrawer(open));
    final drawerMode = MediaQuery.sizeOf(context).width < 1360;
    final active = TickerMode.valuesOf(context).enabled;
    if (lastDrawerMode != drawerMode || lastActive != active) {
      lastDrawerMode = drawerMode;
      lastActive = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) syncDrawer(ref.read(queuePanelVisibleProvider));
      });
    }
    return widget.showDock ? const PlaybackDock() : const SizedBox.shrink();
  }
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
    final labels = _labels(context),
        large = MediaQuery.textScalerOf(context).scale(11) > 18;
    return SizedBox(
      height: large ? 112 : 72,
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
                              horizontal: 15,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selectedIndex == i
                                  ? context.colors.selected
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              selectedIndex == i
                                  ? _selectedIcons[i]
                                  : _icons[i],
                              size: 22,
                              color: selectedIndex == i
                                  ? context.colors.mystic
                                  : context.colors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
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
                                    ? context.colors.text
                                    : context.colors.secondaryText,
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

class _Navigation extends StatelessWidget {
  const _Navigation({required this.selectedIndex, required this.compact});
  final int selectedIndex;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final labels = _labels(context), t = context.l10n;
    return SizedBox(
      width: compact ? 80 : 224,
      child: Material(
        color: context.colors.secondaryBackground,
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 16,
            vertical: 24,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AuroraLogo(size: 30, wordmark: !compact),
            ),
            const SizedBox(height: 32),
            for (var i = 0; i < _routes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Semantics(
                  selected: selectedIndex == i,
                  child: compact
                      ? IconButton(
                          tooltip: labels[i],
                          isSelected: selectedIndex == i,
                          onPressed: () => context.go(_routes[i]),
                          icon: Icon(_icons[i]),
                          selectedIcon: Icon(_selectedIcons[i]),
                        )
                      : ListTile(
                          selected: selectedIndex == i,
                          selectedTileColor: context.colors.selected,
                          selectedColor: context.colors.mystic,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            selectedIndex == i ? _selectedIcons[i] : _icons[i],
                            size: 22,
                          ),
                          title: Text(
                            labels[i],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => context.go(_routes[i]),
                        ),
                ),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            for (final item in [
              (Icons.favorite_border_rounded, t.likedTracks, '/liked'),
              (Icons.queue_music_rounded, t.v3Playlists, '/playlists'),
            ])
              compact
                  ? IconButton(
                      tooltip: item.$2,
                      onPressed: () => context.push(item.$3),
                      icon: Icon(item.$1),
                    )
                  : ListTile(
                      dense: true,
                      leading: Icon(item.$1, size: 20),
                      title: Text(
                        item.$2,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => context.push(item.$3),
                    ),
            const SizedBox(height: 24),
            if (compact)
              IconButton(
                tooltip: t.uploadMusic,
                onPressed: () => context.push('/upload'),
                icon: const Icon(Icons.add_rounded),
              )
            else
              FilledButton.icon(
                onPressed: () => context.push('/upload'),
                icon: const Icon(Icons.add_rounded),
                label: Text(t.uploadMusic),
              ),
          ],
        ),
      ),
    );
  }
}

class _Topbar extends ConsumerStatefulWidget {
  const _Topbar();
  @override
  ConsumerState<_Topbar> createState() => _TopbarState();
}

class _TopbarState extends ConsumerState<_Topbar> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final hasPageSearch =
        path == '/search' ||
        path == '/library/search' ||
        (path == '/explore' && ref.watch(demoModeProvider));
    final avatar = ref.watch(demoModeProvider)
        ? ''
        : ref.watch(myPublicProfileProvider).valueOrNull?.avatar ?? '';
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (context.canPop())
            IconButton(
              tooltip: context.l10n.back,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: hasPageSearch
                    ? Text(
                        context.l10n.search,
                        style: TextStyle(
                          color: context.colors.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : SoundShareSearchField(
                        key: const ValueKey('global-search'),
                        controller: searchController,
                        compact: true,
                        enableShortcut: true,
                        hintText: context.l10n.v3SearchHint,
                        onSubmitted: (value) => context.go(
                          Uri(
                            path: '/search',
                            queryParameters: {'q': value.trim()},
                          ).toString(),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const ThemeModeMenu(),
          IconButton(
            tooltip: context.l10n.uploadMusic,
            onPressed: () => context.push('/upload'),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: context.l10n.profile,
            child: InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Artwork(url: avatar, size: 40, radius: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
