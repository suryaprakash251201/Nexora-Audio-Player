import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/vinyl_disc.dart';

double _sin(double v) => math.sin(v);
double _cos(double v) => math.cos(v);

/// #1 Adaptive background: per-track gradient + blurred artwork
/// with animated cross-fade on track change.
class AdaptiveBackground extends StatefulWidget {
  final String? artworkUrl;
  final AdaptivePalette palette;
  const AdaptiveBackground({super.key, this.artworkUrl, required this.palette});

  @override
  State<AdaptiveBackground> createState() => _AdaptiveBackgroundState();
}

class _AdaptiveBackgroundState extends State<AdaptiveBackground>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _orbit;

  @override
  void initState() {
    super.initState();
    // Slow breathing wash + continuous orbiting glow (modern signature).
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbit = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, _orbit]),
      builder: (_, _) {
        final t = _c.value;
        final o = _orbit.value * 6.28318; // 0..2π continuous drift
        return Stack(
          fit: StackFit.expand,
          children: [
            // Base
            Container(color: AppColors.background),
            // Adaptive gradient wash (animates hue position)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1 + t * 0.4, -1),
                  end: Alignment(1 - t * 0.4, 1),
                  colors: [
                    widget.palette.primary.withValues(alpha: 0.34),
                    AppColors.background.withValues(alpha: 0.0),
                    widget.palette.secondary.withValues(alpha: 0.26),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Blurred artwork (soft, behind gradient scrim)
            if (widget.artworkUrl != null && widget.artworkUrl!.isNotEmpty)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.background.withValues(alpha: 0.78),
                    BlendMode.srcOver,
                  ),
                  child: Image.network(
                    widget.artworkUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            // Top + bottom scrims for legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.55),
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
            // Aurora blobs — breathing + orbiting (moving glow).
            Positioned(
              top: -70 + t * 28 + 14 * _sin(o),
              left: -55 + 18 * _cos(o * 0.8),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.palette.primary.withValues(alpha: 0.30),
                      widget.palette.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80 - t * 20 + 16 * _sin(o + 2.1),
              right: -65 + 20 * _cos(o * 0.7 + 1.2),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.palette.secondary.withValues(alpha: 0.28),
                      widget.palette.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Third drifting cyan wisp for the modern stage.
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.38 +
                  30 * _sin(o * 1.3),
              left:
                  MediaQuery.of(context).size.width * 0.5 -
                  140 +
                  60 * _cos(o * 0.6),
              child: IgnorePointer(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(90),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentCyan.withValues(alpha: 0.10 + t * 0.05),
                        AppColors.accentCyan.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
