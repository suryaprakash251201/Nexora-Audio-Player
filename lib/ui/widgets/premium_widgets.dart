import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
// ANIMATED GRADIENT BACKGROUND
// ═══════════════════════════════════════════════════════════════

/// Slow-moving gradient orbs that create a living, organic background.
class AnimatedGradientBg extends StatefulWidget {
  final List<Color> colors;
  final double blur;
  final Widget child;

  const AnimatedGradientBg({
    super.key,
    this.colors = const [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
    ],
    this.blur = 60,
    required this.child,
  });

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark base
        Container(color: AppColors.background),
        // Animated blurred orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _OrbPainter(
                t: t,
                colors: widget.colors,
                blur: widget.blur,
              ),
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final double blur;

  _OrbPainter({required this.t, required this.colors, required this.blur});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(size.width, size.height) * 0.35;

    for (var i = 0; i < colors.length; i++) {
      final angle = t * 2 * math.pi + (i * 2 * math.pi / colors.length);
      final offset = maxR * 0.4;
      final ox = cx + math.cos(angle) * offset;
      final oy = cy + math.sin(angle * 0.7) * offset * 0.6;
      paint.color = colors[i].withValues(alpha: 0.12);
      canvas.drawCircle(Offset(ox, oy), maxR, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => t != oldDelegate.t;
}

// ═══════════════════════════════════════════════════════════════
// GLOW DOT — Animated pulsing indicator
// ═══════════════════════════════════════════════════════════════

class GlowDot extends StatefulWidget {
  final double size;
  final Color color;
  const GlowDot({super.key, this.size = 8, this.color = AppColors.primary});

  @override
  State<GlowDot> createState() => _GlowDotState();
}

class _GlowDotState extends State<GlowDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4 + 0.3 * v),
                blurRadius: widget.size * (0.8 + 0.5 * v),
                spreadRadius: widget.size * 0.1 * v,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHIMMER LOADING PLACEHOLDER
// ═══════════════════════════════════════════════════════════════

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-0.5 + 2.0 * _controller.value, 0),
              colors: const [
                AppColors.surfaceRaised,
                AppColors.surfaceHigh,
                AppColors.surfaceRaised,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER — with gradient accent bar
// ═══════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final String? seeAllText;
  final IconData? leadingIcon;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllText,
    this.leadingIcon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    seeAllText ?? 'See all',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PLAY BUTTON — Premium circular with glow
// ═══════════════════════════════════════════════════════════════

class PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;

  const PlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GRADIENT BADGE — For codec / quality labels
// ═══════════════════════════════════════════════════════════════

class GradientBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final bool selected;

  const GradientBadge({
    super.key,
    required this.text,
    this.color,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            c.withValues(alpha: selected ? 0.25 : 0.12),
            c.withValues(alpha: selected ? 0.15 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: c.withValues(alpha: selected ? 0.4 : 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NOW PLAYING INDICATOR — Animated equalizer bars
// ═══════════════════════════════════════════════════════════════

class NowPlayingIndicator extends StatefulWidget {
  final double height;
  final double width;
  final Color color;
  const NowPlayingIndicator({
    super.key,
    this.height = 16,
    this.width = 16,
    this.color = AppColors.primary,
  });

  @override
  State<NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<NowPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _EqualizerPainter(
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _EqualizerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final barWidth = size.width / 5;
    final gap = barWidth * 0.4;

    for (var i = 0; i < 4; i++) {
      final phase = progress * 2 * math.pi + i * 1.2;
      final h = (0.3 + 0.7 * ((math.sin(phase) + 1) / 2)) * size.height;
      final x = i * (barWidth + gap) + gap;
      final radius = Radius.circular(barWidth / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter old) =>
      progress != old.progress;
}

// ═══════════════════════════════════════════════════════════════
// APP GRADIENT SCAFFOLD — Background with animated orbs
// ═══════════════════════════════════════════════════════════════

class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showGradientBg;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showGradientBg = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: showGradientBg ? AnimatedGradientBg(child: body) : body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
