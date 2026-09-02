import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/nexora/nexora_icons.dart';
import '../../../ui/nexora/nexora_motion.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_surfaces.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/shimmer_loading.dart';
import '../providers/home_provider.dart';
import '../../player/providers/player_provider.dart';
import '../../../data/dto/file_dto.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/song.dart';

/// Home — the listener's entry point.
///
/// Structure mirrors a good hi-fi front panel: identity at the top, four
/// immediate actions, whatever is currently playing, then a calm editorial
/// stack of library sections. Everything is choreographed with a staggered
/// entrance so the screen assembles rather than simply appearing.
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
      body: Stack(
        children: [
          // Ambient light. Sits behind everything and never intercepts taps.
          const Positioned.fill(child: NexoraAurora(intensity: 0.5)),
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recentSongsProvider);
                ref.invalidate(recentlyPlayedProvider);
                ref.invalidate(featuredAlbumsProvider);
                ref.invalidate(favoritesProvider);
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    toolbarHeight: 64,
                    flexibleSpace: const NexoraSliverAppBarBackground(),
                    title: const _BrandLockup(),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () => context.push('/search'),
                        tooltip: 'Search',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                        tooltip: 'Settings',
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 170),
                      child: NexoraStaggeredColumn(
                        children: [
                          const SizedBox(height: 12),
                          const _Greeting(),
                          const SizedBox(height: 26),
                          const _QuickActions(),
                          if (current != null) ...[
                            const SizedBox(height: 30),
                            const _ContinueListening(),
                          ],
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Recently Added',
                            onSeeAll: () => context.go('/library'),
                          ),
                          const SizedBox(height: 14),
                          _RecentSongsRow(asyncSongs: recentSongs),
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Recently Played',
                            onSeeAll: () => context.push('/history'),
                          ),
                          const SizedBox(height: 14),
                          _RecentlyPlayedRow(asyncItems: recentlyPlayed),
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Albums',
                            onSeeAll: () => context.go('/library'),
                          ),
                          const SizedBox(height: 14),
                          _AlbumsGrid(asyncAlbums: albums),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// App identity: mark + wordmark.
class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: AppColors.surfaceRaised.withValues(alpha: 0.9),
            border: Border.all(color: AppColors.border, width: 0.6),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/icon.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => NexoraGlyph(
              kind: NexoraGlyphKind.waveform,
              size: 18,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Text(
          'NEXORA',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

/// Time-aware greeting above the library heading.
class _Greeting extends StatelessWidget {
  const _Greeting();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Still awake';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 22) return 'Good evening';
    return 'Winding down';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NexoraGlyph(
              kind: NexoraGlyphKind.waveform,
              size: 13,
              color: AppColors.accent,
            ),
            const SizedBox(width: 7),
            Text(
              _greeting.toUpperCase(),
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'Your library',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            height: 1.08,
          ),
        ),
      ],
    );
  }
}

