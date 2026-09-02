import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
// ENHANCED ANIMATIONS & EFFECTS
// ═══════════════════════════════════════════════════════════════

/// A true glass-morphism container with backdrop blur, subtle border,
/// and optional shimmer/glow effects.
class HiFiGlassContainer extends StatelessWidget {
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

  const HiFiGlassContainer({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.85,
    this.borderRadius,
    this.border,
    this.gradient,
    this.showShimmer = false,
    this.showInnerGlow = false,
    this.glowColor,
    this.glowRadius,
    this.boxShadow,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: AppColors.surface.withValues(alpha: opacity),
              gradient: gradient,
              border:
                  border ??
                  Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 0.6,
                  ),
            ),
            child: Stack(
              children: [
                if (showInnerGlow)
                  Positioned.fill(
                    child: _InnerGlow(
                      color: glowColor ?? AppColors.accent,
                      radius: glowRadius ?? 60,
                    ),
                  ),
                if (showShimmer)
                  Positioned.fill(child: _ShimmerOverlay(borderRadius: radius)),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle inner glow that adds depth to glass surfaces.
class _InnerGlow extends StatelessWidget {
  final Color color;
  final double radius;

  const _InnerGlow({required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          radius: 0.8,
          colors: [color.withValues(alpha: 0.08), Colors.transparent],
        ),
      ),
    );
  }
}

/// Animated shimmer overlay for loading/attention states.
class _ShimmerOverlay extends StatefulWidget {
  final BorderRadiusGeometry? borderRadius;

  const _ShimmerOverlay({this.borderRadius});

  @override
  State<_ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<_ShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
      builder: (_, __) {
        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            alignment: Alignment(-1.4 + (_controller.value * 2.8), 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AMBIENT BACKGROUND EFFECTS
// ═══════════════════════════════════════════════════════════════

/// Animated ambient background with slowly drifting orbs of color.
/// Creates an immersive, living background for the player screen.
class AmbientBackground extends StatefulWidget {
  final List<Color>? colors;
  final int orbCount;
  final Widget child;

  const AmbientBackground({
    super.key,
    this.colors,
    this.orbCount = 3,
    required this.child,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.orbCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 15000 + _random.nextInt(10000)),
      ),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(CurvedAnimation(parent: c, curve: Curves.linear));
    }).toList();

    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].repeat();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.colors ??
        [
          AppColors.accent.withValues(alpha: 0.15),
          AppColors.accentSoft.withValues(alpha: 0.10),
          AppColors.accentDim.withValues(alpha: 0.12),
        ];

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: AppColors.background)),
        ...List.generate(widget.orbCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) {
              final t = _animations[i].value;
              final x = 0.2 + 0.6 * math.sin(t * math.pi * 2 + i * 2.1);
              final y = 0.2 + 0.6 * math.cos(t * math.pi * 2 + i * 1.3);
              return Positioned(
                left: x * MediaQuery.of(context).size.width - 150,
                top: y * MediaQuery.of(context).size.height * 0.6 - 150,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [colors[i % colors.length], Colors.transparent],
                    ),
                  ),
                ),
              );
            },
          );
        }),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox.shrink(),
          ),
        ),
        widget.child,
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENHANCED PRESS & SCALE ANIMATIONS
// ═══════════════════════════════════════════════════════════════

/// A widget that scales down when pressed with haptic feedback.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final bool haptic;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 120),
    this.haptic = true,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, child) =>
            Transform.scale(scale: _animation.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SMOOTH PAGE TRANSITIONS
// ═══════════════════════════════════════════════════════════════

/// A custom page transition that slides up with fade.
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SlideUpPageRoute({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.08);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
      );
}

/// A custom page transition that scales up with fade (hero-like).
class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  ScaleFadePageRoute({required this.child})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;
          var scaleTween = Tween<double>(
            begin: 0.94,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
      );
}

// ═══════════════════════════════════════════════════════════════
// FLOATING PARTICLES (subtle ambient dust)
// ═══════════════════════════════════════════════════════════════

/// Very subtle floating particles for ambient atmosphere.
class FloatingDust extends StatefulWidget {
  final int count;
  final Color? color;
  final double maxSize;

  const FloatingDust({
    super.key,
    this.count = 15,
    this.color,
    this.maxSize = 2.5,
  });

  @override
  State<FloatingDust> createState() => _FloatingDustState();
}

