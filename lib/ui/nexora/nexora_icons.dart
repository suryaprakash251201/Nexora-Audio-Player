import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The set of custom-drawn glyphs available through [NexoraGlyph].
enum NexoraGlyphKind {
  /// Vinyl record with concentric grooves.
  vinyl,

  /// Audio waveform bars.
  waveform,

  /// Hi-res / lossless diamond.
  hiRes,

  /// Two curves blending into one another.
  crossfade,

  /// Two blocks sitting flush — no gap.
  gapless,

  /// Cast / output device.
  cast,

  /// Ascending bar chart.
  stats,

  /// Playlist lines with a note.
  playlist,

  /// Crescent moon — night / sleep timer.
  night,
}

/// A custom-drawn icon.
///
/// Material's icon set is deliberately generic. An audiophile product wants
/// marks that reference hardware and signal instead. These are painted from
/// paths, so they stay crisp at any size, cost no font asset, and inherit the
/// active theme's colours.
class NexoraGlyph extends StatelessWidget {
  const NexoraGlyph({
    super.key,
    required this.kind,
    this.size = 22,
    this.color,
  });

  final NexoraGlyphKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GlyphPainter(kind: kind, color: color ?? AppColors.text),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.kind, required this.color});

  final NexoraGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (kind) {
      case NexoraGlyphKind.vinyl:
        _drawVinyl(canvas, size, paint);
        break;
      case NexoraGlyphKind.waveform:
        _drawWaveform(canvas, size, paint);
        break;
      case NexoraGlyphKind.hiRes:
        _drawHiRes(canvas, size, paint);
        break;
      case NexoraGlyphKind.crossfade:
        _drawCrossfade(canvas, size, paint);
        break;
      case NexoraGlyphKind.gapless:
        _drawGapless(canvas, size, paint);
        break;
      case NexoraGlyphKind.cast:
        _drawCast(canvas, size, paint);
        break;
      case NexoraGlyphKind.stats:
        _drawStats(canvas, size, paint);
        break;
      case NexoraGlyphKind.playlist:
        _drawPlaylist(canvas, size, paint);
        break;
      case NexoraGlyphKind.night:
        _drawNight(canvas, size, paint);
        break;
    }
  }

  void _drawVinyl(Canvas canvas, Size size, Paint paint) {
    final center = size.center(Offset.zero);
    final radius = (size.width - paint.strokeWidth) / 2;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * 0.58, paint);
    canvas.drawCircle(
      center,
      radius * 0.18,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawWaveform(Canvas canvas, Size size, Paint paint) {
    const heights = <double>[0.34, 0.62, 1.0, 0.70, 0.44, 0.84, 0.30];
    final gap = size.width * 0.055;
    final barWidth = (size.width - gap * (heights.length - 1)) / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final h = size.height * heights[i];
      final x = i * (barWidth + gap) + barWidth / 2;
      canvas.drawLine(
        Offset(x, (size.height - h) / 2),
        Offset(x, (size.height + h) / 2),
        paint,
      );
    }
  }

  void _drawHiRes(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.06)
        ..lineTo(w * 0.94, h / 2)
        ..lineTo(w / 2, h * 0.94)
        ..lineTo(w * 0.06, h / 2)
        ..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, h * 0.32)
        ..lineTo(w * 0.68, h / 2)
        ..lineTo(w / 2, h * 0.68)
        ..lineTo(w * 0.32, h / 2)
        ..close(),
      paint,
    );
  }

  void _drawCrossfade(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.06, h * 0.74)
        ..quadraticBezierTo(w * 0.34, h * 0.14, w * 0.58, h * 0.54),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.42, h * 0.46)
        ..quadraticBezierTo(w * 0.66, h * 0.86, w * 0.94, h * 0.26),
      paint,
    );
  }

  void _drawGapless(Canvas canvas, Size size, Paint paint) {
    final h = size.height * 0.54;
    final y = (size.height - h) / 2;
    final w = (size.width - size.width * 0.06) / 2;
    final radius = Radius.circular(size.width * 0.09);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, y, w, h), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w, y, w, h), radius),
      paint,
    );
  }

  void _drawCast(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.06, h * 0.32, w * 0.88, h * 0.52),
        Radius.circular(w * 0.09),
      ),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.30, h * 0.04, w * 0.40, h * 0.26),
      math.pi,
      math.pi,
      false,
      paint,
    );
  }

  void _drawStats(Canvas canvas, Size size, Paint paint) {
    const heights = <double>[0.38, 0.66, 1.0];
    final gap = size.width * 0.12;
    final barWidth =
        (size.width - gap * (heights.length - 1)) / heights.length;
    for (var i = 0; i < heights.length; i++) {
      final barHeight = size.height * heights[i];
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
          Radius.circular(barWidth * 0.35),
        ),
        paint,
      );
    }
  }

  void _drawPlaylist(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    for (var i = 0; i < 3; i++) {
      final y = h * (0.26 + i * 0.24);
      canvas.drawLine(Offset(0, y), Offset(w * 0.56, y), paint);
    }
    final noteX = w * 0.74;
    canvas.drawLine(Offset(noteX, h * 0.70), Offset(noteX, h * 0.28), paint);
    canvas.drawCircle(
      Offset(noteX, h * 0.78),
      w * 0.09,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawNight(Canvas canvas, Size size, Paint paint) {
    final w = size.width;
    final h = size.height;
    final outer = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.52, h * 0.5), radius: w * 0.36),
      );
    final inner = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.70, h * 0.38), radius: w * 0.32),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// Animated equalizer bars used as a compact "now playing" indicator.
class NexoraEqualizerBars extends StatefulWidget {
  const NexoraEqualizerBars({
    super.key,
    this.color,
    this.barCount = 4,
    this.barWidth = 3,
    this.minHeight = 4,
    this.maxHeight = 16,
    this.duration = const Duration(milliseconds: 700),
    this.playing = true,
  });

  final Color? color;
  final int barCount;
  final double barWidth;
  final double minHeight;
  final double maxHeight;
  final Duration duration;

  /// When false the bars rest at their minimum height.
  final bool playing;

  @override
  State<NexoraEqualizerBars> createState() => _NexoraEqualizerBarsState();
}

class _NexoraEqualizerBarsState extends State<NexoraEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.playing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant NexoraEqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
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
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < widget.barCount; i++) ...[
              if (i > 0) SizedBox(width: widget.barWidth * 0.7),
              _bar(t, i, color),
            ],
          ],
        );
      },
    );
  }

  Widget _bar(double t, int index, Color color) {
    final phase = t * math.pi * 2 + index * 1.7;
    final amplitude = (math.sin(phase) + 1) / 2;
    final height = widget.minHeight +
        (widget.maxHeight - widget.minHeight) * amplitude;
    return Container(
      width: widget.barWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.barWidth / 2),
      ),
    );
  }
}
