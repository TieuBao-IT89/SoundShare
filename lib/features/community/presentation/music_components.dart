import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/artwork.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';
import 'recommendation_copy.dart';

class FeaturedMusic extends ConsumerStatefulWidget {
  const FeaturedMusic({super.key, required this.songs});
  final List<Song> songs;
  @override
  ConsumerState<FeaturedMusic> createState() => _FeaturedMusicState();
}

class _FeaturedMusicState extends ConsumerState<FeaturedMusic>
    with WidgetsBindingObserver {
  static const _slideInterval = Duration(seconds: 5);
  int page = 0;
  final controller = PageController();
  Timer? _slideTimer;
  bool _motionEnabled = false;
  bool _hovered = false;
  bool _focused = false;
  bool _scrolling = false;
  final _pointers = <int>{};

  int get _pageCount => widget.songs.take(3).length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionEnabled =
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _restartSlideTimer();
  }

  @override
  void didUpdateWidget(covariant FeaturedMusic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songs.take(3).length == _pageCount) return;
    if (page >= _pageCount) {
      page = _pageCount == 0 ? 0 : _pageCount - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.hasClients) controller.jumpToPage(page);
      });
    }
    _restartSlideTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _restartSlideTimer();
  }

  void _restartSlideTimer() {
    _slideTimer?.cancel();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (!_motionEnabled ||
        _pageCount < 2 ||
        _hovered ||
        _focused ||
        _scrolling ||
        _pointers.isNotEmpty ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
      return;
    }
    _slideTimer = Timer(_slideInterval, () {
      if (!mounted || !controller.hasClients) return;
      _goToPage((page + 1) % _pageCount);
    });
  }

  void _goToPage(int target) {
    _restartSlideTimer();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpToPage(target);
      return;
    }
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) {
      _scrolling = true;
      _restartSlideTimer();
    } else if (notification is ScrollEndNotification) {
      _scrolling = false;
      _restartSlideTimer();
    }
    return false;
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.songs.take(3).toList();
    if (songs.isEmpty) return const CommunityEmpty();
    final height = MediaQuery.textScalerOf(context).scale(24) > 36
        ? 520.0
        : context.colors.isDark
        ? 250.0
        : 330.0;
    return MouseRegion(
      onEnter: (_) {
        _hovered = true;
        _restartSlideTimer();
      },
      onExit: (_) {
        _hovered = false;
        _restartSlideTimer();
      },
      child: Focus(
        onFocusChange: (focused) {
          _focused = focused;
          _restartSlideTimer();
        },
        child: Listener(
          onPointerDown: (event) {
            _pointers.add(event.pointer);
            _restartSlideTimer();
          },
          onPointerUp: (event) {
            _pointers.remove(event.pointer);
            _restartSlideTimer();
          },
          onPointerCancel: (event) {
            _pointers.remove(event.pointer);
            _restartSlideTimer();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: Column(
              children: [
                SizedBox(
                  height: height,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: songs.length,
                    onPageChanged: (value) => setState(() => page = value),
                    itemBuilder: (context, i) => !context.colors.isDark
                        ? _PearlFeaturedSong(
                            song: songs[i],
                            onPlay: () {
                              ref
                                  .read(playbackActionsProvider)
                                  .playFrom(widget.songs, i);
                              context.push('/player');
                            },
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                LayoutBuilder(
                                  builder: (context, bounds) => Artwork(
                                    url: songs[i].artwork,
                                    size: bounds.maxWidth,
                                    height: height,
                                    radius: 0,
                                  ),
                                ),
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xF20F1220),
                                        Color(0xB0181C2C),
                                        Color(0x180F1220),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 560,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.v4Featured,
                                            style: TextStyle(
                                              color: context.colors.accentText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            songs[i].title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            songs[i].artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color:
                                                  context.colors.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          FilledButton.icon(
                                            onPressed: () {
                                              ref
                                                  .read(playbackActionsProvider)
                                                  .playFrom(widget.songs, i);
                                              context.push('/player');
                                            },
                                            icon: const Icon(
                                              Icons.play_arrow_rounded,
                                            ),
                                            label: Text(context.l10n.listenNow),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                if (songs.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < songs.length; i++)
                        Semantics(
                          selected: page == i,
                          child: IconButton(
                            tooltip: context.l10n.v4FeaturedPosition(
                              i + 1,
                              songs.length,
                            ),
                            onPressed: () => _goToPage(i),
                            icon: Container(
                              width: page == i ? 24 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: page == i
                                    ? context.colors.cyan
                                    : context.colors.secondaryText,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PearlFeaturedSong extends StatelessWidget {
  const _PearlFeaturedSong({required this.song, required this.onPlay});
  final Song song;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: context.colors.featuredGradient,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.colors.border),
    ),
    child: LayoutBuilder(
      builder: (context, bounds) {
        final wide = bounds.maxWidth >= 620;
        final largeText = MediaQuery.textScalerOf(context).scale(14) > 22;
        final artSize = wide
            ? 218.0
            : largeText
            ? 64.0
            : 96.0;
        final artwork = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: context.colors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Artwork(
            url: song.artwork,
            size: artSize,
            radius: 18,
            semanticLabel: context.l10n.artworkFor(song.title),
          ),
        );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.v4Featured,
                    style: TextStyle(
                      color: context.colors.accentText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!wide) ...[const SizedBox(width: 12), artwork],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              song.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontSize: wide ? 32 : 24),
            ),
            const SizedBox(height: 6),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.colors.secondaryText),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(context.l10n.listenNow),
            ),
          ],
        );
        return Padding(
          padding: EdgeInsets.all(wide ? 32 : 20),
          child: wide
              ? Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 32),
                    artwork,
                  ],
                )
              : copy,
        );
      },
    ),
  );
}

