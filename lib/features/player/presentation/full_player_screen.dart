import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, ProcessingState;

import '../../../data/api/audio_api.dart';
import '../../../data/api/lyrics_api.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_seek_bar.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/nexora/player_visual_mode_provider.dart';
import '../../../ui/theme.dart';
import '../../../ui/theme_provider.dart';
import '../../../ui/widgets/animated_cover.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/connectivity_banner.dart';
import '../../../ui/widgets/lyrics_display.dart';
import '../../../ui/widgets/vinyl_disc.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';
import '../providers/player_provider.dart';
import '../providers/sleep_timer_provider.dart';
import 'cassette_player.dart';

/// Full Player — audiophile redesign.
///
/// - Adaptive gradient background derived from track + blurred artwork
/// - Gradient timeline (seek bar)
/// - Redesigned tactile controls (all wired, haptics, buffering)
/// - Visual modes: modern / vinyl / cassette / minimal (all working)
/// - Round vinyl disc with cover-photo fill
/// - Horizontal swipe to change track, vertical swipe to dismiss/queue
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});
  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  bool _showLyrics = false;
  // Swipe-start anchor so horizontal vs vertical intent is robust.
  Offset? _dragStart;
  static const double _hVelocity = 280;

  @override
  Widget build(BuildContext context) {
    // OPTIMIZED: selective watches — 1Hz position ticks only rebuild
    // the seek bar (_LiveSeekBar), not artwork/controls/background.
    final notifier = ref.read(playerProvider.notifier);
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));
    final mode = ref.watch(playerVisualModeProvider);
    // Keep legacy provider in sync (settings screen reads it).
    final legacyStyle = ref.watch(playerVisualStyleProvider);
    if (legacyStyle.name != mode.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(playerVisualStyleProvider.notifier)
            .set(
              PlayerVisualStyle.values.firstWhere(
                (e) => e.name == mode.name,
                orElse: () => PlayerVisualStyle.modern,
              ),
            );
      });
    }

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Nothing playing',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final isBuffering = ref.watch(
      playerProvider.select(
        (s) =>
            s.processingState == ProcessingState.buffering ||
            s.processingState == ProcessingState.loading,
      ),
    );
    final shuffleEnabled = ref.watch(
      playerProvider.select((s) => s.shuffleEnabled),
    );
    final repeatMode = ref.watch(playerProvider.select((s) => s.repeatMode));
    final volume = ref.watch(playerProvider.select((s) => s.volume));
    final speed = ref.watch(playerProvider.select((s) => s.playbackSpeed));
    // Position/duration only needed for the lyrics overlay here;
    // the timeline itself lives in _LiveSeekBar (isolated rebuilds).
    final pos = ref.watch(playerProvider.select((s) => s.position));

    // #3 FIX: resolve root + file path for /audio/* (sibling .lrc).
    // extras now carry rootId+path (queue_manager), but old persisted
    // queues only have songId ("root|path") — parse as fallback so
    // lyrics keep working after upgrade.
    final _rp = _resolveRootPath(track);
    final rootId = _rp.$1;
    final filePath = _rp.$2;
    final songId = (track.extras?['songId'] as String?) ?? track.id;
    final audioInfo = rootId != null && rootId.isNotEmpty
        ? ref.watch(
            audioInfoProvider(
              Song(
                id: songId,
                title: track.title,
                artist: track.artist,
                rootId: rootId,
              ),
            ),
          )
        : null;
    final lyrics = rootId != null && rootId.isNotEmpty
        ? ref.watch(lyricsProvider((rootId: rootId, path: filePath)))
        : null;

    if (_showLyrics) {
      final lyricsData = lyrics?.value;
      final hasLyrics = lyricsData?.hasLyrics ?? false;
      final lyricLines = hasLyrics
          ? lyricsData!.cues
                .map(
                  (c) => LyricLine(
                    text: c.text,
                    timestamp: c.isSynced
                        ? Duration(milliseconds: (c.time * 1000).round())
                        : null,
                  ),
                )
                .toList()
          : <LyricLine>[];

      return LyricsDisplay(
        lyrics: lyricLines,
        currentPosition: pos,
        onClose: () => setState(() => _showLyrics = false),
        // Tap a synced line → jump the song to that line.
        onLineTap: (ts) => notifier.seek(ts),
        title: track.title,
        artist: track.artist,
        artworkUrl: track.artUri?.toString(),
      );
    }

    final seed = track.id.isNotEmpty ? track.id : track.title;
    final palette = AdaptivePalette.fromSeed(seed);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [palette.primary, palette.secondary, AppColors.accentCyan],
    );
    final gradH = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [palette.primary, palette.secondary, AppColors.accentCyan],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // #1 Adaptive background: gradient wash + blurred artwork
          Positioned.fill(
            child: _AdaptiveBackground(
              artworkUrl: track.artUri?.toString(),
              palette: palette,
              // Force rebuild per track so gradient cross-fades
              key: ValueKey('bg-${track.id}'),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (d) => _dragStart = d.globalPosition,
              onPanEnd: (details) {
                final start = _dragStart;
                _dragStart = null;
                if (start == null) return;
                // Horizontal swipe → track change (#7)
                final vx = details.velocity.pixelsPerSecond.dx;
                final vy = details.velocity.pixelsPerSecond.dy;
                final dx = details.velocity.pixelsPerSecond.dx.abs();
                final dy = details.velocity.pixelsPerSecond.dy.abs();
                if (dx > dy && (dx > _hVelocity)) {
                  HapticFeedback.selectionClick();
                  if (vx < 0) {
                    notifier.next();
                  } else {
                    notifier.previous();
                  }
                  return;
                }
                // Vertical: down dismiss / up queue (existing behavior)
                if (dy > dx) {
                  if (vy > 380 && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else if (vy < -420) {
                    _showQueue(context);
                  }
                }
              },
              // Keep legacy callbacks as fallback for fast flings
              onHorizontalDragEnd: (details) {
                final vx = details.primaryVelocity ?? 0;
                if (vx < -_hVelocity) {
                  HapticFeedback.selectionClick();
                  notifier.next();
                } else if (vx > _hVelocity) {
                  HapticFeedback.selectionClick();
                  notifier.previous();
                }
              },
              onVerticalDragEnd: (details) {
                final vy = details.primaryVelocity ?? 0;
                if (vy > 380 && Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (vy < -420) {
                  _showQueue(context);
                }
              },
              child: Column(
                children: [
                  _TopBar(
                    onClose: () => Navigator.pop(context),
                    onSleepTimer: () => _showSleepTimerSheet(context, ref),
                    onMode: () => _showVisualModeSheet(context, ref),
                  ),
                  // Swipe hint (subtle, first-run discoverability)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      '‹  SWIPE TO CHANGE  ›',
                      style: TextStyle(
                        color: AppColors.textFaint.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  // FIXED STAGE — no scroll on any mode. Artwork scales to
                  // fit width AND height; sections share space evenly so
                  // controls stay aligned on every screen size.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = MediaQuery.of(context).size.width;
                        final h = constraints.maxHeight;
                        // Fit both axes: wide phones get width-capped art,
                        // short screens get height-capped art (no overflow).
                        final artworkSize =
                            (w * 0.64 < h * 0.36 ? w * 0.64 : h * 0.36).clamp(
                              170.0,
                              300.0,
                            );
                        return RepaintBoundary(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Artwork stage (isolated repaint).
                              // Double-tap cover ⇄ lyrics.
                              RepaintBoundary(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onDoubleTap: () {
                                    HapticFeedback.lightImpact();
                                    if ((lyrics?.value?.hasLyrics ?? false)) {
                                      setState(() => _showLyrics = true);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No lyrics for this track',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 380),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    transitionBuilder: (child, anim) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.94,
                                              end: 1.0,
                                            ).animate(anim),
                                            child: child,
                                          ),
                                        ),
                                    child: _ArtworkStage(
                                      key: ValueKey('${mode.name}-${track.id}'),
                                      mode: mode,
                                      track: track,
                                      isPlaying: isPlaying,
                                      artworkSize: artworkSize,
                                      gradient: grad,
                                    ),
                                  ),
                                ),
                              ),
                              // Title + artist (compact, centered)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    // Inline offline marker — player keeps
                                    // working on cache/downloads.
                                    const OfflineChip(),
                                    const SizedBox(height: 8),
                                    if (audioInfo != null)
                                      audioInfo.when(
                                        data: (info) => info != null
                                            ? NexoraTag(
                                                label: info.shortLabel,
                                                icon:
                                                    Icons.high_quality_rounded,
                                                color: info.lossless
                                                    ? const Color(0xFFFFB020)
                                                    : AppColors.accent,
                                              )
                                            : const SizedBox.shrink(),
                                        // No spinner below the cover — badge
                                        // simply appears once loaded.
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) =>
                                            const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              ),
                              // Gradient timeline (own rebuild scope)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _LiveSeekBar(
                                  gradient: gradH,
                                  accent: palette.primary,
                                ),
                              ),
                              // Controls — centered, max-width aligned
                              RepaintBoundary(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 430,
                                    ),
                                    child: _Controls(
                                      isPlaying: isPlaying,
                                      isBuffering: isBuffering,
                                      loopMode: repeatMode,
                                      isShuffled: shuffleEnabled,
                                      // Stable signature blue — never changes
                                      // per track; the page background keeps
                                      // adapting instead.
                                      gradient: AppColors.accentGradient,
                                      onPlayPause: () {
                                        HapticFeedback.lightImpact();
                                        notifier.togglePlay();
                                      },
                                      onPrevious: () {
                                        HapticFeedback.selectionClick();
                                        notifier.previous();
                                      },
                                      onNext: () {
                                        HapticFeedback.selectionClick();
                                        notifier.next();
                                      },
                                      onLoop: () {
                                        HapticFeedback.selectionClick();
                                        notifier.cycleRepeat();
                                      },
                                      onShuffle: () {
                                        HapticFeedback.selectionClick();
                                        notifier.toggleShuffle();
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              // Quick actions — centered, compact
                              _BottomActions(
                                onQueue: () => _showQueue(context),
                                onLyrics: () {
                                  if ((lyrics?.value?.hasLyrics ?? false)) {
                                    setState(() => _showLyrics = true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No lyrics for this track',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                lyricsAvailable:
                                    lyrics?.value?.hasLyrics ?? false,
                                onAddToPlaylist: () =>
                                    _showAddToPlaylist(context, track),
                                onEqualizer: () => context.push('/equalizer'),
                              ),
                              // Bottom cluster — compact, no scroll
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _VolumeBar(
                                  volume: volume,
                                  speed: speed,
                                  onVolume: notifier.setVolume,
                                  onSpeedTap: () =>
                                      _showSpeedSheet(context, ref),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _BottomDock(
                                  track: track,
                                  rootId: rootId,
                                  songId: songId,
                                  filePath: filePath,
                                  lyricsData: lyrics?.value,
                                  onSleep: () =>
                                      _showSleepTimerSheet(context, ref),
                                  onSpeed: () => _showSpeedSheet(context, ref),
                                  onLyricsEdit:
                                      (rootId != null && rootId.isNotEmpty)
                                      ? () => _showLyricsEditor(
                                          context,
                                          ref,
                                          rootId,
                                          filePath,
                                          lyrics?.value,
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => const _QueueSheet(),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _SleepTimerSheet(),
    );
  }

  void _showVisualModeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _VisualModeSheet(),
    );
  }

  /// Resolve (rootId, filePath) for backend /audio/* calls.
  /// Prefers explicit extras (new queues), falls back to parsing the
  /// canonical "root|path" songId (old persisted queues / legacy).
  (String?, String) _resolveRootPath(MediaItem t) {
    final ex = t.extras;
    var root = ex?['rootId'] as String?;
    var path = ex?['path'] as String?;
    final songId = (ex?['songId'] as String?) ?? t.id;
    if ((root == null || root.isEmpty || path == null || path.isEmpty) &&
        songId.contains('|')) {
      root = songId.split('|').first;
      path = songId.split('|').skip(1).join('|');
    }
    path ??= songId;
    if (root != null && root.isEmpty) root = null;
    return (root, path);
  }

  void _showAddToPlaylist(BuildContext context, MediaItem track) {
    // Real sheet — convert MediaItem → Song (was a dead placeholder).
    final rp = _resolveRootPath(track);
    final songId = (track.extras?['songId'] as String?) ?? track.id;
    final song = Song(
      id: songId,
      title: track.title,
      artist: track.artist,
      album: track.album,
      coverUrl: track.artUri?.toString(),
      rootId: rp.$1,
    );
    showAddToPlaylistSheet(context, song: song);
  }

  void _showSpeedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _SpeedSheet(),
    );
  }

  void _showLyricsEditor(
    BuildContext context,
    WidgetRef ref,
    String rootId,
    String filePath,
    LyricsData? current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => _LyricsEditorSheet(
        rootId: rootId,
        filePath: filePath,
        initial: current?.raw ?? '',
        hasLyrics: current?.hasLyrics ?? false,
        synced: current?.synced ?? false,
      ),
    );
  }
}

double _sin(double v) => math.sin(v);
double _cos(double v) => math.cos(v);

/// #4 — artwork stage switch. Previously `mode` was watched but never
/// used, so changing style did nothing. Now every mode renders.
class _ArtworkStage extends StatelessWidget {
  final PlayerVisualMode mode;
  final MediaItem track;
  final bool isPlaying;
  final double artworkSize;
  final Gradient gradient;

  const _ArtworkStage({
    super.key,
    required this.mode,
    required this.track,
    required this.isPlaying,
    required this.artworkSize,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case PlayerVisualMode.vinyl:
        // Caption box removed — clean disc only.
        return VinylDisc(
          artworkUrl: track.artUri?.toString(),
          isPlaying: isPlaying,
          size: artworkSize,
        );
      case PlayerVisualMode.cassette:
        // Caption box removed — deck only.
        return SizedBox(
          width: artworkSize + 40,
          child: CassettePlayer(
            isPlaying: isPlaying,
            artworkUrl: track.artUri?.toString(),
          ),
        );
      case PlayerVisualMode.minimal:
        // Caption box removed — artwork only.
        return Container(
          width: artworkSize * 0.62,
          height: artworkSize * 0.62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ArtworkImage(
              url: track.artUri?.toString(),
              borderRadius: 0,
              fit: BoxFit.cover,
            ),
          ),
        );
      case PlayerVisualMode.modern:
        // Caption box removed — glowing cover only.
        return _ModernGlowFrame(
          gradient: gradient,
          isPlaying: isPlaying,
          child: AnimatedAlbumCover(
            imageUrl: track.artUri?.toString(),
            isPlaying: isPlaying,
            size: artworkSize,
            borderRadius: 24,
          ),
        );
    }
  }
}

/// Modern signature frame — animated breathing gradient border + glow.
/// Gives the locked (non-scroll) modern stage its living feel.
class _ModernGlowFrame extends StatefulWidget {
  final Gradient gradient;
  final bool isPlaying;
  final Widget child;
  const _ModernGlowFrame({
    required this.gradient,
    required this.isPlaying,
    required this.child,
  });

  @override
  State<_ModernGlowFrame> createState() => _ModernGlowFrameState();
}

class _ModernGlowFrameState extends State<_ModernGlowFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.30 + t * 0.18),
                blurRadius: 36 + t * 22,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.14 + t * 0.12),
                blurRadius: 60 + t * 26,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(2.5 + t * 1.2),
          child: widget.child,
        );
      },
    );
  }
}

