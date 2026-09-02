import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// An audiophile-grade waveform visualizer that renders smooth
/// animated bars reacting to playback state.
class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? color;
  final double barWidth;
  final double spacing;

  const WaveformVisualizer({
    super.key,
    this.isPlaying = false,
    this.barCount = 32,
    this.height = 48,
    this.color,
    this.barWidth = 3,
    this.spacing = 2,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      widget.barCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: 400 + _random.nextInt(600),
        ),
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOutSine,
        ),
      );
    }).toList();

    if (widget.isPlaying) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    for (var i = 0; i < _controllers.length; i++) {
      final delay = Duration(milliseconds: i * 30);
      Future.delayed(delay, () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimation() {
    for (final controller in _controllers) {
      controller.stop();
      controller.animateTo(0.2, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.barCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              final heightFactor = widget.isPlaying
                  ? _animations[i].value
                  : 0.2 + (i % 3) * 0.1;

              return Container(
                width: widget.barWidth,
                height: widget.height * heightFactor,
                margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.4 + (heightFactor * 0.6),
                  ),
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// A circular audio visualizer that creates a radial waveform effect.
class CircularVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double size;
  final Color? color;

  const CircularVisualizer({
    super.key,
    this.isPlaying = false,
    this.barCount = 24,
    this.size = 200,
    this.color,
  });

  @override
  State<CircularVisualizer> createState() => _CircularVisualizerState();
}

class _CircularVisualizerState extends State<CircularVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CircularVisualizerPainter(
            progress: _controller.value,
            barCount: widget.barCount,
            color: color,
            isPlaying: widget.isPlaying,
            random: _random,
          ),
        );
      },
    );
  }
}

class _CircularVisualizerPainter extends CustomPainter {
  final double progress;
  final int barCount;
  final Color color;
  final bool isPlaying;
  final math.Random random;

  _CircularVisualizerPainter({
    required this.progress,
    required this.barCount,
    required this.color,
    required this.isPlaying,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < barCount; i++) {
      final angle = (i / barCount) * 2 * math.pi - math.pi / 2;
      final baseX = center.dx + math.cos(angle) * radius;
      final baseY = center.dy + math.sin(angle) * radius;

      double barHeight = 8;
      if (isPlaying) {
        final noise = math.sin(progress * 2 * math.pi + i * 0.5) * 0.5 + 0.5;
        barHeight = 8 + noise * 20 + random.nextDouble() * 8;
      }

      final endX = center.dx + math.cos(angle) * (radius + barHeight);
      final endY = center.dy + math.sin(angle) * (radius + barHeight);

      paint.color = color.withValues(
        alpha: 0.3 + (barHeight / 40) * 0.7,
      );

      canvas.drawLine(
        Offset(baseX, baseY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
