import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, ProcessingState;

import '../../../ui/theme.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/widgets/bright_icons.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../../ui/animations/app_animations.dart';
import '../providers/player_provider.dart';
import '../providers/sleep_timer_provider.dart';
import 'cassette_player.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});
  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showCassette = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final track = state.currentTrack;

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

    final isPlaying = state.isPlaying;
    final pos = state.position;
    final dur = state.duration.inMilliseconds == 0
        ? (track.duration ?? Duration.zero)
        : state.duration;
    final seekMs = _dragValue != null
        ? _dragValue! * dur.inMilliseconds
        : pos.inMilliseconds;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dynamic blurred artwork background
          if (track.artUri != null)
            Positioned.fill(
              child: Image.network(
                track.artUri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.10),
                    AppColors.background.withValues(alpha: 0.72),
                    AppColors.background.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.38, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.72),
              ),
            ),
          ),
          // (wave particles removed — calm modern stage)
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.text,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowDot(size: 6, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    // Sleep timer — shows countdown when active
                    _SleepTimerAppBarButton(
                      onTap: () => _showSleepTimerSheet(context, ref),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.18),
                              AppColors.secondary.withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          _showCassette
                              ? Icons.album_rounded
                              : Icons.audiotrack_rounded,
                          color: AppColors.text,
                          size: 20,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _showCassette = !_showCassette),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = MediaQuery.of(context).size.width;
                      final artworkSize = (w * 0.72)
                          .clamp(220.0, 320.0)
                          .toDouble();
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  // ── Artwork stage — modern minimal ──
                                  _ArtworkStage(
                                    showCassette: _showCassette,
                                    isPlaying: isPlaying,
                                    artworkUrl: track.artUri?.toString(),
                                    size: artworkSize,
                                    onToggle: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                        () => _showCassette = !_showCassette,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 22),
                                  // ── Identity stack — editorial ──
                                  _TrackIdentity(
                                    title: track.title,
                                    artist: track.artist,
                                    album: track.album,
                                  ),
                                  const SizedBox(height: 10),
                                  // Single calm quality line (max 2 pills)
                                  _QualityLine(track: track),
                                  const SizedBox(height: 14),
                                  // Sleep timer inline (above seek, calm)
                                  _SleepTimerInlineBar(
                                    onTap: () =>
                                        _showSleepTimerSheet(context, ref),
                                  ),
                                  const SizedBox(height: 6),
                                  // ── Thin seek — precise ──
                                  EnhancedSeekBar(
                                    progress: dur.inMilliseconds == 0
                                        ? 0
                                        : (seekMs / dur.inMilliseconds).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                    position: Duration(
                                      milliseconds: seekMs.round(),
                                    ),
                                    duration: dur,
                                    onChangeStart: (_) => setState(
                                      () => _dragValue = dur.inMilliseconds == 0
                                          ? 0
                                          : (pos.inMilliseconds /
                                                    dur.inMilliseconds)
                                                .clamp(0.0, 1.0),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _dragValue = v),
                                    onChangeEnd: (v) {
                                      notifier.seek(
                                        Duration(
                                          milliseconds: (v * dur.inMilliseconds)
                                              .round(),
                                        ),
                                      );
                                      setState(() => _dragValue = null);
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  // ── Quiet transport deck ──
                                  _TransportConsole(
                                    isPlaying: isPlaying,
                                    isBuffering:
                                        state.processingState ==
                                        ProcessingState.buffering,
                                    shuffle: state.shuffleEnabled,
                                    repeatMode: state.repeatMode,
                                    onShuffle: () => notifier.toggleShuffle(),
                                    onPrevious: () => notifier.previous(),
                                    onPlayPause: () => notifier.togglePlay(),
                                    onNext: () => notifier.next(),
                                    onRepeat: () => notifier.cycleRepeat(),
                                  ),
                                  const SizedBox(height: 18),
                                  // ── Micro actions — ghost pills ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _IconGlow(
                                        icon: Icons.queue_music_rounded,
                                        onTap: () => _showQueue(context),
                                      ),
                                      const SizedBox(width: 12),
                                      _IconGlow(
                                        icon: Icons.bedtime_rounded,
                                        color: AppColors.secondary,
                                        onTap: () =>
                                            _showSleepTimerSheet(context, ref),
                                      ),
                                      const SizedBox(width: 12),
                                      _SpeedControl(
                                        speed: state.playbackSpeed,
                                        onChanged: (s) => notifier.setSpeed(s),
                                      ),
                                      const SizedBox(width: 12),
                                      _IconGlow(
                                        icon: Icons.more_horiz_rounded,
                                        color: AppColors.textMuted,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQueue(BuildContext context) {
    final state = ref.read(playerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return GlassBottomSheet(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textDim.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Up Next',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              ref.read(playerProvider.notifier).clearQueue(),
                          icon: const Icon(
                            Icons.playlist_remove_rounded,
                            color: AppColors.error,
                            size: 22,
                          ),
                          tooltip: 'Clear queue',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      scrollController: scrollController,
                      itemCount: state.queue.length,
                      onReorder: (o, n) => ref
                          .read(playerProvider.notifier)
                          .move(o, n > o ? n - 1 : n),
                      itemBuilder: (cx, i) {
                        final item = state.queue[i];
                        final isCurrent = state.currentTrack?.id == item.id;
                        return GlassSongTile(
                          key: ValueKey(item.id + '_$i'),
                          artworkUrl: item.artUri?.toString(),
                          title: item.title,
                          subtitle: item.artist ?? '',
                          isCurrent: isCurrent,
                          isPlaying: isCurrent && state.isPlaying,
                          onTap: () =>
                              ref.read(playerProvider.notifier).seekToIndex(i),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textDim,
                            ),
                            onPressed: () =>
                                ref.read(playerProvider.notifier).removeAt(i),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => _SleepTimerSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ARTWORK STAGE — Modern minimal with AnimatedSwitcher
// ═══════════════════════════════════════════════════════════════

class _ArtworkStage extends StatelessWidget {
  final bool showCassette;
  final bool isPlaying;
  final String? artworkUrl;
  final double size;
  final VoidCallback onToggle;

  const _ArtworkStage({
    required this.showCassette,
    required this.isPlaying,
    required this.artworkUrl,
    required this.size,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, anim) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
        child: showCassette
            ? CassettePlayer(
                key: const ValueKey('cassette'),
                isPlaying: isPlaying,
                artworkUrl: artworkUrl,
              )
            : Center(
                key: const ValueKey('artwork'),
                // Round disc only — no box-shape glow background.
                child: RotatingAlbumArt(
                  imageUrl: artworkUrl,
                  isPlaying: isPlaying,
                  size: size,
                ),
              ),
      ),
    );
  }
}

class _TrackIdentity extends StatelessWidget {
  final String title;
  final String? artist;
  final String? album;
  const _TrackIdentity({required this.title, this.artist, this.album});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          artist ?? 'Unknown Artist',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryLight,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
        if (album != null) ...[
          const SizedBox(height: 3),
          Text(
            album!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _QualityLine extends StatelessWidget {
  final dynamic track;
  const _QualityLine({required this.track});

  @override
  Widget build(BuildContext context) {
    final codec = track.extras?['codec'] as String?;
    final lossless = track.extras?['lossless'] == true;
    final hiRes =
        track.extras?['sampleRate'] != null &&
        (track.extras!['sampleRate'] as int) >= 48000;
    final bitrate = track.extras?['bitrate'];

    final pills = <Widget>[];
    if (lossless) {
      pills.add(
        const GradientBadge(text: 'LOSSLESS', color: AppColors.secondary),
      );
    } else if (codec != null) {
      pills.add(GradientBadge(text: codec.toUpperCase()));
    }
    if (hiRes) {
      pills.add(const GradientBadge(text: 'HI-RES', color: AppColors.tertiary));
    } else if (lossless && codec != null && bitrate != null) {
      // Show bitrate only when not hi-res to keep max 2
      pills.add(GradientBadge(text: '$bitrate kbps'));
    }

    if (pills.isEmpty) return const SizedBox(height: 4);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: pills.take(2).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTROL BUTTON
// ═══════════════════════════════════════════════════════════════

/// Quiet modern capsule that houses transport controls.
class _TransportConsole extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final bool shuffle;
  final LoopMode repeatMode;
  final VoidCallback onShuffle;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onRepeat;

  const _TransportConsole({
    required this.isPlaying,
    required this.isBuffering,
    required this.shuffle,
    required this.repeatMode,
    required this.onShuffle,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    // Modern transport: NO container background. Controls float over the
    // scrim, each button is a clean disc (light=ink-on-white, dark=glass).
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: [
        _ControlButton(
          icon: Icons.shuffle_rounded,
          isActive: shuffle,
          tone: BrightIconTone.cyan,
          onPressed: onShuffle,
        ),
        _ControlButton(
          icon: Icons.skip_previous_rounded,
          size: 28,
          discSize: 52,
          tone: BrightIconTone.violet,
          alwaysBright: true,
          onPressed: onPrevious,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            if (isBuffering)
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
            EnhancedPlayButton(
              isPlaying: isPlaying,
              size: 80,
              showGlow: isPlaying,
              onPressed: onPlayPause,
            ),
          ],
        ),
        _ControlButton(
          icon: Icons.skip_next_rounded,
          size: 28,
          discSize: 52,
          tone: BrightIconTone.violet,
          alwaysBright: true,
          onPressed: onNext,
        ),
        _ControlButton(
          icon: repeatMode == LoopMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          isActive: repeatMode != LoopMode.off,
          tone: BrightIconTone.pink,
          onPressed: onRepeat,
        ),
      ],
    );
  }
}

/// A clean transport control button — no glass disc background, just a
/// transparent round tap target. Active state colors the glyph only.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final double size;
  final double discSize;
  final BrightIconTone tone;
  final bool alwaysBright;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    this.isActive = false,
    this.size = 26,
    this.discSize = 48,
    this.tone = BrightIconTone.violet,
    this.alwaysBright = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: discSize,
        height: discSize,
        child: Center(
          child: BrightIcon(
            icon: icon,
            size: size,
            tone: tone,
            active: isActive || alwaysBright,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ICON GLOW
// ═══════════════════════════════════════════════════════════════

class _IconGlow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _IconGlow({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    final isLight = AppColors.mode == AppThemeMode.light;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.86)
              : c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLight ? AppColors.hairline : c.withValues(alpha: 0.14),
            width: 0.6,
          ),
          boxShadow: isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: c, size: 20),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPEED CONTROL
// ═══════════════════════════════════════════════════════════════

class _SpeedControl extends StatelessWidget {
  final double speed;
  final ValueChanged<double> onChanged;
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  const _SpeedControl({required this.speed, required this.onChanged});

  String _label(double s) {
    if (s == 1.0) return '1x';
    final str = s == s.roundToDouble() ? '${s.round()}x' : '${s}x';
    return str;
  }

  void _cycle() {
    final idx = _speeds.indexWhere((s) => (s - speed).abs() < 0.001);
    final next = _speeds[(idx < 0 ? 0 : idx + 1) % _speeds.length];
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final active = speed != 1.0;
    final c = active ? AppColors.secondary : AppColors.textMuted;
    return GestureDetector(
      onTap: _cycle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              c.withValues(alpha: active ? 0.18 : 0.1),
              c.withValues(alpha: active ? 0.08 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: c.withValues(alpha: active ? 0.35 : 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, color: c, size: 18),
            const SizedBox(width: 4),
            Text(
              _label(speed),
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SLEEP TIMER — App bar badge + inline bar + bottom sheet
// ═══════════════════════════════════════════════════════════════

class _SleepTimerAppBarButton extends ConsumerWidget {
  final VoidCallback onTap;
  const _SleepTimerAppBarButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    final active = timer.isActive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.secondary.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.secondary.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.14),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bedtime_rounded,
              size: 16,
              color: active ? AppColors.secondary : AppColors.text,
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                timer.label.replaceAll(' left', ''),
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SleepTimerInlineBar extends ConsumerWidget {
  final VoidCallback onTap;
  const _SleepTimerInlineBar({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    if (!timer.isActive) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withValues(alpha: 0.14),
              AppColors.primary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.22),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bedtime_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep timer • ${timer.label}',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: timer.progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => ref.read(sleepTimerProvider.notifier).cancel(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.22),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return GlassBottomSheet(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary.withValues(alpha: 0.22),
                          AppColors.primary.withValues(alpha: 0.14),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep timer',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          timer.isActive
                              ? timer.label
                              : 'Music stops automatically',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timer.isActive)
                    GestureDetector(
                      onTap: () =>
                          ref.read(sleepTimerProvider.notifier).cancel(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (timer.isActive) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: timer.progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatSleepDuration(timer.total ?? Duration.zero) +
                          ' total',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref
                          .read(sleepTimerProvider.notifier)
                          .extend(const Duration(minutes: 5)),
                      child: Text(
                        '+5 min',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'Set timer',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final d in SleepTimerNotifier.presets)
                    _PresetChip(
                      duration: d,
                      selected: timer.isActive && timer.total == d,
                      onTap: () {
                        ref.read(sleepTimerProvider.notifier).setTimer(d);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (timer.isActive) {
                      ref.read(sleepTimerProvider.notifier).cancel();
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: Text(
                      timer.isActive ? 'Turn off' : 'Off',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final Duration duration;
  final bool selected;
  final VoidCallback onTap;
  const _PresetChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.22),
                    AppColors.primary.withValues(alpha: 0.14),
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppColors.surfaceRaised.withValues(alpha: 0.9),
                    AppColors.surfaceHigh.withValues(alpha: 0.6),
                  ],
                ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.35)
                : AppColors.border,
            width: 0.6,
          ),
        ),
        child: Text(
          formatSleepDuration(duration),
          style: TextStyle(
            color: selected ? AppColors.secondary : AppColors.text,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
