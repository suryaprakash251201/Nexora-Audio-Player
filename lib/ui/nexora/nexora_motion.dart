import 'dart:async';

import 'package:flutter/material.dart';

/// Motion language for the Nexora Hi-Fi redesign.
///
/// Every entrance, transition and press response should pull its curve and
/// duration from here, so the product feels like a single object rather than
/// a collection of independently animated screens.
class NexoraMotion {
  NexoraMotion._();

  /// Default curve for anything settling into place.
  static const Curve standard = Curves.easeOutCubic;

  /// Elements arriving on screen.
  static const Curve decelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Elements leaving the screen.
  static const Curve accelerate = Cubic(0.4, 0.0, 1.0, 1.0);

  /// Larger, more deliberate movement (sheets, page swaps).
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Playful confirmation (badges, toggles).
  static const Curve overshoot = Curves.easeOutBack;

  /// Screen entrance duration.
  static const Duration entrance = Duration(milliseconds: 420);

  /// Delay between staggered siblings.
  static const Duration staggerStep = Duration(milliseconds: 55);

  /// Upper bound on stagger delay so late items never feel abandoned.
  static const Duration staggerCap = Duration(milliseconds: 380);
}

/// Fades and lifts its child into place once, on first build.
///
/// Long scrolling screens use this for choreography: wrap each section and
/// pass an increasing [index], or supply an explicit [delay].
class NexoraEntrance extends StatefulWidget {
  const NexoraEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.duration = NexoraMotion.entrance,
    this.slideOffset = 18,
    this.curve = NexoraMotion.decelerate,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final Duration? delay;
  final Duration duration;

  /// Vertical distance (in logical pixels) the child travels while fading in.
  final double slideOffset;
  final Curve curve;

  /// When false the child is simply painted in its final state.
  final bool enabled;

  @override
  State<NexoraEntrance> createState() => _NexoraEntranceState();
}

class _NexoraEntranceState extends State<NexoraEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _opacity = curved;
    _offset = Tween<double>(
      begin: widget.slideOffset,
      end: 0,
    ).animate(curved);

    if (!widget.enabled) {
      _controller.value = 1;
      return;
    }

    final raw = widget.delay ?? NexoraMotion.staggerStep * widget.index;
    final wait = raw > NexoraMotion.staggerCap ? NexoraMotion.staggerCap : raw;
    unawaited(_playAfter(wait));
  }

  Future<void> _playAfter(Duration wait) async {
    await Future<void>.delayed(wait);
    if (mounted) await _controller.forward();
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
      builder: (context, child) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _offset.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// A [Column] whose children animate in one after another.
class NexoraStaggeredColumn extends StatelessWidget {
  const NexoraStaggeredColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.step = NexoraMotion.staggerStep,
    this.slideOffset = 18,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration step;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          NexoraEntrance(
            delay: step * i,
            slideOffset: slideOffset,
            child: children[i],
          ),
      ],
    );
  }
}

/// Animates a numeric value from zero up to [value].
///
/// Used by the listening-stats screen so figures feel like they are being
/// counted rather than simply printed.
class NexoraCountUp extends StatefulWidget {
  const NexoraCountUp({
    super.key,
    required this.value,
    this.fractionDigits = 0,
    this.duration = const Duration(milliseconds: 900),
    this.curve = NexoraMotion.decelerate,
    this.prefix,
    this.suffix,
    this.style,
  });

  final double value;
  final int fractionDigits;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;
  final TextStyle? style;

  @override
  State<NexoraCountUp> createState() => _NexoraCountUpState();
}

class _NexoraCountUpState extends State<NexoraCountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    unawaited(_controller.forward());
  }

  @override
  void didUpdateWidget(covariant NexoraCountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      unawaited(_controller.forward(from: 0));
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
      animation: _animation,
      builder: (context, _) => Text(
        '${widget.prefix ?? ''}'
        '${_animation.value.toStringAsFixed(widget.fractionDigits)}'
        '${widget.suffix ?? ''}',
        style: widget.style,
      ),
    );
  }
}
