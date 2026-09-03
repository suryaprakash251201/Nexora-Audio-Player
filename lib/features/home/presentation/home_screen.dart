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
import '../../../data/api/files_api.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../data/dto/file_dto.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/widgets/playlist_cover.dart';

/// Home — the listener's entry point.
///
/// Audiophile redesign: a confident hero stage (greeting + continue),
/// four adaptive quick-actions with tonal iconography, and three editorial
/// rails (recent, recents played, albums) that build rhythm without
/// flooding the eye. Everything staggered so the screen assembles.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final librarySongs = ref.watch(recentSongsProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final playlists = ref.watch(homePlaylistsProvider);
    final albums = ref.watch(featuredAlbumsProvider);
    final artists = ref.watch(featuredArtistsProvider);
    final folders = ref.watch(homeFoldersProvider);
    final current = ref.watch(playerProvider).currentTrack;
    // Recently Played tracks live in-app playback: the player writes a
    // local history row on every track change, so refresh this rail the
    // moment the song flips (immediate + delayed pass to win the DB
    // write race) instead of waiting for pull-to-refresh.
    ref.listen(playerProvider.select((s) => s.currentTrack?.id), (prev, next) {
      if (prev == next || next == null) return;
      ref.invalidate(recentlyPlayedProvider);
      Future.delayed(const Duration(seconds: 2), () {
        try {
          ref.invalidate(recentlyPlayedProvider);
        } catch (_) {}
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient light. Sits behind everything and never intercepts taps.
          const Positioned.fill(child: NexoraAurora(intensity: 0.45)),
          Positioned.fill(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: () async {
                ref.invalidate(recentSongsProvider);
                ref.invalidate(recentlyPlayedProvider);
                ref.invalidate(homePlaylistsProvider);
                ref.invalidate(featuredAlbumsProvider);
                ref.invalidate(featuredArtistsProvider);
                ref.invalidate(favoritesProvider);
                ref.invalidate(homeFoldersProvider);
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
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: () => context.push('/settings'),
                        tooltip: 'Settings',
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                      child: NexoraStaggeredColumn(
                        children: [
                          const SizedBox(height: 4),
                          const _Greeting(),
                          const SizedBox(height: 24),
                          if (current != null) ...[
                            const _ContinueListening(),
                            const SizedBox(height: 32),
                          ],
                          const _QuickActions(),
                          const SizedBox(height: 34),
                          const _HiFiStats(),
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Playlists',
                            onSeeAll: () => context.go('/playlists'),
                          ),
                          const SizedBox(height: 14),
                          _PlaylistsRow(asyncPlaylists: playlists),
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Recently Played',
                            onSeeAll: () => context.push('/history'),
                          ),
                          const SizedBox(height: 14),
                          _RecentlyPlayedRow(asyncItems: recentlyPlayed),
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Songs',
                            onSeeAll: () => context.go('/library'),
                          ),
                          const SizedBox(height: 14),
                          _HomeSongsRow(asyncSongs: librarySongs),
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Albums',
                            onSeeAll: () => context.go('/library'),
                          ),
                          const SizedBox(height: 14),
                          _AlbumsGrid(asyncAlbums: albums),
                          if (artists.value?.isNotEmpty == true) ...[
                            const SizedBox(height: 34),
                            _SectionHeader(
                              'Artists you follow',
                              onSeeAll: () => context.go('/library'),
                            ),
                            const SizedBox(height: 14),
                            _ArtistsRow(asyncArtists: artists),
                          ],
                          const SizedBox(height: 34),
                          _SectionHeader(
                            'Folders',
                            onSeeAll: () => context.go('/library'),
                          ),
                          const SizedBox(height: 14),
                          _FoldersRow(asyncFolders: folders),
                          const SizedBox(height: 12),
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
            borderRadius: BorderRadius.circular(10),
            color: AppColors.card,
            border: Border.all(color: AppColors.border, width: 0.7),
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
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEXORA',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LOSSLESS READY',
                  style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Time-aware greeting with editorial hero type.
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

  IconData get _greetingIcon {
    final h = DateTime.now().hour;
    if (h < 5) return Icons.nightlight_round;
    if (h < 8) return Icons.wb_twilight_rounded;
    if (h < 12) return Icons.wb_sunny_rounded;
    if (h < 17) return Icons.wb_cloudy_rounded;
    if (h < 22) return Icons.nights_stay_rounded;
    return Icons.bedtime_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_greetingIcon, size: 11, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text(
                      _greeting.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your library',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick up where you left off, or discover something new.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four tonal quick actions — each is a colored chip with its own iconography
/// and brand, sized for thumb reach.
class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(recentSongsProvider);
    final isDark = AppColors.mode == AppThemeMode.dark;

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

    final actions = <_QuickActionData>[
      _QuickActionData(
        icon: Icons.shuffle_rounded,
        label: 'Shuffle all',
        color: AppColors.accent,
        onTap: shuffleAll,
      ),
      _QuickActionData(
        icon: Icons.favorite_rounded,
        label: 'Favorites',
        color: const Color(0xFFFF4D6D),
        onTap: () => context.push('/favorites'),
      ),
      _QuickActionData(
        icon: Icons.download_rounded,
        label: 'Downloads',
        color: const Color(0xFF2EC4B6),
        onTap: () => context.push('/downloads'),
      ),
      _QuickActionData(
        icon: Icons.equalizer_rounded,
        label: 'Equalizer',
        color: const Color(0xFFFFB020),
        onTap: () => context.push('/equalizer'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: [
        for (final a in actions) _QuickActionTile(data: a, isDark: isDark),
      ],
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickActionData data;
  final bool isDark;
  const _QuickActionTile({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = data.color.withValues(alpha: isDark ? 0.13 : 0.10);
    return NexoraPressable(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.border.withValues(alpha: 0.9)
                : AppColors.border,
            width: 0.7,
          ),
          boxShadow: isDark ? null : NexoraShadow.card(false),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: data.color.withValues(alpha: 0.18),
                  width: 0.6,
                ),
              ),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact "session" stats card — total plays, total time, unique artists.
/// Audiophile-focused: no vanity numbers, only context that matters.
class _HiFiStats extends ConsumerWidget {
  const _HiFiStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentlyPlayedProvider);
    final recentsValue = recents.value ?? const [];

    final totalPlays = recentsValue.length;
    final totalSeconds = recentsValue.fold<int>(
      0,
      (s, h) => s + (h.playDuration ?? 0),
    );
    final hours = (totalSeconds / 3600).floor();
    final minutes = ((totalSeconds % 3600) / 60).floor();
    final losslessCount = recentsValue
        .where((h) => h.song?.lossless == true)
        .length;
    final losslessRatio = totalPlays == 0
        ? 0
        : ((losslessCount / totalPlays) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.7),
        boxShadow: AppColors.mode == AppThemeMode.dark
            ? null
            : NexoraShadow.card(false),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'Plays',
              value: totalPlays.toString(),
              accent: AppColors.accent,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatColumn(
              label: 'Time',
              value: hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
              accent: const Color(0xFF2EC4B6),
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatColumn(
              label: 'Lossless',
              value: '$losslessRatio%',
              accent: const Color(0xFFFFB020),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.bar_chart_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            tooltip: 'See full stats',
            onPressed: () => context.push('/stats'),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatColumn({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.7,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.hairline,
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
                size: 64,
                borderRadius: 10,
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
                        Text(
                          state.isPlaying ? 'NOW PLAYING' : 'PAUSED',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
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
                        if (lossless)
                          const NexoraHiResBadge(
                            label: 'LOSSLESS',
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _HeroPlayButton(isPlaying: state.isPlaying),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2.5),
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
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
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
            color: Colors.white,
            size: 27,
          ),
        ),
      ),
    );
  }
}

/// Editorial section heading with an optional "See all" affordance.
class _SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onSeeAll;

  const _SectionHeader(this.label, {this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
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
                      fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

/// Mosaic covers for a Home playlist card (direct cover, else track art).
final _homePlaylistCoversProvider =
    FutureProvider.family<List<String?>, String>((ref, playlistId) async {
      final repo = ref.watch(playlistsRepositoryProvider);
      try {
        final p = await repo.getPlaylist(playlistId);
        final urls = <String?>[];
        if (p.coverUrl != null && p.coverUrl!.isNotEmpty) urls.add(p.coverUrl);
        var tracks = p.tracks ?? const <Song>[];
        if (tracks.isEmpty) {
          try {
            tracks = await repo.getPlaylistTracks(playlistId);
          } catch (_) {}
        }
        for (final t in tracks) {
          final u = t.coverUrl ?? t.artworkUrl;
          if (u != null && u.isNotEmpty) {
            urls.add(u);
            if (urls.length >= 4) break;
          }
        }
        return urls;
      } catch (_) {
        return const <String?>[];
      }
    });

/// Opening rail: playlists first — horizontal mosaic cards.
class _PlaylistsRow extends ConsumerWidget {
  const _PlaylistsRow({required this.asyncPlaylists});

  final AsyncValue<List<Playlist>> asyncPlaylists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncPlaylists.when(
      data: (list) {
        if (list.isEmpty) {
          return const _EmptyHint(
            icon: Icons.queue_music_outlined,
            text: 'No playlists yet — create one from the Playlists tab',
          );
        }
        return SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _HomePlaylistCard(playlist: list[i]),
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 188, width: 140),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(homePlaylistsProvider),
      ),
    );
  }
}

class _HomePlaylistCard extends ConsumerWidget {
  const _HomePlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_homePlaylistCoversProvider(playlist.id));
    final count = playlist.trackCount ?? playlist.tracks?.length ?? 0;
    return NexoraPressable(
      onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: coversAsync.when(
                  data: (urls) => PlaylistCover(
                    artworkUrls: urls,
                    borderRadius: 0,
                    title: playlist.name,
                  ),
                  loading: () => Container(color: AppColors.surfaceRaised),
                  error: (_, __) => PlaylistCover(
                    artworkUrls: const [],
                    borderRadius: 0,
                    title: playlist.name,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$count ${count == 1 ? 'song' : 'songs'}',
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

/// Songs rail — same source as Library → Songs, so Home and Library
/// can never disagree.
class _HomeSongsRow extends ConsumerWidget {
  const _HomeSongsRow({required this.asyncSongs});

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
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _SongCard(
              song: songs[i],
              onTap: () => ref
                  .read(playerProvider.notifier)
                  .playSongs(songs, initialIndex: i),
            ),
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 200, width: 140),
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
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _SmallSongCard(
              song: songs[i] as Song,
              onTap: () => ref.read(playerProvider.notifier).playSongs([
                songs[i] as Song,
              ]),
            ),
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 172, width: 120),
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
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
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

class _ArtistsRow extends ConsumerWidget {
  const _ArtistsRow({required this.asyncArtists});

  final AsyncValue asyncArtists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncArtists.when(
      data: (artists) {
        if (artists.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 122,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: artists.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final a = artists[i];
              return NexoraPressable(
                onTap: () => context.push(
                  '/artist/${Uri.encodeComponent(a.id)}',
                  extra: a,
                ),
                child: SizedBox(
                  width: 96,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipOval(
                        child: ArtworkImage(
                          url: a.artworkUrl,
                          size: 96,
                          borderRadius: 0,
                          showShadow: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 122, width: 96),
      error: (_, __) => const SizedBox.shrink(),
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
              borderRadius: 10,
              showShadow: true,
            ),
            const SizedBox(height: 10),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.displayArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
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
              borderRadius: 10,
              showShadow: true,
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 1),
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
              borderRadius: 10,
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
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${album.artist ?? 'Album'} • ${album.trackCount ?? '—'} tracks',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
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

/// Top-level music folders for the Home rail (cover = image inside folder).
final homeFoldersProvider = FutureProvider<List<_HomeFolderEntry>>((ref) async {
  final api = ref.watch(filesApiProvider);
  final rootId = await api.musicRootId();
  if (rootId == null) return const [];
  final items = await api.list(rootId, '', limit: 200);
  return [
    for (final f in items)
      if (f.isDir)
        _HomeFolderEntry(
          rootId: rootId,
          path: f.path.isEmpty ? f.name : f.path,
          name: f.name,
        ),
  ];
});

class _HomeFolderEntry {
  final String rootId;
  final String path;
  final String name;
  const _HomeFolderEntry({
    required this.rootId,
    required this.path,
    required this.name,
  });
}

final _homeFolderCoverProvider = FutureProvider.family<String?, String>((
  ref,
  folderId,
) async {
  final api = ref.watch(filesApiProvider);
  final idx = folderId.indexOf('|');
  if (idx <= 0) return null;
  try {
    return await api.folderCoverUrl(
      folderId.substring(0, idx),
      folderId.substring(idx + 1),
    );
  } catch (_) {
    return null;
  }
});

/// Horizontal folders rail with cover images (image from inside folder).
class _FoldersRow extends ConsumerWidget {
  const _FoldersRow({required this.asyncFolders});

  final AsyncValue<List<_HomeFolderEntry>> asyncFolders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncFolders.when(
      data: (folders) {
        if (folders.isEmpty) {
          return const _EmptyHint(
            icon: Icons.folder_outlined,
            text: 'No folders yet',
          );
        }
        return SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: folders.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _HomeFolderCard(entry: folders[i]),
          ),
        );
      },
      loading: () => const _SkeletonRow(height: 172, width: 128),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(homeFoldersProvider),
      ),
    );
  }
}

class _HomeFolderCard extends ConsumerWidget {
  const _HomeFolderCard({required this.entry});

  final _HomeFolderEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(
      _homeFolderCoverProvider('${entry.rootId}|${entry.path}'),
    );
    return NexoraPressable(
      onTap: () => context.push(
        Uri(
          path: '/folder',
          queryParameters: {'root': entry.rootId, 'path': entry.path},
        ).toString(),
      ),
      child: SizedBox(
        width: 128,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverAsync.when(
                      data: (url) => url != null && url.isNotEmpty
                          ? Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.surfaceRaised,
                                child: Icon(
                                  Icons.folder_rounded,
                                  color: AppColors.textDim,
                                  size: 36,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceRaised,
                              child: Icon(
                                Icons.folder_rounded,
                                color: AppColors.textDim,
                                size: 36,
                              ),
                            ),
                      loading: () => Container(
                        color: AppColors.surfaceRaised,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => Container(
                        color: AppColors.surfaceRaised,
                        child: Icon(
                          Icons.folder_rounded,
                          color: AppColors.textDim,
                          size: 36,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.7),
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
        padding: const EdgeInsets.symmetric(horizontal: 4),
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