/// Four one-tap destinations. Keeps the most common intents one press away
/// instead of buried two screens deep.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(recentSongsProvider);

    void shuffleAll() {
      final songs = songsAsync.value;
      if (songs == null || songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library is still loading — try again shortly.'),
          ),
        );
        return;
      }
      final shuffled = List<Song>.of(songs)..shuffle();
      ref.read(playerProvider.notifier).playSongs(shuffled);
      ref.read(playerProvider.notifier).toggleShuffle();
    }

    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            icon: NexoraGlyph(
              kind: NexoraGlyphKind.waveform,
              size: 20,
              color: AppColors.accent,
            ),
            label: 'Shuffle all',
            onTap: shuffleAll,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icon(
              Icons.favorite_rounded,
              size: 19,
              color: AppColors.accent,
            ),
            label: 'Favorites',
            onTap: () => context.push('/favorites'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: Icon(
              Icons.download_rounded,
              size: 19,
              color: AppColors.accent,
            ),
            label: 'Downloads',
            onTap: () => context.push('/downloads'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            icon: NexoraGlyph(
              kind: NexoraGlyphKind.stats,
              size: 20,
              color: AppColors.accent,
            ),
            label: 'Your stats',
            onTap: () => context.push('/stats'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.66),
          borderRadius: NexoraRadius.chip,
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hero card for whatever is currently loaded in the player.
class _ContinueListening extends ConsumerWidget {
  const _ContinueListening();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final progress = state.duration.inMilliseconds == 0
        ? 0.0
        : (state.position.inMilliseconds / state.duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
    final lossless = track.extras?['lossless'] as bool? ?? false;

    return NexoraGradientCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/player'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ArtworkImage(
                url: track.artUri?.toString(),
                size: 62,
                borderRadius: 8,
                showShadow: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NexoraEqualizerBars(
                          playing: state.isPlaying,
                          barWidth: 2.5,
                          minHeight: 3,
                          maxHeight: 13,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            state.isPlaying ? 'NOW PLAYING' : 'PAUSED',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.artist ?? 'Unknown Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (lossless) ...[
                          const SizedBox(width: 8),
                          const NexoraHiResBadge(
                            label: 'LOSSLESS',
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _HeroPlayButton(isPlaying: state.isPlaying),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlayButton extends ConsumerWidget {
  const _HeroPlayButton({required this.isPlaying});

  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NexoraPressable(
      onTap: () => ref.read(playerProvider.notifier).togglePlay(),
      scale: 0.9,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
            child: child,
          ),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey<bool>(isPlaying),
            color: AppColors.onAccent,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Editorial section heading with an optional "See all" affordance.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label, {this.onSeeAll});

  final String label;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 15,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentSongsRow extends ConsumerWidget {
  const _RecentSongsRow({required this.asyncSongs});

  final AsyncValue<List<Song>> asyncSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncSongs.when(
      data: (songs) {
        if (songs.isEmpty) {
          return const _EmptyHint(
            icon: Icons.music_note_outlined,
            text: 'No songs yet — check your server connection',
          );
        }
        return SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, i) => _SongCard(
              song: songs[i],
              onTap: () => ref
                  .read(playerProvider.notifier)
                  .playSongs(songs, initialIndex: i),
            ),
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 196, width: 140),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(recentSongsProvider),
      ),
    );
  }
}

class _RecentlyPlayedRow extends ConsumerWidget {
  const _RecentlyPlayedRow({required this.asyncItems});

  final AsyncValue asyncItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncItems.when(
      data: (items) {
        final songs = <dynamic>[
          for (final h in items)
            if (h.song != null) h.song,
        ];
        if (songs.isEmpty) {
          return const _EmptyHint(
            icon: Icons.history_rounded,
            text: 'Tracks you play will appear here',
          );
        }
        return SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _SmallSongCard(
              song: songs[i] as Song,
              onTap: () => ref.read(playerProvider.notifier).playSongs([
                songs[i] as Song,
              ]),
            ),
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 164, width: 120),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(recentlyPlayedProvider),
      ),
    );
  }
}

class _AlbumsGrid extends ConsumerWidget {
  const _AlbumsGrid({required this.asyncAlbums});

  final AsyncValue<List<Album>> asyncAlbums;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 16,
      childAspectRatio: 0.78,
    );

    return asyncAlbums.when(
      data: (list) {
        if (list.isEmpty)
          return const _EmptyHint(
            icon: Icons.album_outlined,
            text: 'No albums yet',
          );
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: gridDelegate,
          itemCount: list.length,
          itemBuilder: (context, i) => _AlbumCard(album: list[i]),
        );
      },
      loading: () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: gridDelegate,
        itemCount: 4,
        itemBuilder: (_, _) => ShimmerLoading(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(12),
            ),
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
  const _SongCard({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkImage(
              url: song.effectiveArtwork,
              size: 140,
              borderRadius: 8,
              showShadow: true,
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.displayArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSongCard extends StatelessWidget {
  const _SmallSongCard({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkImage(
              url: song.effectiveArtwork,
              size: 120,
              borderRadius: 8,
              showShadow: true,
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.displayArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: () => _openAlbum(context, album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ArtworkImage(
              url: album.coverUrl,
              borderRadius: 8,
              showShadow: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _openAlbum(BuildContext context, Album album) {
    if (album.id.isEmpty) {
      context.push('/library');
      return;
    }
    final rootId = NexoraFiles.parseRootId(album.id);
    final path = NexoraFiles.parsePath(album.id);
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
  const _EmptyHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textDim, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => ShimmerLoading(
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
