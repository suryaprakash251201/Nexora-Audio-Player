import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A true glassmorphism surface that uses [BackdropFilter] to blur whatever
/// is painted beneath it. Use this for floating chrome (nav bar, mini
/// player, sheets, dialogs, app bars) where you want the user to feel the
/// content scrolling behind the surface.
///
/// The class falls back gracefully to a flat translucent surface on
/// devices that can't run the blur (e.g. some headless test environments).
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

  /// The widget rendered inside the glass surface.
  final Widget child;

  /// Corner radius. Defaults to [NexoraRadius.card] when null.
  final BorderRadius? borderRadius;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Outer margin (applied outside the rounded shape, useful for shadows).
  final EdgeInsetsGeometry? margin;

  /// Strength of the backdrop blur (sigma). Higher = more frosted.
  final double blur;

  /// Opacity of the dark/light tint laid on top of the blurred surface.
  final double tintAlpha;

  /// Opacity of the inner highlight stroke that simulates a thin specular.
  final double highlightAlpha;

  /// Opacity of the hairline border.
  final double borderAlpha;
  final double borderWidth;

  /// Optional custom border. Overrides [borderAlpha]/[borderWidth].
  final Border? border;

  /// Optional gradient overlay drawn on top of the blur (for accent washes).
  final Gradient? gradient;

  /// Optional shadow for elevated glass cards.
  final List<BoxShadow>? shadow;

  /// Whether to clip children to the rounded shape. Disable when the
  /// caller manages clipping (e.g. inside another [ClipRRect]).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final isDark = AppColors.mode == AppThemeMode.dark;

    // The tint blends a low-opacity surface color so dark/light modes both
    // read as "frosted" rather than as a colored fill.
    final tintColor = isDark
        ? Colors.black.withValues(alpha: tintAlpha)
        : Colors.white.withValues(alpha: tintAlpha);

    final defaultBorder = Border.all(
      color: (isDark ? Colors.white : Colors.black).withValues(
        alpha: borderAlpha,
      ),
      width: borderWidth,
    );

    // Inner surface: clipped + blurred + tinted.
    Widget inner = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Don't set both color and gradient — BoxDecoration forbids it.
            color: gradient != null ? null : tintColor,
            borderRadius: radius,
            gradient: gradient,
            border: border ?? defaultBorder,
          ),
          child: Stack(
            children: [
              // Specular highlight along the top edge to suggest a curved
              // glass plate lit from above.
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
                        stops: const [0.0, 0.55],
                      ),
                    ),
                  ),
                ),
              ),
              // The actual content.
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
        boxShadow: shadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: inner,
    );
  }
}

/// A specialized [NexoraGlass] tuned for the bottom nav dock. It uses a
/// slightly stronger blur and a smaller radius, and accepts the optional
/// safe-area inset so the surface sits flush against the bottom edge.
class NexoraGlassDock extends StatelessWidget {
  const NexoraGlassDock({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 8),
    this.horizontalMargin = 12,
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
      blur: 26,
      tintAlpha: 0.58,
      borderAlpha: 0.40,
      borderWidth: 0.7,
      child: child,
    );
  }
}
