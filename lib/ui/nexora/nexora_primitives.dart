import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_tokens.dart';

/// Frosted-glass sliver-app-bar background.
class NexoraSliverAppBarBackground extends StatelessWidget {
  const NexoraSliverAppBarBackground({super.key, this.blur = 18});

  final double blur;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            // Strong enough that large titles scrolling underneath
            // (playlist detail hero) never collide with bar icons.
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: 0.60,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.hairline.withValues(alpha: 0.8),
                width: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact section header used throughout the redesign.
class NexoraSectionHeader extends StatelessWidget {
  final String label;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  final Color? accent;
  final Widget? trailing;

  const NexoraSectionHeader({
    super.key,
    required this.label,
    this.action,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 12),
    this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.accent;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (action != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action!,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Tactile press-feedback wrapper used by Nexora controls.
class NexoraPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;

  const NexoraPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<NexoraPressable> createState() => _NexoraPressableState();
}

class _NexoraPressableState extends State<NexoraPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: widget.onTap == null ? null : () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: NexoraDuration.tap,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Minimal text button used in actions rows.
/// 2.0: primary uses the aurora gradient with glow; secondary is frosted card.
class NexoraTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool primary;
  final EdgeInsets padding;
  final bool fullWidth;

  const NexoraTextButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.primary = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final btn = NexoraPressable(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: primary ? AppColors.accentGradient : null,
          color: primary ? null : AppColors.card,
          borderRadius: NexoraRadius.button,
          border: Border.all(
            color: primary
                ? Colors.white.withValues(alpha: 0.18)
                : AppColors.border.withValues(alpha: 0.9),
            width: 0.8,
          ),
          boxShadow: primary
              ? NexoraShadow.glow(isDark)
              : NexoraShadow.card(isDark),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: fullWidth
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 17,
                color: primary ? AppColors.onAccent : AppColors.text,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: primary ? AppColors.onAccent : AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
    return btn;
  }
}

/// Calm square icon button used in the full player and the equalizer.
/// 2.0: tonal pill background, 16px radius, active = aurora tint + glow ring.
class NexoraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final double size;
  final double iconSize;
  final Color? color;
  final String? tooltip;

  const NexoraIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.active = false,
    this.size = 46,
    this.iconSize = 20,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? AppColors.accent : AppColors.text);
    final btn = NexoraPressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.card.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? AppColors.accent.withValues(alpha: 0.35)
                : AppColors.border.withValues(alpha: 0.8),
            width: 0.8,
          ),
        ),
        child: Icon(icon, size: iconSize, color: c),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

/// Calm empty-state used by every list.
/// 2.0: frosted icon tile with aurora tint + bolder title.
class NexoraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const NexoraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.18),
                    AppColors.accentCyan.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: AppColors.accent, size: 26),
            ),
            const SizedBox(height: NexoraSpacing.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: NexoraSpacing.s8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: NexoraSpacing.s20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Quiet vertical divider used by settings rows.
class NexoraDivider extends StatelessWidget {
  final double indent;
  final double endIndent;
  const NexoraDivider({super.key, this.indent = 20, this.endIndent = 20});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: indent,
      endIndent: endIndent,
      color: AppColors.hairline,
    );
  }
}

/// Compact a11y label for icon-only buttons.
class NexoraIconLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const NexoraIconLabel({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped small tag with subtle accent or neutral fill.
/// 2.0: gradient-aware, 10px radius, bolder tracking.
class NexoraTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool solid;

  const NexoraTag({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: solid ? AppColors.accentGradient : null,
        color: solid
            ? null
            : c.withValues(
                alpha: AppColors.mode == AppThemeMode.dark ? 0.15 : 0.10,
              ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: solid
              ? Colors.white.withValues(alpha: 0.20)
              : c.withValues(
                  alpha: AppColors.mode == AppThemeMode.dark ? 0.32 : 0.22,
                ),
          width: 0.8,
        ),
        boxShadow: solid
            ? NexoraShadow.glow(AppColors.mode == AppThemeMode.dark, color: c)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: solid ? Colors.white : c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: solid ? Colors.white : c,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