class SongArtworkRail extends ConsumerWidget {
  const SongArtworkRail({
    super.key,
    required this.songs,
    this.showRecommendationReasons = false,
  });
  final List<Song> songs;
  final bool showRecommendationReasons;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    height:
        220 +
        MediaQuery.textScalerOf(context).scale(60) * 1.4 +
        (showRecommendationReasons &&
                songs.any((song) => song.recommendationReason != null)
            ? 8 + MediaQuery.textScalerOf(context).scale(11) * 1.4 * 3
            : 0),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: songs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 20),
      itemBuilder: (context, i) => SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref.read(playbackActionsProvider).playFrom(songs, i);
                    context.push('/player');
                  },
                  child: Artwork(
                    url: songs[i].artwork,
                    size: 168,
                    radius: 12,
                    semanticLabel: context.l10n.playSong(songs[i].title),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Material(
                    color: context.colors.secondaryBackground.withValues(
                      alpha: .9,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    child: SongActionMenu(song: songs[i]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              songs[i].title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
            if (songs[i].username != null)
              Text(
                songs[i].artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colors.secondaryText,
                  fontSize: 12,
                ),
              ),
            if (songs[i].username != null)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => context.push(
                  '/u/${Uri.encodeComponent(songs[i].username!)}',
                ),
                child: Text(
                  '@${songs[i].username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  songs[i].artist,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ),
            if (showRecommendationReasons &&
                songs[i].recommendationReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Tooltip(
                  message: recommendationReasonLabel(
                    context.l10n,
                    songs[i].recommendationReason!,
                  ),
                  child: Text(
                    recommendationReasonLabel(
                      context.l10n,
                      songs[i].recommendationReason!,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.secondaryText,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class ChartSpotlight extends ConsumerWidget {
  const ChartSpotlight({super.key, required this.songs});
  final List<Song> songs;
  @override
  Widget build(BuildContext context, WidgetRef ref) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 22;
      final width = bounds.maxWidth >= 840 && !large
          ? (bounds.maxWidth - 32) / 3
          : 220.0;
      return SizedBox(
        height: large ? 510 : 334,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: songs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: (context, i) => SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    InkWell(
                      onTap: () {
                        ref.read(playbackActionsProvider).playFrom(songs, i);
                        context.push('/player');
                      },
                      child: Artwork(
                        url: songs[i].artwork,
                        size: width,
                        height: 156,
                        radius: 12,
                        semanticLabel: context.l10n.playSong(songs[i].title),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${i + 1}'.padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 32,
                            height: 1.1,
                            color: context.colors.mystic,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: context.colors.secondaryBackground,
                        borderRadius: BorderRadius.circular(24),
                        child: SongActionMenu(song: songs[i]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  songs[i].title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  songs[i].artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${songs[i].validPlays} ${context.l10n.v3Views} · ${songs[i].likeCount} ${context.l10n.v3Likes}',
                  style: TextStyle(
                    color: context.colors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SongColumns extends StatelessWidget {
  const SongColumns({super.key, required this.songs, this.ranked = false});
  final List<Song> songs;
  final bool ranked;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 22;
      final columns = !large && bounds.maxWidth >= 1120
          ? 3
          : !large && bounds.maxWidth >= 720
          ? 2
          : 1;
      final width = (bounds.maxWidth - (columns - 1) * 24) / columns;
      return Wrap(
        spacing: 24,
        runSpacing: 4,
        children: [
          for (var i = 0; i < songs.length; i++)
            SizedBox(
              width: width,
              child: CommunitySongRow(
                song: songs[i],
                queue: songs,
                index: i,
                rank: ranked ? i + 1 : null,
                showStats: ranked,
              ),
            ),
        ],
      );
    },
  );
}

class CreatorRail extends StatelessWidget {
  const CreatorRail({super.key, required this.profiles});
  final List<PublicProfile> profiles;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(14) > 22 ? 460 : 270,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (context, i) => SizedBox(
        width: MediaQuery.textScalerOf(context).scale(14) > 22 ? 250 : 186,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.push(
                    '/u/${Uri.encodeComponent(profiles[i].username!)}',
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Artwork(url: profiles[i].avatar, size: 64, radius: 40),
                      const SizedBox(height: 12),
                      Text(
                        profiles[i].displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '@${profiles[i].username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${profiles[i].followers} ${context.l10n.v3Followers}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.secondaryText,
                  ),
                ),
                const SizedBox(height: 8),
                FollowButton(profile: profiles[i]),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class GenreTiles extends StatelessWidget {
  const GenreTiles({
    super.key,
    required this.genres,
    required this.onSelect,
    this.selected,
  });
  final List<String> genres;
  final ValueChanged<String> onSelect;
  final String? selected;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final count = bounds.maxWidth >= 900
          ? 4
          : bounds.maxWidth >= 560
          ? 3
          : 2;
      final width = (bounds.maxWidth - (count - 1) * 12) / count;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < genres.length; i++)
            SizedBox(
              width: width,
              child: Material(
                color: context.colors.isDark
                    ? (i.isEven
                          ? context.colors.surface
                          : context.colors.secondaryBackground)
                    : const [
                        Color(0xFFEFEAFF),
                        Color(0xFFE6F5F5),
                        Color(0xFFE8F0FF),
                        Color(0xFFFFF2E8),
                      ][i % 4],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected == genres[i]
                        ? context.colors.cyan
                        : context.colors.border,
                  ),
                ),
                child: InkWell(
                  onTap: () => onSelect(genres[i]),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          [
                            Icons.graphic_eq_rounded,
                            Icons.album_outlined,
                            Icons.waves_rounded,
                            Icons.piano_outlined,
                          ][i % 4],
                          color: i.isEven
                              ? context.colors.cyan
                              : context.colors.mystic,
                          size: 28,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          genres[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class ContentTabs extends StatelessWidget {
  const ContentTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.icons = const {},
  });
  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onSelected;
  final Map<String, IconData> icons;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: icons[item.$1] == null
                  ? null
                  : Icon(
                      icons[item.$1],
                      size: 18,
                      color: selected == item.$1
                          ? context.colors.primary
                          : context.colors.secondaryText,
                    ),
              showCheckmark: icons.isEmpty ? null : false,
              shape: icons.isEmpty ? null : const StadiumBorder(),
              label: Text(item.$2),
              selected: selected == item.$1,
              onSelected: (_) => onSelected(item.$1),
            ),
          ),
      ],
    ),
  );
}
