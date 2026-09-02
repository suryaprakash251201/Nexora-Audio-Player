import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

// ═══════════════════════════════════════════════════════════════
// ENHANCED GLASS SURFACE — Multi-layer glassmorphism
// ═══════════════════════════════════════════════════════════════

class EnhancedGlassSurface extends StatelessWidget {
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
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  const EnhancedGlassSurface({
    super.key,
    required this.child,
    this.blur = 30.0,
    this.opacity = 0.5,
    this.borderRadius,
    this.border,
    this.gradient,
    this.showShimmer = true,
    this.showInnerGlow = false,
    this.glowColor,
    this.glowRadius,
    this.shadows,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final isLight = AppColors.mode == AppThemeMode.light;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows ?? [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.28),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          if (showInnerGlow)
            BoxShadow(
              color: (glowColor ?? AppColors.primary).withValues(
                alpha: isLight ? 0.15 : 0.22,
              ),
              blurRadius: glowRadius ?? 48,
              spreadRadius: -4,
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
                    colors: isLight
                        ? [
                            Colors.white.withValues(alpha: 0.88),
                            Colors.white.withValues(alpha: 0.65),
                          ]
                        : [
                            AppColors.glassBase.withValues(alpha: opacity),
                            AppColors.glassBase.withValues(alpha: opacity * 0.6),
                          ],
                  ),
              border:
                  border ??
                  Border.all(
                    color: showInnerGlow
                        ? (glowColor ?? AppColors.primary).withValues(
                            alpha: 0.45,
                          )
                        : (isLight ? AppColors.glassBorder : AppColors.glassBorderStrong),
                    width: showInnerGlow ? 1.0 : 0.6,
                  ),
            ),
            child: Stack(
              children: [
                // Specular top highlight bevel
                if (showShimmer)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: isLight ? 0.25 : 0.12),
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.35, 1.0],
                          ),
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
// GLASS CARD — Interactive with press animation
// ═══════════════════════════════════════════════════════════════

class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool elevated;
  final bool animated;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.elevated = false,
    this.animated = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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

    Widget card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          if (widget.elevated)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.glassBase.withValues(alpha: 0.65),
                  AppColors.glassBase.withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (!widget.animated || widget.onTap == null) return card;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: card,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS CHIP — Small glass badge
// ═══════════════════════════════════════════════════════════════

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
    final radius = borderRadius ?? BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withValues(alpha: 0.12),
            borderRadius: radius,
            border: Border.all(
              color: (color ?? AppColors.primary).withValues(alpha: 0.22),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════

class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final double borderRadius;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceHigh.withValues(alpha: 0.85),
            AppColors.surface.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        border: Border(
          top: BorderSide(color: AppColors.glassBorderStrong, width: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS APP BAR
// ═══════════════════════════════════════════════════════════════

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBottom;
  final PreferredSizeWidget? bottom;
  final double blur;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBottom = false,
    this.bottom,
    this.blur = 25,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.85),
                AppColors.background.withValues(alpha: 0.6),
                AppColors.background.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: leading,
            title: title != null
                ? Text(
                    title!,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  )
                : null,
            actions: actions,
            bottom: bottom,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS FLOATING ACTION BUTTON
// ═══════════════════════════════════════════════════════════════

class GlassFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double size;

  const GlassFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.primaryDark.withValues(alpha: 0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AURORA BACKGROUND — Animated flowing gradient
// ═══════════════════════════════════════════════════════════════

class AuroraBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;

  const AuroraBackground({
    super.key,
    required this.child,
    this.colors = const [
      AppColors.primary,
      AppColors.secondary,
      AppColors.tertiary,
      Color(0xFF7C3AED),
    ],
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
        Container(color: AppColors.background),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _AuroraPainter(
                t: _controller.value,
                colors: widget.colors,
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.5),
                AppColors.background.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final List<Color> colors;

  _AuroraPainter({required this.t, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 100);

    // Create flowing aurora bands
    for (var band = 0; band < 3; band++) {
      final path = Path();
      final baseY = size.height * (0.15 + band * 0.25);
      final amplitude = size.height * 0.08;
      final frequency = 0.003 + band * 0.001;
      final speed = t * math.pi * 2 + band * 2.0;

      path.moveTo(0, baseY);

      for (double x = 0; x <= size.width; x += 10) {
        final y = baseY +
            math.sin(x * frequency + speed) * amplitude +
            math.sin(x * frequency * 2.3 + speed * 1.5) * amplitude * 0.5;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final colorIndex = band % colors.length;
      paint.color = colors[colorIndex].withValues(alpha: 0.06 + band * 0.02);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => t != old.t;
}

// ═══════════════════════════════════════════════════════════════
// GLASS DIALOG
// ═══════════════════════════════════════════════════════════════

class GlassDialog extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassDialog({
    super.key,
    required this.child,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.glassBase.withValues(alpha: 0.7),
                  AppColors.glassBase.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.glassBorderStrong,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NEON GLOW BUTTON
// ═══════════════════════════════════════════════════════════════

class NeonGlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;
  final double height;

  const NeonGlowButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color = AppColors.primary,
    this.height = 56,
  });

  @override
  State<NeonGlowButton> createState() => _NeonGlowButtonState();
}

class _NeonGlowButtonState extends State<NeonGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = 1.0 - _controller.value * 0.03;
          return Transform.scale(
            scale: scale,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
