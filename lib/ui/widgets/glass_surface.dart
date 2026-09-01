import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Premium glassmorphism surface with layered blur, gradient tint,
/// border shimmer, and optional inner glow — Apple Music / iOS-style.
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
    this.blur = 25.0,
    this.opacity = 0.5,
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
    final radius = borderRadius ?? BorderRadius.circular(20);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.glassBase.withOpacity(opacity),
                    AppColors.glassBase.withOpacity(opacity * 0.6),
                  ],
                ),
            border:
                border ?? Border.all(color: AppColors.glassBorder, width: 0.5),
            boxShadow: [
              if (showInnerGlow)
                BoxShadow(
                  color: (glowColor ?? AppColors.primary).withValues(
                    alpha: 0.08,
                  ),
                  blurRadius: glowRadius ?? 30,
                  spreadRadius: -5,
                  inset: true,
                ),
            ],
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
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.3, 1.0],
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
    );
  }
}

/// A smaller glass chip for badges, tags, and inline labels.
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
    final radius = borderRadius ?? BorderRadius.circular(10);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(
              color: (color ?? AppColors.primary).withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass card with a subtle animated shimmer border on hover/tap.
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
    this.borderRadius = 20,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.glassBase.withOpacity(0.7),
                    AppColors.glassBase.withOpacity(0.4),
                  ],
                ),
                border: Border.all(color: AppColors.glassBorder, width: 0.5),
                boxShadow: [
                  if (elevated)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
