import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/glass_surface.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../providers/home_provider.dart';
import '../../player/providers/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSongs = ref.watch(recentSongsProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final albums = ref.watch(featuredAlbumsProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Pure black background for OLED
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.transparent),
              ),
            ),
            pinned: true,
            expandedHeight: 120,
            title: const Text(
              'Listen Now',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, size: 28),
                onPressed: () => context.push('/search'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.account_circle,
                  size: 28,
                  color: AppColors.primary,
                ),
                onPressed: () => context.push('/settings'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentSongsProvider);
                ref.invalidate(recentlyPlayedProvider);
                ref.invalidate(featuredAlbumsProvider);
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _heroBanner(context),
                    ),
                    const SizedBox(height: 36),
                    _sectionTitle(
                      'Recently Added',
                      onSeeAll: () => context.push('/library'),
                    ),
                    const SizedBox(height: 16),
                    recentSongs.when(
                      data: (songs) => songs.isEmpty
                          ? const EmptyView(
                              title: 'No songs',
                              subtitle:
                                  'Pull to refresh or check server connection',
                              icon: Icons.music_note_outlined,
                            )
                          : SizedBox(
                              height: 220,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: songs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (c, i) {
                                  final s = songs[i];
                                  return GestureDetector(
                                    onTap: () => ref
                                        .read(playerProvider.notifier)
                                        .playSongs(songs, initialIndex: i),
                                    child: SizedBox(
                                      width: 140,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ArtworkImage(
                                              url: s.coverUrl,
                                              size: 140,
                                              borderRadius: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            s.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            s.artist ?? 'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                      loading: () =>
                          const SizedBox(height: 220, child: LoadingView()),
                      error: (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(recentSongsProvider),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _sectionTitle('Recently Played'),
                    const SizedBox(height: 16),
                    recentlyPlayed.when(
                      data: (items) => items.isEmpty
                          ? const EmptyView(
                              title: 'No history yet',
                              subtitle: 'Play something to see it here',
                              icon: Icons.history,
                            )
                          : SizedBox(
                              height: 180,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (c, i) {
                                  final h = items[i];
                                  final song = h.song;
                                  return SizedBox(
                                    width: 120,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ArtworkImage(
                                          url: song?.coverUrl,
                                          size: 120,
                                          borderRadius: 12,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          song?.title ?? h.songId,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                      loading: () =>
                          const SizedBox(height: 180, child: LoadingView()),
                      error: (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(recentlyPlayedProvider),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _sectionTitle(
                      'Featured Albums',
                      onSeeAll: () => context.push('/library'),
                    ),
                    const SizedBox(height: 16),
                    albums.when(
                      data: (list) => list.isEmpty
                          ? const EmptyView(
                              title: 'No albums',
                              icon: Icons.album_outlined,
                            )
                          : SizedBox(
                              height: 240,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemBuilder: (c, i) {
                                  final a = list[i];
                                  return SizedBox(
                                    width: 160,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ArtworkImage(
                                            url: a.coverUrl,
                                            size: 160,
                                            borderRadius: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          a.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          a.artist ?? '',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                      loading: () =>
                          const SizedBox(height: 240, child: LoadingView()),
                      error: (e, _) => ErrorView(
                        message: e.toString(),
                        onRetry: () => ref.invalidate(featuredAlbumsProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBanner(BuildContext context) {
    return GlassSurface(
      opacity: 0.3,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.3),
              AppColors.secondary.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Continue Listening',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your audiophile\ncollection awaits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/library'),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Browse Library'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'See all',
              style: TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
