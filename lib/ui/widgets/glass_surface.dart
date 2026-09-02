import 'package:flutter/material.dart';

import '../theme.dart';

/// Hi-Fi replacement for the original glassmorphism surface.
///
/// Renders a flat surface card with a hairline border, minimal elevation
/// and no blur/glass sheen — keeping the editorial calm of the redesign.
class GlassSurface extends StatelessWidget {
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

  const GlassSurface({
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
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surface,
        gradient: gradient,
        border: border ?? Border.all(color: AppColors.border, width: 0.6),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Subdued chip replacement — minimal padding, hairline border, accent ink.
class GlassChip extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const GlassChip({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accent;
    final radius = borderRadius ?? BorderRadius.circular(8);
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: radius,
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.6),
      ),
      child: child,
    );
  }
}

/// Card replacement: flat, hairline-bordered, no shadow / blur.
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool elevated;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}
