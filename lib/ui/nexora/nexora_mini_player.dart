import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/player/providers/player_provider.dart';
import '../theme.dart';
import 'nexora_artwork.dart';
import 'nexora_tokens.dart';

/// Premium persistent mini-player.
///
/// Square artwork on the left, title + artist center, play / next on the
/// right. Supports horizontal swipe gestures: left → next, right →
/// previous. Long-press can be wired by callers for quick actions. Tap
/// opens the full player.
class NexoraMiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  const NexoraMiniPlayer({super.key, required this.onTap});

  @override
  ConsumerState<NexoraMiniPlayer> createState() => _NexoraMiniPlayerState();
}

class _NexoraMiniPlayerState extends ConsumerState<NexoraMiniPlayer> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final progress = state.duration.inMilliseconds == 0
        ? 0.0
        : (state.position.inMilliseconds / state.duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onHorizontalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dx);
      },
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (_dragOffset < -40 || v < -500) {
          ref.read(playerProvider.notifier).next();
        } else if (_dragOffset > 40 || v > 500) {
          ref.read(playerProvider.notifier).previous();
        }
        setState(() => _dragOffset = 0);
      },
      onHorizontalDragCancel: () => setState(() => _dragOffset = 0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: NexoraRadius.card,
          border: Border.all(color: AppColors.border, width: 0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  NexoraArtwork(
                    url: track.artUri?.toString(),
                    size: 44,
                  ),
                  const SizedBox(width: NexoraSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (track.artist != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            track.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _MiniPlayButton(
                    isPlaying: state.isPlaying,
                    onPressed: () =>
                      ref.read(playerProvider.notifier).togglePlay(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.text,
                      size: 24,
                    ),
                    onPressed: () =>
                      ref.read(playerProvider.notifier).next(),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ),
            // Thin progress line — accent only, no glow.
            Stack(
              children: [
                Container(
                  height: 2,
                  color: AppColors.surfaceHigh,
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 2,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  const _MiniPlayButton({required this.isPlaying, required this.onPressed});

  @override
  State<_MiniPlayButton> createState() => _MiniPlayButtonState();
}

class _MiniPlayButtonState extends State<_MiniPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: NexoraDuration.tap,
        curve: Curves.easeOut,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.text,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppColors.background,
            size: 20,
          ),
        ),
      ),
    );
  }
}