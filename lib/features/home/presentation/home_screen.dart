import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/animations/app_animations.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              pinned: true,
              stretch: true,
              expandedHeight: 140,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background.withValues(alpha: 0.95),
                        AppColors.background.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
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
                      _discoverBanner(context, ref),
                      const SizedBox(height: 32),
                      _quickActions(context),
                      const SizedBox(height: 36),
                      SlideInAnimation(
                        child: const SectionHeader(
                          title: 'Recently Added',
                          leadingIcon: Icons.new_releases_rounded,
                        ),
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
                                height: 250,
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
                                    return SlideInAnimation(
                                      delay: Duration(milliseconds: i * 80),
                                      child: _SongCard(
                                        song: s,
                                        onTap: () => ref
                                            .read(playerProvider.notifier)
                                            .playSongs(songs, initialIndex: i),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        loading: () => const _SongSkeletonList(height: 250),
                        error: (e, _) => ErrorView(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(recentSongsProvider),
                        ),
                      ),
                      const SizedBox(height: 38),
                      SlideInAnimation(
                        child: const SectionHeader(
                          title: 'Recently Played',
                          leadingIcon: Icons.history_rounded,
                          trailing: Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: AppColors.secondaryLight,
                          ),
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
                                height: 180,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 14),
                                  itemBuilder: (c, i) {
                                    final h = items[i];
                                    final song = h.song;
                                    return SlideInAnimation(
                                      delay: Duration(milliseconds: i * 60),
                                      child: _HistoryCard(
                                        song: song,
                                        fallbackId: h.songId,
                                        onTap: song != null
                                            ? () => ref
                                                  .read(playerProvider.notifier)
                                                  .playSongs([song])
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                        loading: () => const _HistorySkeletonList(height: 180),
                        error: (e, _) => ErrorView(
                          message: e.toString(),
                          onRetry: () => ref.invalidate(recentlyPlayedProvider),
                        ),
                      ),
                      const SizedBox(height: 38),
                      SlideInAnimation(
                        child: const SectionHeader(
                          title: 'Featured Albums',
                          leadingIcon: Icons.album_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      albums.when(
                        data: (list) => list.isEmpty
                            ? const EmptyView(
                                title: 'No albums',
                                icon: Icons.album_outlined,
                              )
                            : SizedBox(
                                height: 260,
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
                                    return SlideInAnimation(
                                      delay: Duration(milliseconds: i * 80),
                                      child: _AlbumCard(
                                        album: a,
                                        onTap: () => _openAlbum(context, a),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        loading: () => const _AlbumSkeletonList(height: 260),
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

  Widget _discoverBanner(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentSongsProvider);
    final historyAsync = ref.watch(recentlyPlayedProvider);
    final albumsAsync = ref.watch(featuredAlbumsProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    // Stats — fallback to 0 while loading
    final songCount = recentAsync.value?.length ?? 0;
    final albumCount = albumsAsync.value?.length ?? 0;
    final playedCount = historyAsync.value?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScaleBounce(
        child: EnhancedGlassSurface(
          opacity: 0.32,
          blur: 36,
          borderRadius: BorderRadius.circular(28),
          showShimmer: true,
          showInnerGlow: true,
          glowColor: AppColors.primary,
          glowRadius: 48,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.30),
                  AppColors.secondary.withValues(alpha: 0.18),
                  AppColors.tertiary.withValues(alpha: 0.10),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Decorative orb — top right
                Positioned(
                  right: -30,
                  top: -36,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.10),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Soft bottom glow
                Positioned(
                  left: -20,
                  bottom: -40,
                  child: Container(
                    width: 160,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GlassChip(
                          color: AppColors.primary,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GlowDot(size: 6, color: AppColors.primaryLight),
                              const SizedBox(width: 6),
                              Text(
                                greeting.toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GlassChip(
                          color: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: AppColors.secondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FOR YOU',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Discover your\nnext favourite',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Live stats row
                    Row(
                      children: [
                        _StatPill(
                          icon: Icons.music_note_rounded,
                          label: '$songCount songs',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.album_rounded,
                          label: '$albumCount albums',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          icon: Icons.history_rounded,
                          label: '$playedCount played',
                          color: AppColors.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _HeroButton(
                          label: 'Shuffle all',
                          icon: Icons.shuffle_rounded,
                          onTap: () {
                            final songs = recentAsync.value;
                            if (songs != null && songs.isNotEmpty) {
                              final shuffled = [...songs]..shuffle();
                              ref
                                  .read(playerProvider.notifier)
                                  .playSongs(shuffled);
                            } else {
                              context.push('/library');
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        _HeroGhostButton(
                          label: 'Surprise me',
                          icon: Icons.casino_rounded,
                          onTap: () {
                            final songs = recentAsync.value;
                            if (songs != null && songs.isNotEmpty) {
                              final pick =
                                  ([...songs]..shuffle()).first;
                              ref
                                  .read(playerProvider.notifier)
                                  .playSongs([pick]);
                            } else {
                              context.push('/search');
                            }
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/equalizer'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 0.6,
                              ),
                            ),
                            child: Icon(
                              Icons.equalizer_rounded,
                              color: AppColors.text,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
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
              child: SlideInAnimation(
                delay: Duration(milliseconds: i * 100),
                child: _QuickAction(
                  icon: actions[i].$1,
                  color: actions[i].$2,
                  label: actions[i].$3,
                  onTap: actions[i].$4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Albums are directories on the Nexora server, whose id is "rootId|path".
  /// Open that exact album folder instead of the generic library list.
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

// ═══════════════════════════════════════════════════════════════
// APP BAR CONTENT
// ═══════════════════════════════════════════════════════════════

class _AppBarContent extends StatelessWidget {
  final VoidCallback onSearch;
  const _AppBarContent({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/icon.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.text,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nexora',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.text,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlowDot(size: 5, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Hi-Fi Streaming',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.18),
              accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.6),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: accent, size: 22),
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
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: color.withValues(alpha: 0.35),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.text,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.text, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
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
// STAT PILL (discover banner)

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SONG CARD
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
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  url: song.coverUrl,
                  size: 160,
                  borderRadius: 20,
                  showShadow: true,
                ),
                // Conic gradient rim
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: SweepGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.0),
                            AppColors.secondary.withValues(alpha: 0.4),
                            AppColors.tertiary.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Play overlay pill
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background.withValues(alpha: 0.7),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.text,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              song.artist ?? 'Unknown',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (song.lossless == true) ...[
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              GradientBadge(text: (song.codec as String).toUpperCase()),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HISTORY CARD
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
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  url: song?.coverUrl,
                  size: 120,
                  borderRadius: 16,
                  showShadow: true,
                ),
                if (onTap != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background.withValues(alpha: 0.65),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.6,
                        ),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.text,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              song?.title ?? fallbackId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (song?.artist != null) ...[
              const SizedBox(height: 3),
              Text(
                song.artist as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ALBUM CARD
// ═══════════════════════════════════════════════════════════════

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 170,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ArtworkImage(
                  url: album.coverUrl,
                  size: 170,
                  borderRadius: 20,
                  showShadow: true,
                ),
                if (album.trackCount != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: GlassChip(
                      color: AppColors.primary,
                      child: Text(
                        '${album.trackCount} songs',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              album.artist ?? 'Albums',
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

// ═══════════════════════════════════════════════════════════════
// SKELETON LOADERS
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
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(width: 160, height: 160, borderRadius: 20),
            SizedBox(height: 12),
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
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(width: 120, height: 120, borderRadius: 16),
            SizedBox(height: 10),
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
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerWidget(width: 170, height: 170, borderRadius: 20),
            SizedBox(height: 12),
            ShimmerWidget(width: 120, height: 14, borderRadius: 7),
            SizedBox(height: 6),
            ShimmerWidget(width: 70, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
