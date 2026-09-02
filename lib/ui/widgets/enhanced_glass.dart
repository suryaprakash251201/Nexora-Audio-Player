import 'dart:ui';

import 'package:flutter/material.dart';

import '../nexora/nexora_tokens.dart';
import '../theme.dart';

/// Refined flat surface with subtle elevation — the new card baseline.
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
    this.blur = 0,
    this.opacity = 1,
    this.borderRadius,
    this.border,
    this.gradient,
    this.showShimmer = false,
    this.showInnerGlow = false,
    this.glowColor,
    this.glowRadius,
    this.shadows,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final radius = borderRadius ?? NexoraRadius.card;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: gradient != null ? null : AppColors.card,
        gradient: gradient,
        border: border ?? Border.all(color: AppColors.border, width: 0.7),
        boxShadow: shadows ?? NexoraShadow.card(isDark),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Press-responsive card with refined elevation, spring scale and
/// adaptive light/dark shadows. The primary grouped-card primitive.
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
    this.borderRadius = 16,
    this.elevated = false,
    this.animated = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final radius = BorderRadius.circular(widget.borderRadius);
    final card = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: widget.elevated ? AppColors.cardElevated : AppColors.card,
        border: Border.all(
          color: isDark
              ? AppColors.border.withValues(alpha: 0.9)
              : AppColors.border,
          width: 0.7,
        ),
        boxShadow: widget.elevated
            ? NexoraShadow.floating(isDark)
            : NexoraShadow.card(isDark),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.child,
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
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: card,
      ),
    );
  }
}

/// Compact pill badge — tighter radius, subtle accent wash.
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
    final radius = borderRadius ?? BorderRadius.circular(20);
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.11),
        borderRadius: radius,
        border: Border.all(color: accent.withValues(alpha: 0.30), width: 0.6),
      ),
      child: child,
    );
  }
}

/// Bottom sheet wrapper with refined radius and border treatment.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final double borderRadius;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.border : AppColors.borderStrong,
            width: 0.7,
          ),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF1A2A4A).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

/// Frosted app bar — clips and blurs whatever scrolls underneath.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBottom;
  final PreferredSizeWidget? bottom;
  final double blur;
  final double toolbarHeight;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBottom = false,
    this.bottom,
    this.blur = 22,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final tint = (isDark ? Colors.black : Colors.white).withValues(
      alpha: isDark ? 0.38 : 0.68,
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            border: Border(
              bottom: BorderSide(
                color: AppColors.hairline.withValues(alpha: 0.8),
                width: 0.6,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: AppBar(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: toolbarHeight,
              leading: leading,
              title: title,
              actions: actions,
              bottom: bottom,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double size;

  const GlassFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: isDarkFloat ? 6 : 2,
        shape: const CircleBorder(),
        child: child,
      ),
    );
  }

  bool get isDarkFloat => AppColors.mode == AppThemeMode.dark;
}

class AuroraBackground extends StatelessWidget {
  final Widget child;
  final List<Color> colors;

  const AuroraBackground({
    super.key,
    required this.child,
    this.colors = const [AppColors.accent, AppColors.accent],
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.background, child: child);
  }
}

class GlassDialog extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassDialog({super.key, required this.child, this.borderRadius = 20});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: AppColors.shadowColorStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: AppColors.border, width: 0.7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

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
    this.color = AppColors.accent,
    this.height = 52,
  });

  @override
  State<NeonGlowButton> createState() => _NeonGlowButtonState();
}

class _NeonGlowButtonState extends State<NeonGlowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color;
    final fg = widget.color == AppColors.error
        ? AppColors.text
        : AppColors.onAccent;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => Transform.scale(
          scale: 1.0 - _controller.value * 0.02,
          child: child,
        ),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
