import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'artwork_image.dart' show nexoraArtworkCache;

/// Spinning vinyl record with the track artwork filling the center label.
///
/// Fixes:
/// - true round shape (AspectRatio 1, BoxShape.circle everywhere)
/// - cover photo FILLS the label (BoxFit.cover, no letterbox, no distortion)
/// - grooves + sheen + spindle hole for realism
/// - smooth rotation while playing, stops cleanly when paused
class VinylDisc extends StatefulWidget {
  final String? artworkUrl;
  final Widget Function()? artworkBuilder;
  final bool isPlaying;
  final double size;

  const VinylDisc({
    super.key,
    this.artworkUrl,
    this.artworkBuilder,
    required this.isPlaying,
    this.size = 300,
  });

  @override
  State<VinylDisc> createState() => _VinylDiscState();
}

class _VinylDiscState extends State<VinylDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.isPlaying) _spin.repeat();
  }

  @override
  void didUpdateWidget(covariant VinylDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.isPlaying && _spin.isAnimating) {
      _spin.stop(canceled: false);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Drop shadow
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
          ),
          // Rotating platter
          RotationTransition(
            turns: _spin,
            child: Container(
              width: s,
              height: s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF23232e),
                    Color(0xFF0a0a10),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grooves
                  CustomPaint(size: Size(s, s), painter: _GroovesPainter()),
                  // Light sheen (static, doesn't rotate with grooves ideally,
                  // but cheap + looks good)
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white10,
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x14FFFFFF),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.18, 0.32, 0.55, 0.72, 1.0],
                      ),
                    ),
                  ),
                  // Center label ring
                  Container(
                    width: s * 0.42,
                    height: s * 0.42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  // Artwork FILL — circle-clipped, cover fit
                  ClipOval(
                    child: SizedBox(
                      width: s * 0.42,
                      height: s * 0.42,
                      child: _labelArt(),
                    ),
                  ),
                  // Spindle hole
                  Container(
                    width: s * 0.045,
                    height: s * 0.045,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFe8e8ee),
                      border: Border.all(color: Colors.black54, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: s * 0.014,
                        height: s * 0.014,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black87,
                        ),
                      ),
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

  Widget _labelArt() {
    if (widget.artworkBuilder != null) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 200,
          height: 200,
          child: widget.artworkBuilder!(),
        ),
      );
    }
    final url = widget.artworkUrl;
    if (url == null || url.isEmpty || url == 'null') {
      return Container(
        color: const Color(0xFF2E7CF6),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white, size: 44),
        ),
      );
    }
    // Fill: cover, centered, no distortion. gapless.
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      cacheManager: nexoraArtworkCache,
      errorWidget: (_, _, _) => Container(
        color: const Color(0xFF2E7CF6),
        child: const Center(
          child: Icon(Icons.music_note_rounded, color: Colors.white, size: 44),
        ),
      ),
      progressIndicatorBuilder: (c, u, p) => Container(
        color: const Color(0xFF141927),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}

class _GroovesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Grooves between label edge and outer edge
    final labelR = maxR * 0.42;
    for (double r = labelR + 6; r < maxR - 3; r += 4.5) {
      final t = (r - labelR) / (maxR - labelR);
      paint.color = Colors.white.withValues(
        alpha: 0.05 + 0.04 * math.sin(t * 20),
      );
      canvas.drawCircle(c, r, paint);
    }
    // Outer rim highlight
    canvas.drawCircle(
      c,
      maxR - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.12),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Deterministic adaptive palette from any string seed (track id / title).
/// No extra dependency — stable hue per track, always harmonious with
/// the midnight-aurora theme.
class AdaptivePalette {
  final Color primary;
  final Color secondary;
  final Color glow;

  const AdaptivePalette(this.primary, this.secondary, this.glow);

  static AdaptivePalette fromSeed(String seed) {
    var h = 0;
    for (var i = 0; i < seed.length; i++) {
      h = (h * 31 + seed.codeUnitAt(i)) & 0x7fffffff;
    }
    final hue = (h % 360).toDouble();
    // Keep saturation/lightness in audiophile range: rich but not neon.
    final p = HSLColor.fromAHSL(1.0, hue, 0.72, 0.55).toColor();
    final s = HSLColor.fromAHSL(1.0, (hue + 42) % 360, 0.78, 0.48).toColor();
    return AdaptivePalette(p, s, p);
  }
}
