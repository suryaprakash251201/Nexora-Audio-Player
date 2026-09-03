import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// True glassmorphism surface with [BackdropFilter] blur.
/// Used for floating chrome: nav bar, mini player, app bars, sheets.
class NexoraGlass extends StatelessWidget {
  const NexoraGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blur = 22,
    this.tintAlpha = 0.55,
    this.borderAlpha = 0.35,
    this.borderWidth = 0.6,
    this.highlightAlpha = 0.18,
    this.shadow,
    this.border,
    this.gradient,
    this.clip = true,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double tintAlpha;
  final double highlightAlpha;
  final double borderAlpha;
  final double borderWidth;
  final Border? border;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final isDark = AppColors.mode == AppThemeMode.dark;

    final tintColor = isDark
        ? Colors.black.withValues(alpha: tintAlpha)
        : Colors.white.withValues(alpha: tintAlpha);

    final defaultBorder = Border.all(
      color: (isDark ? Colors.white : Colors.black).withValues(
        alpha: borderAlpha,
      ),
      width: borderWidth,
    );

    Widget inner = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient != null ? null : tintColor,
            borderRadius: radius,
            gradient: gradient,
            border: border ?? defaultBorder,
          ),
          child: Stack(
            children: [
              // Top specular highlight — soft studio light.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: highlightAlpha),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.50],
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );

    if (!clip) inner = ClipRect(child: inner);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            shadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.11),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: inner,
    );
  }
}

/// Optimized glass dock for the bottom navigation bar.
/// Pinned to the very bottom with refined blur and tighter margins.
/// 2.0: true floating pill — 14px margins, 28px radius, heavier blur.
class NexoraGlassDock extends StatelessWidget {
  const NexoraGlassDock({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    this.margin = const EdgeInsets.fromLTRB(14, 0, 14, 12),
    this.horizontalMargin = 14,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double horizontalMargin;

  @override
  Widget build(BuildContext context) {
    return NexoraGlass(
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      blur: 32,
      tintAlpha: 0.68,
      borderAlpha: 0.30,
      borderWidth: 0.8,
      child: child,
    );
  }
}

/// Glass for the mini player — matches the dock but slightly less blur
/// so the artwork remains crisp.
/// 2.0: floating card with 20px radius and aurora edge highlight.
class NexoraMiniGlass extends StatelessWidget {
  const NexoraMiniGlass({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NexoraGlass(
      borderRadius: BorderRadius.circular(20),
      padding: EdgeInsets.zero,
      blur: 28,
      tintAlpha: 0.66,
      borderAlpha: 0.28,
      borderWidth: 0.8,
      child: child,
    );
  }
}
