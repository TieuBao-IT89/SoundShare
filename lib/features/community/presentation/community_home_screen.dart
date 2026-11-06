import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../l10n/l10n.dart';
import '../../home/domain/song.dart';
import '../application/community_providers.dart';
import 'community_widgets.dart';

class CommunityHomeScreen extends ConsumerWidget {
  const CommunityHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final home = ref.watch(communityHomeProvider);
    final name = ref.watch(myPublicProfileProvider).valueOrNull?.displayName;
    return AppScaffold(
      child: ListView(
        key: const PageStorageKey('community-home'),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SOUNDSHARE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.search,
                onPressed: () => context.go('/search'),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: t.uploadMusic,
                onPressed: () => context.push('/upload'),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            name?.isNotEmpty == true
                ? name!
                : ref.watch(authSessionProvider)?.name ?? t.accountName,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          Text(
            t.v3Editorial,
            style: const TextStyle(
              color: AppColors.mystic,
              fontSize: 11,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Text(
              t.v3HomeTitle,
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontSize: 42, height: 1.15),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.v3HomeSubtitle,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 32),
          CommunityAsync(
            value: home,
            retry: () => ref.invalidate(communityHomeProvider),
            data: (data) {
              final sections = [
                ('recent', t.v3Recent),
                ('following', t.v3FollowingFeed),
                ('recommended', t.v3ForYou),
                ('newReleases', t.v3NewReleases),
                ('popular', t.v3Trending),
              ];
              final featured = (data['newReleases'] as List)
                  .map((item) => Song.fromJson(Map<String, dynamic>.from(item)))
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featured.isNotEmpty)
                    _EditorialHero(
                      song: featured.first,
                      onPlay: () {
                        ref.read(playbackActionsProvider).playFrom(featured, 0);
                        context.push('/player');
                      },
                    )
                  else ...[
                    const CommunityEmpty(),
                    FilledButton.icon(
                      onPressed: () => context.push('/upload'),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t.uploadMusic),
                    ),
                  ],
                  for (final section in sections)
                    if (((data[section.$1] as List?) ?? []).isNotEmpty) ...[
                      const SizedBox(height: 40),
                      SectionHeading(section.$2),
                      if (section.$1 == 'recommended')
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Text(
                            t.v3RecommendationNote,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Builder(
                        builder: (context) {
                          final songs = (data[section.$1] as List)
                              .map(
                                (item) => Song.fromJson(
                                  Map<String, dynamic>.from(item),
                                ),
                              )
                              .toList();
                          return Column(
                            children: [
                              for (var i = 0; i < songs.length; i++)
                                CommunitySongRow(
                                  song: songs[i],
                                  queue: songs,
                                  index: i,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EditorialHero extends StatelessWidget {
  const _EditorialHero({required this.song, required this.onPlay});
  final Song song;
  final VoidCallback onPlay;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final wide = bounds.maxWidth > 650;
      final image = Artwork(
        url: song.artwork,
        size: wide ? bounds.maxWidth * .48 : bounds.maxWidth,
        height: wide ? 320 : 280,
        radius: 8,
      );
      final detail = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.genre.toUpperCase(),
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(song.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              song.artist,
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(context.l10n.listenNow),
            ),
          ],
        ),
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: wide
            ? Row(
                children: [
                  image,
                  Expanded(child: detail),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [image, detail],
              ),
      );
    },
  );
}
