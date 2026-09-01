import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
// ENHANCED ANIMATED GRADIENT BACKGROUND — Multi-orb system
// ═══════════════════════════════════════════════════════════════

class AnimatedGradientBg extends StatefulWidget {
  final List<Color> colors;
  final double blur;
  final Widget child;
  final bool enableOrbs;

  const AnimatedGradientBg({
    super.key,
    this.colors = const [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
    ],
    this.blur = 80,
    required this.child,
    this.enableOrbs = true,
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
      duration: const Duration(seconds: 20),
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
        // Mesh gradient noise texture
        if (widget.enableOrbs)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _MeshGradientPainter(
                  t: _controller.value,
                  colors: widget.colors,
                  blur: widget.blur,
                ),
              );
            },
          ),
        // Subtle noise overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.3),
                AppColors.background.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final double blur;

  _MeshGradientPainter({
    required this.t,
    required this.colors,
    required this.blur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(size.width, size.height) * 0.45;

    // Main orbiting orbs
    for (var i = 0; i < colors.length; i++) {
      final angle = t * 2 * math.pi + (i * 2 * math.pi / colors.length);
      final offset = maxR * 0.5;
      final ox = cx + math.cos(angle) * offset;
      final oy = cy + math.sin(angle * 0.6 + i * 0.8) * offset * 0.5;
      paint.color = colors[i].withValues(alpha: 0.08 + 0.04 * math.sin(t * math.pi * 2 + i));
      canvas.drawCircle(Offset(ox, oy), maxR * (0.8 + 0.2 * math.sin(t * math.pi + i)), paint);
    }

    // Secondary smaller orbs
    for (var i = 0; i < 3; i++) {
      final angle = -t * 1.5 * math.pi + (i * 2.1);
      final offset = maxR * 0.7;
      final ox = cx + math.cos(angle) * offset;
      final oy = cy + math.sin(angle * 0.8) * offset * 0.4;
      final color = colors[(i + 1) % colors.length];
      paint.color = color.withValues(alpha: 0.04);
      canvas.drawCircle(Offset(ox, oy), maxR * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter old) => t != old.t;
}

// ═══════════════════════════════════════════════════════════════
// FLOATING PARTICLES — Ambient dust/particle effect
// ═══════════════════════════════════════════════════════════════

class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color? color;
  final double maxSize;

  const FloatingParticles({
    super.key,
    this.particleCount = 30,
    this.color,
    this.maxSize = 4,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _particles = List.generate(
      widget.particleCount,
      (i) => _Particle.random(),
    );
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
          size: MediaQuery.of(context).size,
          painter: _ParticlesPainter(
            progress: _controller.value,
            particles: _particles,
            color: widget.color ?? AppColors.primary,
            maxSize: widget.maxSize,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.phase,
  });

  factory _Particle.random() {
    return _Particle(
      x: math.Random().nextDouble(),
      y: math.Random().nextDouble(),
      speed: 0.1 + math.Random().nextDouble() * 0.3,
      size: 0.3 + math.Random().nextDouble() * 0.7,
      phase: math.Random().nextDouble() * math.pi * 2,
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Color color;
  final double maxSize;

  _ParticlesPainter({
    required this.progress,
    required this.particles,
    required this.color,
    required this.maxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = ((p.y + progress * p.speed) % 1.0) * size.height;
      final x = p.x * size.width + math.sin(progress * math.pi * 2 + p.phase) * 20;
      final alpha = 0.03 + 0.04 * math.sin(progress * math.pi * 2 + p.phase);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxSize * p.size);

      canvas.drawCircle(Offset(x, y), maxSize * p.size * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════
// GLASS MORPHISM CONTAINER — Enhanced with depth
// ═══════════════════════════════════════════════════════════════

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;
  final Gradient? gradient;
  final bool showShimmer;
  final bool showInnerGlow;
  final Color? glowColor;
  final double? glowRadius;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.opacity = 0.45,
    this.borderRadius,
    this.border,
    this.gradient,
    this.showShimmer = true,
    this.showInnerGlow = false,
    this.glowColor,
    this.glowRadius,
    this.boxShadow,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          if (showInnerGlow)
            BoxShadow(
              color: (glowColor ?? AppColors.primary).withValues(alpha: 0.1),
              blurRadius: glowRadius ?? 40,
              spreadRadius: -5,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient:
                  gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.glassBase.withValues(
                        alpha: opacity,
                      ),
                      AppColors.glassBase.withValues(
                        alpha: opacity * 0.5,
                      ),
                    ],
                  ),
              border:
                  border ??
                  Border.all(
                    color: showInnerGlow
                        ? (glowColor ?? AppColors.primary).withValues(
                            alpha: 0.3,
                          )
                        : AppColors.glassBorder,
                    width: showInnerGlow ? 1.0 : 0.5,
                  ),
            ),
            child: Stack(
              children: [
                // Top shimmer highlight
                if (showShimmer)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.25, 1.0],
                        ),
                      ),
                    ),
                  ),
                // Inner content
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED GLASS CARD — With hover/tap scale effect
// ═══════════════════════════════════════════════════════════════

class AnimatedGlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool elevated;
  final Duration duration;

  const AnimatedGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.elevated = false,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  if (widget.elevated)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.glassBase.withValues(alpha: 0.6),
                          AppColors.glassBase.withValues(alpha: 0.3),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 0.5,
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAGGERED ANIMATION WRAPPER
// ═══════════════════════════════════════════════════════════════

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Axis direction;
  final double spacing;

  const StaggeredList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.direction = Axis.vertical,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: direction == Axis.horizontal ? Axis.horizontal : Axis.vertical,
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(children.length, (index) {
        return _StaggeredItem(
          delay: delay * index,
          duration: duration,
          child: children[index],
        );
      }),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final Widget child;

  const _StaggeredItem({
    required this.delay,
    required this.duration,
    required this.child,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PULSE RING ANIMATION
// ═══════════════════════════════════════════════════════════════

class PulseRing extends StatefulWidget {
  final double size;
  final Color color;
  final int ringCount;
  final Duration duration;

  const PulseRing({
    super.key,
    this.size = 100,
    this.color = AppColors.primary,
    this.ringCount = 3,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
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
        return Stack(
          alignment: Alignment.center,
          children: List.generate(widget.ringCount, (i) {
            final delay = i / widget.ringCount;
            final t = ((_controller.value - delay) % 1.0 + 1.0) % 1.0;
            final scale = 0.5 + t * 0.8;
            final opacity = (1.0 - t) * 0.3;

            return Container(
              width: widget.size * scale,
              height: widget.size * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: opacity),
                  width: 1.5,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROTATING GRADIENT BORDER
// ═══════════════════════════════════════════════════════════════

class RotatingGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final List<Color> colors;
  final double borderRadius;
  final Duration duration;

  const RotatingGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 2,
    this.colors = const [AppColors.primary, AppColors.secondary, AppColors.tertiary],
    this.borderRadius = 24,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<RotatingGradientBorder> createState() => _RotatingGradientBorderState();
}

class _RotatingGradientBorderState extends State<RotatingGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
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
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: [...widget.colors, widget.colors.first],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth),
                color: AppColors.background,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BREATHING GLOW EFFECT
// ═══════════════════════════════════════════════════════════════

class BreathingGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double maxBlur;
  final Duration duration;

  const BreathingGlow({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.maxBlur = 30,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
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
        final blur = widget.maxBlur * (0.3 + 0.7 * _controller.value);
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2 + 0.2 * _controller.value),
                blurRadius: blur,
                spreadRadius: blur * 0.2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SLIDE IN ANIMATION
// ═══════════════════════════════════════════════════════════════

class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final AxisDirection direction;
  final Duration duration;
  final Duration delay;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.direction = AxisDirection.up,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    Offset begin;
    switch (widget.direction) {
      case AxisDirection.up:
        begin = const Offset(0, 16);
        break;
      case AxisDirection.down:
        begin = const Offset(0, -16);
        break;
      case AxisDirection.left:
        begin = const Offset(16, 0);
        break;
      case AxisDirection.right:
        begin = const Offset(-16, 0);
        break;
    }

    _slideAnimation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        final scale = 0.97 + 0.03 * _opacityAnimation.value;
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: Transform.scale(
              scale: scale,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SCALE BOUNCE ANIMATION
// ═══════════════════════════════════════════════════════════════

class ScaleBounce extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ScaleBounce({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
  });

  @override
  State<ScaleBounce> createState() => _ScaleBounceState();
}

class _ScaleBounceState extends State<ScaleBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.1), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}
