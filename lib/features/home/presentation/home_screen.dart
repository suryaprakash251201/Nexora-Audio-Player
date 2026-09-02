import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/error_view.dart';
import '../providers/home_provider.dart';
import '../../player/providers/player_provider.dart';
import '../../../data/dto/file_dto.dart';
import '../../../domain/entities/album.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSongs = ref.watch(recentSongsProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final albums = ref.watch(featuredAlbumsProvider);
    final current = ref.watch(playerProvider).currentTrack;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 64,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surfaceRaised,
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.6,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.graphic_eq_rounded,
                          size: 18,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'NEXORA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push('/search'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
              const SizedBox(width: 4),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _Greeting(),
                    const SizedBox(height: 32),
                    if (current != null) ...[
                      _ContinueListening(),
                      const SizedBox(height: 40),
                    ],
                    _SectionTitle('Recently Added'),
                    const SizedBox(height: 16),
                    _RecentSongsRow(asyncSongs: recentSongs, ref: ref),
                    const SizedBox(height: 40),
                    _SectionTitle('Recently Played'),
                    const SizedBox(height: 16),
                    _RecentlyPlayedRow(
                      asyncItems: recentlyPlayed,
                      ref: ref,
                    ),
                    const SizedBox(height: 40),
                    _SectionTitle('Albums'),
                    const SizedBox(height: 16),
                    _AlbumsGrid(asyncAlbums: albums, ref: ref),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  String get _hour {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _hour.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your library',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _ContinueListening extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => context.push('/player'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          children: [
            ArtworkImage(
              url: track.artUri?.toString(),
              size: 64,
              borderRadius: 6,
              showShadow: true,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'CONTINUE LISTENING',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
              child: Icon(
                state.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppColors.onAccent,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSongsRow extends StatelessWidget {
  final AsyncValue asyncSongs;
  final WidgetRef ref;
  const _RecentSongsRow({required this.asyncSongs, required this.ref});

  @override
  Widget build(BuildContext context) {
    return asyncSongs.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const _EmptyHint(
            icon: Icons.music_note_outlined,
            text: 'No songs yet — check server connection',
          );
        }
        return SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (c, i) {
              final s = songs[i];
              return _SongCard(
                song: s,
                onTap: () => ref
                    .read(playerProvider.notifier)
                    .playSongs(songs, initialIndex: i),
              );
            },
          ),
        );
      },
      loading: () => _SkeletonRow(height: 200),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(recentSongsProvider),
      ),
    );
  }
}

class _RecentlyPlayedRow extends StatelessWidget {
  final AsyncValue asyncItems;
  final WidgetRef ref;
  const _RecentlyPlayedRow({required this.asyncItems, required this.ref});

  @override
  Widget build(BuildContext context) {
    return asyncItems.when(
      data: (items) {
        final songs = <dynamic>[
          for (final h in items)
            if (h.song != null) h.song,
        ];
        if (songs.isEmpty) {
          return const _EmptyHint(
            icon: Icons.history_rounded,
            text: 'Played songs will appear here',
          );
        }
        return SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (c, i) {
              return _SmallSongCard(
                song: songs[i],
                onTap: () => ref
                    .read(playerProvider.notifier)
                    .playSongs([songs[i]]),
              );
            },
          ),
        );
      },
      loading: () => _SkeletonRow(height: 168),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(recentlyPlayedProvider),
      ),
    );
  }
}

class _AlbumsGrid extends StatelessWidget {
  final AsyncValue asyncAlbums;
  final WidgetRef ref;
  const _AlbumsGrid({required this.asyncAlbums, required this.ref});

  @override
  Widget build(BuildContext context) {
    return asyncAlbums.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyHint(
            icon: Icons.album_outlined,
            text: 'No albums',
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final a = list[i] as Album;
            return _AlbumCard(album: a);
          },
        );
      },
      loading: () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(featuredAlbumsProvider),
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final dynamic song;
  final VoidCallback onTap;
  const _SongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkImage(
              url: song.coverUrl,
              size: 140,
              borderRadius: 6,
              showShadow: true,
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSongCard extends StatelessWidget {
  final dynamic song;
  final VoidCallback onTap;
  const _SmallSongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkImage(
              url: song.coverUrl,
              size: 120,
              borderRadius: 6,
              showShadow: true,
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (song.artist != null) ...[
              const SizedBox(height: 2),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAlbum(context, album),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ArtworkImage(
              url: album.coverUrl,
              borderRadius: 6,
              showShadow: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${album.artist ?? 'Album'} • ${album.trackCount ?? '—'} tracks',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _openAlbum(BuildContext context, Album album) {
    final id = album.id;
    if (id.isEmpty) {
      context.push('/library');
      return;
    }
    final rootId = NexoraFiles.parseRootId(id);
    final path = NexoraFiles.parsePath(id);
    if (rootId.isEmpty) {
      context.push('/library');
      return;
    }
    context.push(
      Uri(
        path: '/folder',
        queryParameters: {'root': rootId, 'path': path},
      ).toString(),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDim, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  final double height;
  const _SkeletonRow({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: height - 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}