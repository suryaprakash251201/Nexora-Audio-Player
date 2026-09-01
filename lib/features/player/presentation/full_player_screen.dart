import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, ProcessingState;

import '../../../ui/theme.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../../ui/animations/app_animations.dart';
import '../providers/player_provider.dart';
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
                        // Transport controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ControlButton(
                              icon: Icons.shuffle_rounded,
                              isActive: state.shuffleEnabled,
                              onPressed: () => notifier.toggleShuffle(),
                            ),
                            _ControlButton(
                              icon: Icons.skip_previous_rounded,
                              size: 44,
                              onPressed: () => notifier.previous(),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                if (state.processingState ==
                                    ProcessingState.buffering)
                                  SizedBox(
                                    width: 84,
                                    height: 84,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                        AppColors.primary,
                                      ),
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                EnhancedPlayButton(
                                  isPlaying: isPlaying,
                                  size: 84,
                                  onPressed: () => notifier.togglePlay(),
                                ),
                              ],
                            ),
                            _ControlButton(
                              icon: Icons.skip_next_rounded,
                              size: 44,
                              onPressed: () => notifier.next(),
                            ),
                            _ControlButton(
                              icon: _repeatIcon(state.repeatMode),
                              isActive: state.repeatMode != LoopMode.off,
                              onPressed: () => notifier.cycleRepeat(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
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
                              icon: Icons.favorite_rounded,
                              color: AppColors.tertiary,
                              onTap: () {},
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

  IconData _repeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.one:
        return Icons.repeat_one_rounded;
      case LoopMode.all:
        return Icons.repeat_rounded;
      case LoopMode.off:
        return Icons.repeat_rounded;
    }
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
}

// ═══════════════════════════════════════════════════════════════
// CONTROL BUTTON
// ═══════════════════════════════════════════════════════════════

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final double size;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    this.isActive = false,
    this.size = 32,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.text,
          size: size,
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
