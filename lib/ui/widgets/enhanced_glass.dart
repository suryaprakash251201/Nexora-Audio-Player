import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Hi-Fi replacement for [EnhancedGlassSurface]. Renders a clean, flat
/// surface with hairline borders and minimal elevation. No backdrop blur,
/// no shimmer, no glow orbs.
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
    final radius = borderRadius ?? BorderRadius.circular(12);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surface,
        gradient: gradient,
        border: border ?? Border.all(color: AppColors.border, width: 0.6),
        boxShadow: shadows,
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// Flat press-responsive card with subtle scale animation.
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
    this.borderRadius = 12,
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
      duration: const Duration(milliseconds: 150),
    );
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
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 0.6),
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

/// Compact badge / pill — minimal padding, hairline border, accent ink.
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

/// Bottom sheet wrapper — flat surface, no glass blur. Kept as
/// `GlassBottomSheet` so call sites compile.
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double? height;
  final double borderRadius;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

/// App bar — kept as `GlassAppBar` so legacy call sites compile. The new
/// design uses a clean AppBar directly. When [blur] > 0 the bar renders a
/// translucent frosted surface instead of a flat fill.
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
    this.blur = 18,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final tint = (isDark ? Colors.black : Colors.white).withValues(alpha: 0.35);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: tint,
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

/// FAB replacement. Single accent fill, no glow.
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
        elevation: 1,
        shape: const CircleBorder(),
        child: child,
      ),
    );
  }
}

/// Aurora background — replaced with a solid background. Kept as a class so
/// legacy call sites still compile.
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

/// Glass dialog replacement — flat surface, hairline border.
class GlassDialog extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const GlassDialog({super.key, required this.child, this.borderRadius = 16});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: AppColors.border, width: 0.6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

/// Neon glow button — replaced by a calm, single-accent fill button with
/// scale-on-press.
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
            borderRadius: BorderRadius.circular(10),
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
