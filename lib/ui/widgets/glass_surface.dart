import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry? borderRadius;
  final Border? border;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.45,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: opacity), // Apple Music dark mode glass color
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border:
                border ??
                Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }
}