class _FloatingDustState extends State<FloatingDust>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.count,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 8000 + _random.nextInt(12000)),
      )..repeat(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: List.generate(widget.count, (i) {
        final seed = i * 1.618;
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) {
            final t = _controllers[i].value;
            final x =
                (math.sin(t * math.pi * 2 + seed) * 0.4 + 0.5) * size.width;
            final y =
                (math.cos(t * math.pi * 2 + seed * 0.7) * 0.3 + t * 0.4) *
                size.height;
            final opacity =
                (math.sin(t * math.pi * 2 + seed * 2) + 1) / 2 * 0.3;
            final particleSize = widget.maxSize * (0.5 + (i % 3) * 0.25);
            return Positioned(
              left: x,
              top: y,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: particleSize,
                  height: particleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (widget.color ?? AppColors.accent).withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BREATHING GLOW EFFECT
// ═══════════════════════════════════════════════════════════════

/// A breathing glow that pulses around a child widget.
class BreathingGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double maxBlur;
  final Duration duration;

  const BreathingGlow({
    super.key,
    required this.child,
    this.color = AppColors.accent,
    this.maxBlur = 24,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
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
      builder: (_, child) {
        final blur = widget.maxBlur * (0.3 + 0.7 * _controller.value);
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 * _controller.value),
                blurRadius: blur,
                spreadRadius: blur * 0.3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROTATING GRADIENT BORDER
// ═══════════════════════════════════════════════════════════════

/// A rotating gradient border that adds a premium feel to artwork.
class RotatingGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final List<Color> colors;
  final double borderRadius;
  final Duration duration;
  final bool animate;

  const RotatingGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 1.5,
    this.colors = const [
      AppColors.accent,
      AppColors.accentSoft,
      AppColors.accent,
    ],
    this.borderRadius = 16,
    this.duration = const Duration(seconds: 4),
    this.animate = true,
  });

  @override
  State<RotatingGradientBorder> createState() => _RotatingGradientBorderState();
}

class _RotatingGradientBorderState extends State<RotatingGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RotatingGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Container(
          padding: EdgeInsets.all(widget.borderWidth),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: widget.colors,
              transform: GradientRotation(_controller.value * math.pi * 2),
            ),
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 2),
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAGGERED LIST ANIMATION (enhanced)
// ═══════════════════════════════════════════════════════════════

/// Enhanced staggered list with fade + slide + scale.
class StaggeredFadeList extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Axis direction;
  final double spacing;

  const StaggeredFadeList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 40),
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
      children: List.generate(children.length, (i) {
        return _StaggeredFadeItem(
          delay: delay * i,
          duration: duration,
          child: children[i],
        );
      }),
    );
  }
}

class _StaggeredFadeItem extends StatefulWidget {
  final Duration delay;
  final Duration duration;
  final Widget child;

  const _StaggeredFadeItem({
    required this.delay,
    required this.duration,
    required this.child,
  });

  @override
  State<_StaggeredFadeItem> createState() => _StaggeredFadeItemState();
}

class _StaggeredFadeItemState extends State<_StaggeredFadeItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 16),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
      builder: (_, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: Transform.scale(scale: _scale.value, child: child),
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

/// Animated pulse rings that emanate from a center point.
class PulseRing extends StatefulWidget {
  final double size;
  final Color color;
  final int ringCount;
  final Duration duration;

  const PulseRing({
    super.key,
    this.size = 100,
    this.color = AppColors.accent,
    this.ringCount = 3,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.ringCount,
      (i) => AnimationController(vsync: this, duration: widget.duration),
    );
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(
        Duration(
          milliseconds:
              (widget.duration.inMilliseconds ~/ widget.ringCount) * i,
        ),
        () {
          if (mounted) _controllers[i].repeat();
        },
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(widget.ringCount, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) {
              final t = _controllers[i].value;
              return Container(
                width: widget.size * (0.4 + t * 0.6),
                height: widget.size * (0.4 + t * 0.6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: (1 - t) * 0.3),
                    width: 1.5,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SPRING ANIMATION HELPER
// ═══════════════════════════════════════════════════════════════

/// A spring-based animation for bouncy, natural motion.
class SpringAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const SpringAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<SpringAnimation> createState() => _SpringAnimationState();
}

class _SpringAnimationState extends State<SpringAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
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
      animation: _animation,
      builder: (_, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
