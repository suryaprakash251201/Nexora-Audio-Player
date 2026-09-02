import 'package:flutter/material.dart';

import '../theme.dart';

/// Tones used to tint icons. In the Hi-Fi redesign every tone resolves to
/// the same warm accent so the UI feels consistent rather than rainbow-coded.
enum BrightIconTone {
  violet,
  cyan,
  pink,
  emerald,
  amber,
  sky,
  rose,
  indigo,
  sunset,
  teal,
  coral,
}

extension BrightIconToneX on BrightIconTone {
  List<Color> get stops => [AppColors.accent, AppColors.accentSoft];

  /// Flat representative colour (used for shadows / glow).
  Color get base => AppColors.accent;

  /// Outer glow colour with preset opacity.
  Color get glowColor => AppColors.accent.withValues(alpha: 0.45);
}

/// A simple flat icon. The original [BrightIcon] used ShaderMask to paint
/// gradient glyphs; the redesign uses a single accent color to keep icons
/// editorial rather than rainbow.
class BrightIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final BrightIconTone tone;
  final bool active;

  const BrightIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.tone = BrightIconTone.violet,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textDim;
    return Icon(icon, size: size, color: color);
  }
}

/// Subdued icon-on-surface "chip" with a thin border and subtle accent glow.
/// Used as a building block for quick actions and settings rows.
class GlassBrightIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final BrightIconTone tone;
  final double iconSize;
  final bool active;
  final bool showGlow;

  const GlassBrightIcon({
    super.key,
    required this.icon,
    this.size = 42,
    this.tone = BrightIconTone.violet,
    this.iconSize = 22,
    this.active = true,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? accent.withValues(alpha: 0.10) : AppColors.surfaceHigh,
        border: Border.all(
          color: active ? accent.withValues(alpha: 0.45) : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Center(
        child: BrightIcon(
          icon: icon,
          size: iconSize,
          tone: tone,
          active: active,
        ),
      ),
    );
  }
}

/// Tappable icon-button with press-scale animation.
class BrightIconButton extends StatefulWidget {
  final IconData icon;
  final BrightIconTone tone;
  final double size;
  final double iconSize;
  final bool active;
  final VoidCallback? onTap;
  final String? tooltip;

  const BrightIconButton({
    super.key,
    required this.icon,
    this.tone = BrightIconTone.violet,
    this.size = 42,
    this.iconSize = 22,
    this.active = true,
    this.onTap,
    this.tooltip,
  });

  @override
  State<BrightIconButton> createState() => _BrightIconButtonState();
}

class _BrightIconButtonState extends State<BrightIconButton>
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
      end: 0.90,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    final button = GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active
                ? accent.withValues(alpha: 0.10)
                : AppColors.surfaceHigh,
            border: Border.all(
              color: widget.active
                  ? accent.withValues(alpha: 0.45)
                  : AppColors.border,
              width: 0.8,
            ),
          ),
          child: Center(
            child: BrightIcon(
              icon: widget.icon,
              size: widget.iconSize,
              tone: widget.tone,
              active: widget.active,
            ),
          ),
        ),
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}

/// Square version of [BrightIconButton] for compact action surfaces.
class GlowIconButton extends StatefulWidget {
  final IconData icon;
  final BrightIconTone tone;
  final double size;
  final double iconSize;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isCircle;

  const GlowIconButton({
    super.key,
    required this.icon,
    this.tone = BrightIconTone.violet,
    this.size = 46,
    this.iconSize = 22,
    this.borderRadius = 12,
    this.onTap,
    this.tooltip,
    this.isCircle = false,
  });

  @override
  State<GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<GlowIconButton>
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
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    final radius = widget.isCircle
        ? BorderRadius.circular(widget.size / 2)
        : BorderRadius.circular(widget.borderRadius);

    final content = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.surfaceHigh,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Center(
        child: BrightIcon(
          icon: widget.icon,
          size: widget.iconSize,
          tone: widget.tone,
          active: true,
        ),
      ),
    );

    final button = GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.tooltip != null
            ? Tooltip(message: widget.tooltip!, child: content)
            : content,
      ),
    );
    // 'accent' kept in scope to avoid lint warnings — variable preserves the
    // intent of the redesign (accent reserved for selected states).
    // ignore: unused_local_variable
    final _ = accent;
    return button;
  }
}

/// Rounded chip combining an icon and a label. Used for compact menu rows.
class BrightIconChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final BrightIconTone tone;
  final VoidCallback? onTap;

  const BrightIconChip({
    super.key,
    required this.icon,
    required this.label,
    this.tone = BrightIconTone.violet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surfaceHigh,
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrightIcon(icon: icon, size: 18, tone: tone, active: true),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