/// Top bar — no rounded pill. Centered NEXORA wordmark, plain text.
class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSleepTimer;
  final VoidCallback onMode;

  const _TopBar({
    required this.onClose,
    required this.onSleepTimer,
    required this.onMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.text,
              size: 28,
            ),
            onPressed: onClose,
          ),
          const Spacer(),
          // Center brand — plain text, no box / no rounded corner.
          Text(
            'NEXORA',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.0,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.bedtime_outlined, color: AppColors.text, size: 20),
            onPressed: onSleepTimer,
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: AppColors.text, size: 20),
            onPressed: onMode,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final LoopMode loopMode;
  final bool isShuffled;
  final Gradient gradient;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLoop;
  final VoidCallback onShuffle;

  const _Controls({
    required this.isPlaying,
    required this.isBuffering,
    required this.loopMode,
    required this.isShuffled,
    required this.gradient,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onLoop,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    // Centered transport with fixed gaps — aligned on every width.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SmallRoundButton(
            icon: Icons.shuffle_rounded,
            active: isShuffled,
            onTap: onShuffle,
            tooltip: 'Shuffle',
          ),
          const SizedBox(width: 12),
          _SkipButton(icon: Icons.skip_previous_rounded, onTap: onPrevious),
          const SizedBox(width: 18),
          // Play / Pause — adaptive gradient hero button
          GestureDetector(
            onTap: onPlayPause,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.22),
                    blurRadius: 52,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isBuffering
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) => ScaleTransition(
                        scale: Tween<double>(begin: 0.7, end: 1.0).animate(a),
                        child: c,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(isPlaying),
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 18),
          _SkipButton(icon: Icons.skip_next_rounded, onTap: onNext),
          const SizedBox(width: 12),
          _SmallRoundButton(
            icon: loopMode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            active: loopMode != LoopMode.off,
            onTap: onLoop,
            tooltip: 'Repeat',
          ),
        ],
      ),
    );
  }
}

