import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import '../../../data/api/audio_api.dart';
import '../../../data/api/lyrics_api.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/player_visual_mode_provider.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/connectivity_banner.dart';
import '../../../ui/widgets/lyrics_display.dart';
import '../../../ui/widgets/vinyl_disc.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';
import '../providers/player_provider.dart';
import 'player_background.dart';
import 'player_badges.dart';
import 'player_dock.dart';
import 'player_sheets.dart';
import 'player_stage.dart';
import 'player_transport.dart';

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
    // the seek bar (LiveSeekBar), not artwork/controls/background.
    final notifier = ref.read(playerProvider.notifier);
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));
    final mode = ref.watch(playerVisualModeProvider);

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
    // the timeline itself lives in LiveSeekBar (isolated rebuilds).
    final pos = ref.watch(playerProvider.select((s) => s.position));
    final durState = ref.watch(playerProvider.select((s) => s.duration));
    final dur = durState.inMilliseconds == 0
        ? (track.duration ?? Duration.zero)
        : durState;

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
        duration: dur,
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
            child: AdaptiveBackground(
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
                  PlayerTopBar(
                    onClose: () => Navigator.pop(context),
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
                                    child: ArtworkStage(
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
                                    // Lossless wordmark — renders only for
                                    // lossless tracks (display only).
                                    LosslessBadge(
                                      track: track,
                                      info: audioInfo?.value,
                                    ),
                                  ],
                                ),
                              ),
                              // Gradient timeline (own rebuild scope)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: LiveSeekBar(
                                  gradient: gradH,
                                  accent: palette.primary,
                                ),
                              ),
                              // PlayerTransport — centered, max-width aligned
                              RepaintBoundary(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 430,
                                    ),
                                    child: PlayerTransport(
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
                              PlayerQuickActions(
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
                                child: VolumeBar(
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
                                child: PlayerBottomDock(
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
      builder: (c) => const QueueSheet(),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const SleepTimerSheet(),
    );
  }

  void _showVisualModeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const VisualModeSheet(),
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
      builder: (c) => const SpeedSheet(),
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
      builder: (c) => LyricsEditorSheet(
        rootId: rootId,
        filePath: filePath,
        initial: current?.raw ?? '',
        hasLyrics: current?.hasLyrics ?? false,
        synced: current?.synced ?? false,
      ),
    );
  }
}
