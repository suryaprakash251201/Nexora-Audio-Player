import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../theme.dart';
import 'nexora_primitives.dart';
import 'nexora_tokens.dart';

/// Tactile transport deck used by the full player.
///
/// Center play button is large and balanced. Shuffle + repeat sit at the
/// ends as quiet icon buttons. All controls feel physical: tap-down
/// feedback, accent highlights for active states.
class NexoraPlaybackControls extends ConsumerWidget {
  final bool isPlaying;
  final bool isBuffering;
  final bool shuffle;
  final LoopMode repeatMode;
  final ValueChanged onShuffle;
  final ValueChanged onPrevious;
  final ValueChanged onPlayPause;
  final ValueChanged onNext;
  final ValueChanged onRepeat;

  const NexoraPlaybackControls({
    super.key,
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NexoraIconButton(
          icon: Icons.shuffle_rounded,
          onTap: onShuffle,
          active: shuffle,
          color: shuffle ? AppColors.accent : AppColors.textMuted,
          tooltip: 'Shuffle',
        ),
        NexoraIconButton(
          icon: Icons.skip_previous_rounded,
          onTap: onPrevious,
          size: 56,
          iconSize: 32,
          tooltip: 'Previous',
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            if (isBuffering)
              SizedBox(
                width: 76,
                height: 76,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.6,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            NexoraPlayButton(isPlaying: isPlaying, onPressed: onPlayPause),
          ],
        ),
        NexoraIconButton(
          icon: Icons.skip_next_rounded,
          onTap: onNext,
          size: 56,
          iconSize: 32,
          tooltip: 'Next',
        ),
        NexoraIconButton(
          icon: repeatMode == LoopMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          onTap: onRepeat,
          active: repeatMode != LoopMode.off,
          color: repeatMode != LoopMode.off
              ? AppColors.accent
              : AppColors.textMuted,
          tooltip: 'Repeat',
        ),
      ],
    );
  }
}

/// Big circular play button. The visual centerpiece of the transport
/// deck. Stays simple — no glow halo, no gradient — so it reads as
/// premium hardware, not as decoration.
class NexoraPlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;

  const NexoraPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onPressed,
      scale: 0.94,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.text,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: NexoraDuration.micro,
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(isPlaying),
              color: AppColors.background,
              size: size * 0.46,
            ),
          ),
        ),
      ),
    );
  }
}