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
      appBar: AppBar(
        title: const Text('Good Evening'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => context.push('/settings')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentSongsProvider);
          ref.invalidate(recentlyPlayedProvider);
          ref.invalidate(featuredAlbumsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 100),
          children: [
            _heroBanner(context),
            const SizedBox(height: 24),
            _sectionTitle('Recently Added', onSeeAll: () => context.push('/library')),
            const SizedBox(height: 12),
            recentSongs.when(
              data: (songs) => songs.isEmpty
                  ? const EmptyView(title: 'No songs', subtitle: 'Pull to refresh or check server connection', icon: Icons.music_note_outlined)
                  : SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: songs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (c, i) {
                          final s = songs[i];
                          return GestureDetector(
                            onTap: () => ref.read(playerProvider.notifier).playSongs(songs, initialIndex: i),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ArtworkImage(url: s.coverUrl, size: 120, borderRadius: 12),
                                const SizedBox(height: 8),
                                SizedBox(width: 120, child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
                                SizedBox(width: 120, child: Text(s.artist ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const SizedBox(height: 180, child: LoadingView()),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(recentSongsProvider)),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Recently Played'),
            const SizedBox(height: 12),
            recentlyPlayed.when(
              data: (items) => items.isEmpty
                  ? const EmptyView(title: 'No history yet', subtitle: 'Play something to see it here', icon: Icons.history)
                  : SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (c, i) {
                          final h = items[i];
                          final song = h.song;
                          return Container(
                            width: 140,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ArtworkImage(url: song?.coverUrl, size: 56, borderRadius: 8),
                                const Spacer(),
                                Text(song?.title ?? h.songId, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                Text(song?.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const SizedBox(height: 80, child: LoadingView()),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(recentlyPlayedProvider)),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Featured Albums', onSeeAll: () => context.push('/library')),
            const SizedBox(height: 12),
            albums.when(
              data: (list) => list.isEmpty
                  ? const EmptyView(title: 'No albums', icon: Icons.album_outlined)
                  : SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (c, i) {
                          final a = list[i];
                          return Column(
                            children: [
                              ArtworkImage(url: a.coverUrl, size: 120, borderRadius: 12),
                              const SizedBox(height: 8),
                              SizedBox(width: 120, child: Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12))),
                              SizedBox(width: 120, child: Text(a.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                            ],
                          );
                        },
                      ),
                    ),
              loading: () => const SizedBox(height: 120, child: LoadingView()),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(featuredAlbumsProvider)),
            ),
          ],
        ),
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
          gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.2)]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Continue Listening', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('Your audiophile\ncollection awaits', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1)),
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: () => context.push('/library'), icon: const Icon(Icons.play_arrow, size: 18), label: const Text('Browse Library')),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const Spacer(),
        if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all', style: TextStyle(color: AppColors.primary, fontSize: 12))),
      ],
    );
  }
}
