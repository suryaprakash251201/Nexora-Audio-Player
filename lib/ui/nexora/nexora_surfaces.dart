import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_icons.dart';
import 'nexora_primitives.dart';
import 'nexora_tokens.dart';

/// Slow-moving ambient light that sits behind a screen's content.
/// Faint depth without competing with artwork. Wrapped in [RepaintBoundary].
class NexoraAurora extends StatefulWidget {
  const NexoraAurora({
    super.key,
    this.intensity = 1,
    this.tint,
    this.duration = const Duration(seconds: 18),
  });

  final double intensity;
  final Color? tint;
  final Duration duration;

  @override
  State<NexoraAurora> createState() => _NexoraAuroraState();
}

class _NexoraAuroraState extends State<NexoraAurora>
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
    return RepaintBoundary(
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _AuroraPainter(
              progress: _controller.value,
              intensity: widget.intensity,
              tint: widget.tint ?? AppColors.accent,
              background: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.progress,
    required this.intensity,
    required this.tint,
    required this.background,
  });

  final double progress;
  final double intensity;
  final Color tint;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final shortest = size.shortestSide;
    final blobs = <_Blob>[
      _Blob(
        center: Offset(
          size.width * (0.18 + 0.06 * progress),
          size.height * 0.16,
        ),
        radius: shortest * 1.05,
        color: tint,
        alpha: 0.20,
      ),
      _Blob(
        center: Offset(
          size.width * (0.88 - 0.08 * progress),
          size.height * 0.34,
        ),
        radius: shortest * 0.85,
        color: AppColors.accentSoft,
        alpha: 0.13,
      ),
      _Blob(
        center: Offset(
          size.width * (0.5 + 0.05 * progress),
          size.height * 0.94,
        ),
        radius: shortest * 0.95,
        color: tint,
        alpha: 0.09,
      ),
    ];

    for (final blob in blobs) {
      final effectiveAlpha = blob.alpha * intensity;
      if (effectiveAlpha <= 0) continue;
      canvas.drawCircle(
        blob.center,
        blob.radius,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  blob.color.withValues(alpha: effectiveAlpha),
                  blob.color.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: blob.center, radius: blob.radius),
              ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.tint != tint ||
      oldDelegate.background != background;
}

class _Blob {
  const _Blob({
    required this.center,
    required this.radius,
    required this.color,
    required this.alpha,
  });

  final Offset center;
  final double radius;
  final Color color;
  final double alpha;
}

/// Premium card with subtle gradient, refined border and layered shadows.
/// The default surface for hero cards, stat tiles and featured content.
class NexoraGradientCard extends StatelessWidget {
  const NexoraGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius,
    this.tint,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? NexoraRadius.card;
    final accent = tint ?? AppColors.accent;
    final isDark = AppColors.mode == AppThemeMode.dark;

    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppColors.border.withValues(alpha: 0.9)
              : AppColors.border.withValues(alpha: 0.7),
          width: 0.8,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppColors.card : Colors.white,
            Color.alphaBlend(
              accent.withValues(alpha: isDark ? 0.08 : 0.05),
              isDark ? AppColors.card : Colors.white,
            ),
          ],
        ),
        boxShadow: NexoraShadow.card(isDark),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return NexoraPressable(onTap: onTap, child: card);
  }
}

/// Elevated card — solid surface, stronger shadow. Use for grouped
/// settings sections or any content that must clearly float.
class NexoraElevatedCard extends StatelessWidget {
  const NexoraElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final radius = borderRadius ?? NexoraRadius.card;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppColors.border.withValues(alpha: 0.85)
              : AppColors.border,
          width: 0.7,
        ),
        boxShadow: NexoraShadow.card(isDark),
      ),
      child: child,
    );
  }
}

/// Gradient scrim that keeps text legible over artwork.
class NexoraScrim extends StatelessWidget {
  const NexoraScrim({
    super.key,
    this.topStrength = 0,
    this.bottomStrength = 0.65,
    this.baseColor = const Color(0xFF000000),
  });

  final double topStrength;
  final double bottomStrength;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withValues(alpha: topStrength),
            baseColor.withValues(alpha: bottomStrength),
          ],
        ),
      ),
    );
  }
}

/// Small quality badge used to flag lossless / high-resolution audio.
class NexoraHiResBadge extends StatelessWidget {
  const NexoraHiResBadge({
    super.key,
    this.label = 'HI-RES',
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.45),
          width: 0.7,
        ),
        color: AppColors.accent.withValues(alpha: 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexoraGlyph(
            kind: NexoraGlyphKind.hiRes,
            size: compact ? 9 : 11,
            color: AppColors.accent,
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
