import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/glass_surface.dart';
import '../../../ui/widgets/premium_widgets.dart';
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
      backgroundColor: AppColors.background,
      body: AnimatedGradientBg(
        colors: const [
          AppColors.primary,
          AppColors.secondary,
          Color(0xFF7C3AED),
          AppColors.tertiary,
        ],
        blur: 80,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              pinned: true,
              stretch: true,
              expandedHeight: 128,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background.withValues(alpha: 0.9),
                        AppColors.background.withValues(alpha: 0.0),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              title: _AppBarContent(onSearch: () => context.push('/search')),
              actions: [
                _ActionButton(
                  icon: Icons.settings_rounded,
                  accent: AppColors.secondary,
                  onTap: () => context.push('/settings'),
                ),
                const SizedBox(width: 18),
              ],
            ),
            SliverToBoxAdapter(
              child: RefreshIndicator(
                edgeOffset: 90,
                onRefresh: () async {
                  ref.invalidate(recentSongsProvider);
                  ref.invalidate(recentlyPlayedProvider);
                  ref.invalidate(featuredAlbumsProvider);
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroBanner(context, ref),
                      const SizedBox(height: 30),
                      _quickActions(context),
                      const SizedBox(height: 34),
                      const SectionHeader(
                        title: 'Recently Added',
                        leadingIcon: Icons.new_releases_rounded,
                      ),
                      const SizedBox(height: 16),
                      recentSongs.when(
                        data: (songs) => songs.isEmpty
                            ? const EmptyView(
                                title: 'No songs yet',
                                subtitle:
                                    'Pull to refresh or check server connection',
                                icon: Icons.music_note_outlined,
                              )
                            : SizedBox(
                                height: 236,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: songs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 20),
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
                              ),
                        loading: () => const _SongSkeletonList(height: 236),
                        error: (e, _) => ErrorView(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(recentSongsProvider),
                        ),
                      ),
                      const SizedBox(height: 38),
                      const SectionHeader(
                        title: 'Recently Played',
                        leadingIcon: Icons.history_rounded,
                        trailing: Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.secondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      recentlyPlayed.when(
                        data: (items) => items.isEmpty
                            ? const EmptyView(
                                title: 'No history yet',
                                subtitle: 'Play something to see it here',
                                icon: Icons.history,
                              )
                            : SizedBox(
                                height: 166,
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
                                    return _HistoryCard(
                                      song: song,
                                      fallbackId: h.songId,
                                      onTap: song != null
                                          ? () => ref
                                                .read(playerProvider.notifier)
                                                .playSongs([song])
                                          : null,
                                    );
                                  },
                                ),
                              ),
                        loading: () => const _HistorySkeletonList(height: 166),
                        error: (e, _) => ErrorView(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(recentlyPlayedProvider),
                        ),
                      ),
                      const SizedBox(height: 38),
                      const SectionHeader(
                        title: 'Featured Albums',
                        leadingIcon: Icons.album_rounded,
                      ),
                      const SizedBox(height: 16),
                      albums.when(
                        data: (list) => list.isEmpty
                            ? const EmptyView(
                                title: 'No albums',
                                icon: Icons.album_outlined,
                              )
                            : SizedBox(
                                height: 252,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 20),
                                  itemBuilder: (c, i) {
                                    final a = list[i];
                                    return _AlbumCard(
                                      album: a,
                                      onTap: () => context.push('/library'),
                                    );
                                  },
                                ),
                              ),
                        loading: () => const _AlbumSkeletonList(height: 252),
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
      ),
    );
  }

  // ── Hero "Continue Listening" banner ──────────────────────────
  Widget _heroBanner(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final current = playerState.currentTrack;
    final hasNowPlaying = current != null;
    final isPlaying = playerState.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassSurface(
        opacity: 0.3,
        blur: 45,
        borderRadius: BorderRadius.circular(28),
        showShimmer: true,
        showInnerGlow: true,
        glowColor: hasNowPlaying ? AppColors.secondary : AppColors.primary,
        glowRadius: 40,
        child: Container(
          height: 196,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasNowPlaying
                  ? [
                      AppColors.secondary.withValues(alpha: 0.4),
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.tertiary.withValues(alpha: 0.1),
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.4),
                      AppColors.secondary.withValues(alpha: 0.18),
                      AppColors.tertiary.withValues(alpha: 0.12),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative glowing orb
              Positioned(
                right: -30,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      GlassChip(
                        color: hasNowPlaying
                            ? AppColors.secondary
                            : AppColors.primary,
                        child: Row(
                          children: [
                            GlowDot(
                              size: 6,
                              color: hasNowPlaying
                                  ? AppColors.secondaryLight
                                  : AppColors.primaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hasNowPlaying
                                  ? 'NOW PLAYING'
                                  : 'CONTINUE LISTENING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasNowPlaying && isPlaying) ...[
                        const SizedBox(width: 10),
                        const NowPlayingIndicator(
                          height: 12,
                          width: 12,
                          color: AppColors.secondaryLight,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (hasNowPlaying) ...[
                    Text(
                      current!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current.artist ?? 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Your audiophile\ncollection awaits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroButton(
                        label: hasNowPlaying
                            ? (isPlaying ? 'Pause' : 'Resume')
                            : 'Browse Library',
                        icon: hasNowPlaying
                            ? (isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded)
                            : Icons.library_music_rounded,
                        onTap: hasNowPlaying
                            ? () =>
                                  ref.read(playerProvider.notifier).togglePlay()
                            : () => context.push('/library'),
                      ),
                      if (hasNowPlaying) ...[
                        const SizedBox(width: 12),
                        _HeroGhostButton(
                          label: 'Open Player',
                          icon: Icons.expand_less_rounded,
                          onTap: () => context.push('/player'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick action cards ────────────────────────────────────────
  Widget _quickActions(BuildContext context) {
    final actions = [
      (
        Icons.library_music_rounded,
        AppColors.primary,
        'Library',
        () => context.push('/library'),
      ),
      (
        Icons.queue_music_rounded,
        AppColors.secondary,
        'Playlists',
        () => context.push('/playlists'),
      ),
      (
        Icons.favorite_rounded,
        AppColors.tertiary,
        'Favorites',
        () => context.push('/favorites'),
      ),
      (
        Icons.search_rounded,
        AppColors.success,
        'Search',
        () => context.push('/search'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: actions[i].$1,
                color: actions[i].$2,
                label: actions[i].$3,
                onTap: actions[i].$4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// APP BAR CONTENT — Frosted-glass header
// ═══════════════════════════════════════════════════════════════

class _AppBarContent extends StatelessWidget {
  final VoidCallback onSearch;
  const _AppBarContent({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nexora',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlowDot(size: 5, color: AppColors.success),
                const SizedBox(width: 5),
                const Text(
                  'Hi-Fi Streaming',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _ActionButton(
          icon: Icons.search_rounded,
          accent: AppColors.primary,
          onTap: onSearch,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.16),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.22), width: 0.6),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: accent, size: 21),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK ACTION TILE
// ═══════════════════════════════════════════════════════════════

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 0.6,
                ),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO BUTTONS
// ═══════════════════════════════════════════════════════════════

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroGhostButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _HeroGhostButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SONG CARD — Horizontal scrolling card with live play state
// ═══════════════════════════════════════════════════════════════

class _SongCard extends StatelessWidget {
  final dynamic song;
  final VoidCallback onTap;
  const _SongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  url: song.coverUrl,
                  size: 148,
                  borderRadius: 18,
                  showShadow: true,
                ),
                // Conic gradient rim
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: SweepGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.0),
                            AppColors.secondary.withValues(alpha: 0.35),
                            AppColors.tertiary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Play overlay pill
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background.withValues(alpha: 0.65),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (song.lossless == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const GradientBadge(
                    text: 'LOSSLESS',
                    color: AppColors.secondary,
                  ),
                  if (song.codec != null)
                    GradientBadge(text: (song.codec as String).toUpperCase()),
                ],
              ),
            ] else if (song.codec != null) ...[
              const SizedBox(height: 6),
              GradientBadge(text: (song.codec as String).toUpperCase()),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HISTORY CARD — with ranking pill
// ═══════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final dynamic song;
  final String fallbackId;
  final VoidCallback? onTap;
  const _HistoryCard({
    required this.song,
    required this.fallbackId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 114,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  url: song?.coverUrl,
                  size: 114,
                  borderRadius: 14,
                  showShadow: true,
                ),
                if (onTap != null)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background.withValues(alpha: 0.6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.6,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              song?.title ?? fallbackId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (song?.artist != null) ...[
              const SizedBox(height: 2),
              Text(
                song.artist as String,
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

// ═══════════════════════════════════════════════════════════════
// ALBUM CARD — with gradient count pill
// ═══════════════════════════════════════════════════════════════

class _AlbumCard extends StatelessWidget {
  final dynamic album;
  final VoidCallback onTap;
  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  url: album.coverUrl,
                  size: 160,
                  borderRadius: 18,
                  showShadow: true,
                ),
                if (album.trackCount != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: GlassChip(
                      color: AppColors.primary,
                      child: Text(
                        '${album.trackCount} songs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              album.artist ?? 'Albums',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SKELETON LOADERS — shimmer placeholders matching card dimensions
// ═══════════════════════════════════════════════════════════════

class _SongSkeletonList extends StatelessWidget {
  final double height;
  const _SongSkeletonList({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(width: 148, height: 148, borderRadius: 18),
            SizedBox(height: 10),
            ShimmerWidget(width: 120, height: 14, borderRadius: 7),
            SizedBox(height: 6),
            ShimmerWidget(width: 80, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _HistorySkeletonList extends StatelessWidget {
  final double height;
  const _HistorySkeletonList({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(width: 114, height: 114, borderRadius: 14),
            SizedBox(height: 8),
            ShimmerWidget(width: 90, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _AlbumSkeletonList extends StatelessWidget {
  final double height;
  const _AlbumSkeletonList({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(width: 160, height: 160, borderRadius: 18),
            SizedBox(height: 10),
            ShimmerWidget(width: 120, height: 14, borderRadius: 7),
            SizedBox(height: 6),
            ShimmerWidget(width: 70, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
