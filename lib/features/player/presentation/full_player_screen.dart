import 'dart:ui';

import 'package:flutter/material.dart';
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
                    AppColors.background.withValues(alpha: 0.15),
                    AppColors.background.withValues(alpha: 0.8),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.5),
              ),
            ),
          ),
          // Floating particles
          const FloatingParticles(particleCount: 20, maxSize: 3),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _showCassette
                            ? CassettePlayer(
                                isPlaying: isPlaying,
                                artworkUrl: track.artUri?.toString(),
                              )
                            : Expanded(
                                child: Center(
                                  child: BreathingGlow(
                                    color: AppColors.primary,
                                    maxBlur: 40,
                                    child: RotatingAlbumArt(
                                      imageUrl: track.artUri?.toString(),
                                      isPlaying: isPlaying,
                                      size: 260,
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 32),
                        // Track info
                        Text(
                          track.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          track.artist ?? 'Unknown Artist',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (track.album != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            track.album!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Visualizer
                        VisualizerBars(
                          isPlaying: isPlaying,
                          barCount: 24,
                          color: AppColors.primary,
                          height: 30,
                        ),
                        const SizedBox(height: 16),
                        // Quality badges
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            if (track.extras?['codec'] != null)
                              GradientBadge(
                                text: (track.extras!['codec'] as String)
                                    .toUpperCase(),
                              ),
                            if (track.extras?['lossless'] == true)
                              const GradientBadge(
                                text: 'LOSSLESS',
                                color: AppColors.secondary,
                              ),
                            if (track.extras?['sampleRate'] != null &&
                                (track.extras!['sampleRate'] as int) >= 48000)
                              const GradientBadge(
                                text: 'HI-RES',
                                color: AppColors.tertiary,
                              ),
                            if (track.extras?['bitrate'] != null)
                              GradientBadge(
                                text: '${track.extras!['bitrate']} kbps',
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Seek slider
                        EnhancedSeekBar(
                          progress: dur.inMilliseconds == 0
                              ? 0
                              : (seekMs / dur.inMilliseconds).clamp(0.0, 1.0),
                          position: Duration(milliseconds: seekMs.round()),
                          duration: dur,
                          onChangeStart: (_) => setState(
                            () => _dragValue = dur.inMilliseconds == 0
                                ? 0
                                : (pos.inMilliseconds / dur.inMilliseconds)
                                    .clamp(0.0, 1.0),
                          ),
                          onChanged: (v) => setState(() => _dragValue = v),
                          onChangeEnd: (v) {
                            notifier.seek(
                              Duration(
                                milliseconds: (v * dur.inMilliseconds).round(),
                              ),
                            );
                            setState(() => _dragValue = null);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Transport console — audiophile glass control deck
                        _TransportConsole(
                          isPlaying: isPlaying,
                          isBuffering:
                              state.processingState == ProcessingState.buffering,
                          shuffle: state.shuffleEnabled,
                          repeatMode: state.repeatMode,
                          onShuffle: () => notifier.toggleShuffle(),
                          onPrevious: () => notifier.previous(),
                          onPlayPause: () => notifier.togglePlay(),
                          onNext: () => notifier.next(),
                          onRepeat: () => notifier.cycleRepeat(),
                        ),
                        const SizedBox(height: 20),
                        // Inline sleep timer status (visible when active)
                        _SleepTimerInlineBar(
                          onTap: () => _showSleepTimerSheet(context, ref),
                        ),
                        const SizedBox(height: 10),
                        // Bottom actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _IconGlow(
                              icon: Icons.queue_music_rounded,
                              onTap: () => _showQueue(context),
                            ),
                            const SizedBox(width: 16),
                            _IconGlow(
                              icon: Icons.bedtime_rounded,
                              color: AppColors.secondary,
                              onTap: () => _showSleepTimerSheet(context, ref),
                            ),
                            const SizedBox(width: 16),
                            _SpeedControl(
                              speed: state.playbackSpeed,
                              onChanged: (s) => notifier.setSpeed(s),
                            ),
                            const SizedBox(width: 16),
                            _IconGlow(
                              icon: Icons.more_horiz_rounded,
                              color: AppColors.textMuted,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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
// CONTROL BUTTON
// ═══════════════════════════════════════════════════════════════

/// The floating glass deck that houses the transport controls.
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AppColors.glassBorderStrong, width: 0.6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.glassBase.withValues(alpha: 0.55),
            AppColors.glassBase.withValues(alpha: 0.26),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Row(
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
                size: 32,
                discSize: 56,
                tone: BrightIconTone.violet,
                alwaysBright: true,
                onPressed: onPrevious,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isBuffering)
                    SizedBox(
                      width: 94,
                      height: 94,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                  EnhancedPlayButton(
                    isPlaying: isPlaying,
                    size: 84,
                    onPressed: onPlayPause,
                  ),
                ],
              ),
              _ControlButton(
                icon: Icons.skip_next_rounded,
                size: 32,
                discSize: 56,
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
          ),
        ),
      ),
    );
  }
}

/// A glass transport control with a bright gradient glyph.
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
    final colors = tone.stops;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: discSize,
        height: discSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.first.withValues(alpha: 0.32),
                    colors.last.withValues(alpha: 0.10),
                  ],
                )
              : LinearGradient(
                  colors: [
                    AppColors.glassBase.withValues(alpha: 0.38),
                    AppColors.glassBase.withValues(alpha: 0.14),
                  ],
                ),
          border: Border.all(
            color: isActive
                ? colors.first.withValues(alpha: 0.45)
                : AppColors.glassBorder,
            width: 0.7,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.38),
                    blurRadius: 24,
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [c.withValues(alpha: 0.12), c.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withValues(alpha: 0.18), width: 0.5),
        ),
        child: Icon(icon, color: c, size: 24),
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
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
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
                      selected:
                          timer.isActive && timer.total == d,
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
                      border: Border.all(
                        color: AppColors.border,
                        width: 0.6,
                      ),
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
