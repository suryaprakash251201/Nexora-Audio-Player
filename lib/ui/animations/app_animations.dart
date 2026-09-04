import 'package:flutter/material.dart';

import '../theme.dart';

/// Calm background — used as a top-level surface wrapper. The Hi-Fi
/// redesign uses a solid near-black; this widget just paints that.
class AnimatedGradientBg extends StatelessWidget {
  final List<Color> colors;
  final double blur;
  final Widget child;
  final bool enableOrbs;

  const AnimatedGradientBg({
    super.key,
    this.colors = const [AppColors.accent, AppColors.accent],
    this.blur = 0,
    required this.child,
    this.enableOrbs = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.background, child: child);
  }
}

/// Floating particles replaced with a no-op widget. Kept so legacy imports
/// still compile.
class FloatingParticles extends StatelessWidget {
  final int particleCount;
  final Color? color;
  final double maxSize;

  const FloatingParticles({
    super.key,
    this.particleCount = 0,
    this.color,
    this.maxSize = 0,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Glass-morphism container — replaced with a calm surface card. Kept so
/// legacy call sites still compile.
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
    this.blur = 0,
    this.opacity = 1,
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
    final radius = borderRadius ?? BorderRadius.circular(12);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surface,
        gradient: gradient,
        border: border ?? Border.all(color: AppColors.border, width: 0.6),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Animated glass card — calm press-scale only.
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
    this.borderRadius = 12,
    this.elevated = false,
    this.duration = const Duration(milliseconds: 180),
  });

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final card = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: ClipRRect(borderRadius: radius, child: widget.child),
    );

    if (widget.onTap == null) return card;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: card,
      ),
    );
  }
}

/// Staggered list wrapper. Same API as the original; builds a column /
/// row with timed entries. Animation is calmer and only used in legacy
/// spots — new code should use plain lists.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration delay;
  final Duration duration;
  final Axis direction;
  final double spacing;

  const StaggeredList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 320),
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
        return _StaggeredItem(
          delay: delay * i,
          duration: duration,
          child: children[i],
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
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
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
          child: Transform.translate(offset: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Pulse ring — replaced with a static circle outline. Kept for API compat.
class PulseRing extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size);
  }
}

/// Rotating gradient border — replaced with a static hairline border.
class RotatingGradientBorder extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final List<Color> colors;
  final double borderRadius;
  final Duration duration;

  const RotatingGradientBorder({
    super.key,
    required this.child,
    this.borderWidth = 1,
    this.colors = const [AppColors.accent, AppColors.accent],
    this.borderRadius = 12,
    this.duration = const Duration(seconds: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// Breathing glow — replaced with no decoration.
class BreathingGlow extends StatelessWidget {
  final Widget child;
  final Color color;
  final double maxBlur;
  final Duration duration;

  const BreathingGlow({
    super.key,
    required this.child,
    this.color = AppColors.accent,
    this.maxBlur = 0,
    this.duration = const Duration(milliseconds: 2500),
  });

  @override
  Widget build(BuildContext context) => child;
}

/// Slide-in animation used across lists. Kept for legacy call sites.
class SlideInAnimation extends StatefulWidget {
  final Widget child;
  final AxisDirection direction;
  final Duration duration;
  final Duration delay;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.direction = AxisDirection.up,
    this.duration = const Duration(milliseconds: 320),
    this.delay = Duration.zero,
  });

  @override
  State<SlideInAnimation> createState() => _SlideInAnimationState();
}

class _SlideInAnimationState extends State<SlideInAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Offset begin;
    switch (widget.direction) {
      case AxisDirection.up:
        begin = const Offset(0, 8);
        break;
      case AxisDirection.down:
        begin = const Offset(0, -8);
        break;
      case AxisDirection.left:
        begin = const Offset(8, 0);
        break;
      case AxisDirection.right:
        begin = const Offset(-8, 0);
        break;
    }
    _slide = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
      builder: (_, _) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: _slide.value, child: widget.child),
        );
      },
    );
  }
}

/// Scale-bounce — quiet one-shot scale, no overshoot.
class ScaleBounce extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ScaleBounce({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.delay = Duration.zero,
  });

  @override
  State<ScaleBounce> createState() => _ScaleBounceState();
}

class _ScaleBounceState extends State<ScaleBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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
      animation: _scale,
      builder: (_, _) {
        return Transform.scale(scale: _scale.value, child: widget.child);
      },
    );
  }
}