class _SmallRoundButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;
  const _SmallRoundButton({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — bright white idle, gradient-filled icon +
    // glow bar when selected.
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: active
                    ? ShaderMask(
                        key: const ValueKey(true),
                        shaderCallback: (bounds) =>
                            AppColors.accentGradient.createShader(bounds),
                        child: Icon(icon, color: Colors.white, size: 26),
                      )
                    : Icon(
                        icon,
                        key: const ValueKey(false),
                        color: AppColors.text,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: active ? 18 : 5,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: active ? AppColors.accentGradient : null,
                  color: active ? null : Colors.transparent,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.8),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SkipButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Direct on background — no card circle. Big tactile icon.
    // (Haptic lives at the call site.)
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppColors.text, size: 38),
      ),
    );
  }
}

/// Timeline with isolated rebuilds — position ticks (≈1Hz) only rebuild
/// this bar, not the artwork/controls/background above.
class _LiveSeekBar extends ConsumerWidget {
  final Gradient gradient;
  final Color accent;
  const _LiveSeekBar({required this.gradient, required this.accent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(playerProvider.select((s) => s.position));
    final dur = ref.watch(playerProvider.select((s) => s.duration));
    final buffered = ref.watch(
      playerProvider.select((s) => s.bufferedPosition),
    );
    final trackDur = ref.watch(
      playerProvider.select((s) => s.currentTrack?.duration),
    );
    final effective = dur.inMilliseconds == 0
        ? (trackDur ?? Duration.zero)
        : dur;
    final notifier = ref.read(playerProvider.notifier);
    return NexoraSeekBar(
      position: pos,
      duration: effective,
      buffered: buffered,
      gradient: gradient,
      accent: accent,
      onSeek: notifier.seek,
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onQueue;
  final VoidCallback onLyrics;
  final bool lyricsAvailable;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onEqualizer;

  const _BottomActions({
    required this.onQueue,
    required this.onLyrics,
    this.lyricsAvailable = false,
    required this.onAddToPlaylist,
    required this.onEqualizer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionIcon(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: onQueue,
          ),
          _ActionIcon(
            icon: Icons.lyrics_rounded,
            label: 'Lyrics',
            highlighted: lyricsAvailable,
            onTap: onLyrics,
          ),
          _ActionIcon(
            icon: Icons.playlist_add_rounded,
            label: 'Add',
            onTap: onAddToPlaylist,
          ),
          _ActionIcon(
            icon: Icons.equalizer_rounded,
            label: 'EQ',
            onTap: onEqualizer,
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — bright icon + label, no box.
    final Color main = highlighted ? AppColors.accent : AppColors.text;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: main, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: highlighted ? AppColors.accent : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// #1 Adaptive background: per-track gradient + blurred artwork
/// with animated cross-fade on track change.
class _AdaptiveBackground extends StatefulWidget {
  final String? artworkUrl;
  final AdaptivePalette palette;
  const _AdaptiveBackground({
    super.key,
    this.artworkUrl,
    required this.palette,
  });

  @override
  State<_AdaptiveBackground> createState() => _AdaptiveBackgroundState();
}

class _AdaptiveBackgroundState extends State<_AdaptiveBackground>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    // Slow breathing wash + continuous orbiting glow (modern signature).
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, _orbit]),
      builder: (_, _) {
        final t = _c.value;
        final o = _orbit.value * 6.28318; // 0..2π continuous drift
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base
            Container(color: AppColors.background),
            // Adaptive gradient wash (animates hue position)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + t * 0.4, -1),
                  end: Alignment(1 - t * 0.4, 1),
                  colors: [
                    widget.palette.primary.withValues(alpha: 0.34),
                    AppColors.background.withValues(alpha: 0.0),
                    widget.palette.secondary.withValues(alpha: 0.26),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Blurred artwork (soft, behind gradient scrim)
            if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.background.withValues(alpha: 0.78),
                    BlendMode.srcOver,
                  ),
                  child: Image.network(
                    widget.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            // Top + bottom scrims for legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.55),
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
            // Aurora blobs — breathing + orbiting (moving glow).
            Positioned(
              top: -70 + t * 28 + 14 * _sin(o),
              left: -55 + 18 * _cos(o * 0.8),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.palette.primary.withValues(alpha: 0.30),
                      widget.palette.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80 - t * 20 + 16 * _sin(o + 2.1),
              right: -65 + 20 * _cos(o * 0.7 + 1.2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.palette.secondary.withValues(alpha: 0.28),
                      widget.palette.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Third drifting cyan wisp for the modern stage.
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.38 +
                  30 * _sin(o * 1.3),
              left:
                  MediaQuery.of(context).size.width * 0.5 -
                  140 +
                  60 * _cos(o * 0.6),
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentCyan.withValues(alpha: 0.10 + t * 0.05),
                        AppColors.accentCyan.withValues(alpha: 0.0),
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
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final queue = state.queue;
    final notifier = ref.read(playerProvider.notifier);
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textFaint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Queue',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradientHorizontal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${queue.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const NexoraEmptyState(
                      icon: Icons.queue_music_outlined,
                      title: 'Queue is empty',
                      subtitle: 'Add songs from your library.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final item = queue[i];
                        final isCurrent = state.currentTrack?.id == item.id;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: isCurrent
                                ? AppColors.selectionGradientHorizontal
                                : null,
                            color: isCurrent
                                ? null
                                : AppColors.surfaceRaised.withValues(
                                    alpha: 0.55,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : AppColors.border.withValues(alpha: 0.6),
                              width: 0.7,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: ArtworkImage(
                                  url: item.artUri?.toString(),
                                  borderRadius: 0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              item.artist ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.textMuted,
                              ),
                            ),
                            trailing: isCurrent
                                ? NexoraEqualizerBars(
                                    playing: state.isPlaying,
                                    barWidth: 2.5,
                                    minHeight: 3,
                                    maxHeight: 12,
                                    color: Colors.white,
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.textDim,
                                    ),
                                    onPressed: () => notifier.removeAt(i),
                                  ),
                            onTap: () => notifier.seekToIndex(i),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sleep Timer',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in SleepTimerNotifier.presets)
                    ActionChip(
                      label: Text(formatSleepDuration(d)),
                      onPressed: () {
                        ref.read(sleepTimerProvider.notifier).setTimer(d);
                        Navigator.pop(context);
                      },
                      backgroundColor: timer.isActive && timer.total == d
                          ? AppColors.accent
                          : AppColors.surfaceRaised,
                      labelStyle: TextStyle(
                        color: timer.isActive && timer.total == d
                            ? Colors.white
                            : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: timer.isActive && timer.total == d
                              ? AppColors.accent
                              : AppColors.border,
                          width: 0.7,
                        ),
                      ),
                    ),
                ],
              ),
              if (timer.isActive) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier).cancel();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel timer'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualModeSheet extends ConsumerWidget {
  const _VisualModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(playerVisualModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Player Style',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Artwork stage updates instantly.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              for (final mode in PlayerVisualMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: current == mode
                          ? AppColors.selectionGradientHorizontal
                          : null,
                      color: current == mode
                          ? null
                          : AppColors.surfaceRaised.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: current == mode
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.border,
                        width: 0.7,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _modeIcon(mode),
                        color: current == mode
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                      title: Text(
                        mode.label,
                        style: TextStyle(
                          color: current == mode
                              ? Colors.white
                              : AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _modeDesc(mode),
                        style: TextStyle(
                          color: current == mode
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: current == mode
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(playerVisualModeProvider.notifier).set(mode);
                        // Keep legacy provider synced (settings reads it)
                        ref
                            .read(playerVisualStyleProvider.notifier)
                            .set(
                              PlayerVisualStyle.values.firstWhere(
                                (e) => e.name == mode.name,
                                orElse: () => PlayerVisualStyle.modern,
                              ),
                            );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _modeIcon(PlayerVisualMode mode) {
    switch (mode) {
      case PlayerVisualMode.modern:
        return Icons.album_outlined;
      case PlayerVisualMode.vinyl:
        return Icons.album_rounded;
      case PlayerVisualMode.cassette:
        return Icons.audiotrack_rounded;
      case PlayerVisualMode.minimal:
        return Icons.crop_square_rounded;
    }
  }

  String _modeDesc(PlayerVisualMode mode) {
    switch (mode) {
      case PlayerVisualMode.modern:
        return 'Aurora frame, glowing square artwork';
      case PlayerVisualMode.vinyl:
        return 'Spinning record, artwork fills the label';
      case PlayerVisualMode.cassette:
        return 'Tape deck with rotating reels';
      case PlayerVisualMode.minimal:
        return 'Compact artwork, pure & quiet';
    }
  }
}

/// #1 Bottom-space dock — volume + speed + favorite + sleep + lyrics sync.
/// Turns the dead gap below EQ into live, tactile controls.
class _VolumeBar extends StatelessWidget {
  final double volume;
  final double speed;
  final ValueChanged<double> onVolume;
  final VoidCallback onSpeedTap;

  const _VolumeBar({
    required this.volume,
    required this.speed,
    required this.onVolume,
    required this.onSpeedTap,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — no card. Slider + plain speed text.
    final muted = volume <= 0.01;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onVolume(muted ? 1.0 : 0.0);
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              muted
                  ? Icons.volume_off_rounded
                  : volume < 0.5
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded,
              color: AppColors.text,
              size: 22,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: Colors.white,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(value: volume.clamp(0.0, 1.0), onChanged: onVolume),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSpeedTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 1 : 2)}×',
              style: TextStyle(
                color: speed == 1.0 ? AppColors.textMuted : AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomDock extends ConsumerWidget {
  final MediaItem track;
  final String? rootId;
  final String songId;
  final String filePath;
  final LyricsData? lyricsData;
  final VoidCallback onSleep;
  final VoidCallback onSpeed;
  final VoidCallback? onLyricsEdit;

  const _BottomDock({
    required this.track,
    required this.rootId,
    required this.songId,
    required this.filePath,
    required this.lyricsData,
    required this.onSleep,
    required this.onSpeed,
    required this.onLyricsEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepTimerProvider);
    final synced = lyricsData?.synced ?? false;
    final hasLyrics = lyricsData?.hasLyrics ?? false;
    // Direct on background — no card. Evenly spread actions.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _FavoriteButton(track: track, songId: songId),
          _DockButton(
            icon: Icons.speed_rounded,
            label: 'Speed',
            onTap: onSpeed,
          ),
          _DockButton(
            icon: Icons.bedtime_outlined,
            label: sleep.isActive ? sleep.label : 'Sleep',
            highlight: sleep.isActive,
            onTap: onSleep,
          ),
          _DockButton(
            icon: hasLyrics
                ? (synced ? Icons.lyrics_rounded : Icons.lyrics_outlined)
                : Icons.lyrics_outlined,
            label: hasLyrics ? (synced ? 'Synced' : 'Plain') : 'No lyr',
            highlight: hasLyrics && synced,
            dimmed: !hasLyrics,
            onTap:
                onLyricsEdit ??
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lyrics editing needs a server track (root+path).',
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  final bool dimmed;

  const _DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — bright white idle, accent when highlighted.
    final Color main = highlight
        ? AppColors.accent
        : dimmed
        ? AppColors.textFaint
        : AppColors.text;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: main),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: main,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: highlight ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: highlight ? AppColors.accentGradient : null,
                color: highlight ? null : Colors.transparent,
                boxShadow: highlight
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimistic favorite toggle wired to the real backend + offline queue.
class _FavoriteButton extends ConsumerStatefulWidget {
  final MediaItem track;
  final String songId;
  const _FavoriteButton({required this.track, required this.songId});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  bool _liked = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy
          ? null
          : () async {
              HapticFeedback.lightImpact();
              final next = !_liked;
              setState(() {
                _liked = next;
                _busy = true;
              });
              try {
                await ref
                    .read(favoritesRepositoryProvider)
                    .toggleFavorite(widget.songId, !next);
              } catch (_) {
                if (mounted) {
                  setState(() => _liked = !next);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Favorite sync failed — queued offline'),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1.0).animate(a),
              child: c,
            ),
            child: Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_liked),
              size: 24,
              color: _liked ? const Color(0xFFFF5C8A) : AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _liked ? 'Loved' : 'Love',
            style: TextStyle(
              color: _liked ? const Color(0xFFFF5C8A) : AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedSheet extends ConsumerWidget {
  const _SpeedSheet();

  static const _presets = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(playerProvider).playbackSpeed;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Playback speed',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pitch-correct tempo for podcasts, practice, audiobooks.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _presets)
                    ChoiceChip(
                      label: Text(
                        '${p.toStringAsFixed(p.truncateToDouble() == p ? 1 : 2)}×',
                      ),
                      selected: (speed - p).abs() < 0.001,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.surfaceRaised,
                      labelStyle: TextStyle(
                        color: (speed - p).abs() < 0.001
                            ? Colors.white
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppColors.border, width: 0.7),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        ref.read(playerProvider.notifier).setSpeed(p);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// #5 Lyrics sync monitor + editor.
/// Shows backend sync state (synced/plain/missing + source) and lets the
/// user save plain or LRC text straight to the sibling `.lrc` file.
class _LyricsEditorSheet extends ConsumerStatefulWidget {
  final String rootId;
  final String filePath;
  final String initial;
  final bool hasLyrics;
  final bool synced;

  const _LyricsEditorSheet({
    required this.rootId,
    required this.filePath,
    required this.initial,
    required this.hasLyrics,
    required this.synced,
  });

  @override
  ConsumerState<_LyricsEditorSheet> createState() => _LyricsEditorSheetState();
}

class _LyricsEditorSheetState extends ConsumerState<_LyricsEditorSheet> {
  late final TextEditingController _c;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _c.text.trimRight();
    if (raw.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(lyricsApiProvider)
          .saveLyrics(widget.rootId, widget.filePath, raw);
      ref.invalidate(
        lyricsProvider((rootId: widget.rootId, path: widget.filePath)),
      );
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lyrics synced to server (.lrc)')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(lyricsApiProvider)
          .deleteLyrics(widget.rootId, widget.filePath);
      ref.invalidate(
        lyricsProvider((rootId: widget.rootId, path: widget.filePath)),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lyrics sync',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _SyncPill(
                      hasLyrics: widget.hasLyrics,
                      synced: widget.synced,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Saved as sibling .lrc next to the track. Use [mm:ss.xx] tags for sync.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.7),
                    ),
                    child: TextField(
                      controller: _c,
                      maxLines: 10,
                      minLines: 6,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            '[00:12.00] First line\\n[00:15.50] Second line\\n\\nor plain text (unsynced)',
                        hintStyle: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (widget.hasLyrics)
                      TextButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                        ),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _busy ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Sync'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  final bool hasLyrics;
  final bool synced;
  const _SyncPill({required this.hasLyrics, required this.synced});

  @override
  Widget build(BuildContext context) {
    final label = !hasLyrics
        ? 'MISSING'
        : synced
        ? 'SYNCED'
        : 'PLAIN';
    final color = !hasLyrics
        ? AppColors.textDim
        : synced
        ? AppColors.success
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
