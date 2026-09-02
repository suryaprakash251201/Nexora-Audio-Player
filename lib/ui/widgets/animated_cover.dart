import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'artwork_image.dart';

/// Animated album cover that pulses gently when playing.
class AnimatedAlbumCover extends StatefulWidget {
  final String? imageUrl;
  final bool isPlaying;
  final double size;
  final double borderRadius;
  final bool showShadow;

  const AnimatedAlbumCover({
    super.key,
    this.imageUrl,
    required this.isPlaying,
    this.size = 280,
    this.borderRadius = 12,
    this.showShadow = true,
  });

  @override
  State<AnimatedAlbumCover> createState() => _AnimatedAlbumCoverState();
}

class _AnimatedAlbumCoverState extends State<AnimatedAlbumCover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedAlbumCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle glow behind the artwork when playing
          if (widget.isPlaying)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final t = _controller.value;
                final glowOpacity = 0.15 + 0.10 * math.sin(t * 2 * math.pi);
                return Container(
                  width: widget.size + 24,
                  height: widget.size + 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius + 12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: glowOpacity),
                        blurRadius: 40 + 20 * math.sin(t * 2 * math.pi),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                );
              },
            ),
          // The artwork itself with a subtle breathing scale
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              final t = _controller.value;
              final scale = widget.isPlaying
                  ? 1.0 + 0.008 * math.sin(t * 2 * math.pi)
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: widget.showShadow
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: AppColors.mode == AppThemeMode.dark
                                    ? 0.45
                                    : 0.18,
                              ),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: ArtworkImage(
                      url: widget.imageUrl,
                      size: widget.size,
                      borderRadius: 0,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A compact equalizer indicator for the mini player / list rows.
class NexoraEqualizerBars extends StatefulWidget {
  final bool playing;
  final double barWidth;
  final double minHeight;
  final double maxHeight;
  final Color? color;

  const NexoraEqualizerBars({
    super.key,
    required this.playing,
    this.barWidth = 3,
    this.minHeight = 3,
    this.maxHeight = 14,
    this.color,
  });

  @override
  State<NexoraEqualizerBars> createState() => _NexoraEqualizerBarsState();
}

class _NexoraEqualizerBarsState extends State<NexoraEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.playing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NexoraEqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppColors.accent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (i) {
            final phase = _controller.value * math.pi * 2 + i * 1.2;
            final h = widget.playing
                ? widget.minHeight +
                      (widget.maxHeight - widget.minHeight) *
                          ((math.sin(phase) + 1) / 2)
                : widget.minHeight;
            return Container(
              width: widget.barWidth,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c.withValues(alpha: widget.playing ? 0.9 : 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
