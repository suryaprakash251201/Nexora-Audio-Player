import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../../../ui/nexora/nexora_seek_bar.dart';
import '../../../ui/theme.dart';
import '../providers/player_provider.dart';

/// Top bar — close left, style right, clean center (no wordmark).
/// Sleep lives in the bottom dock, so it is not duplicated here. Both
/// sides are a single 48px IconButton, so the wordmark centers exactly.
class PlayerTopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMode;

  const PlayerTopBar({required this.onClose, required this.onMode});

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
          Expanded(
            // Brand wordmark removed — keep the row balanced with an
            // empty center so close/style icons stay in the corners.
            child: const SizedBox.shrink(),
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

class PlayerTransport extends StatelessWidget {
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

  const PlayerTransport({
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
          TransportSmallButton(
            icon: Icons.shuffle_rounded,
            active: isShuffled,
            onTap: onShuffle,
            tooltip: 'Shuffle',
          ),
          const SizedBox(width: 12),
          TransportSkipButton(
            icon: Icons.skip_previous_rounded,
            onTap: onPrevious,
          ),
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
          TransportSkipButton(icon: Icons.skip_next_rounded, onTap: onNext),
          const SizedBox(width: 12),
          TransportSmallButton(
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

class TransportSmallButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String tooltip;
  const TransportSmallButton({
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

class TransportSkipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const TransportSkipButton({required this.icon, required this.onTap});

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
class LiveSeekBar extends ConsumerWidget {
  final Gradient gradient;
  final Color accent;
  const LiveSeekBar({required this.gradient, required this.accent});

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
