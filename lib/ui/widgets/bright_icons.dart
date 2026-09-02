import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Vivid, saturated tones used to tint app icons.
///
/// Each tone resolves to a two-stop gradient so glyphs read as "lit" rather
/// than flat, giving the icon set its bright, glassy look.
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
  /// The two gradient stops for this tone.
  List<Color> get stops {
    switch (this) {
      case BrightIconTone.violet:
        return const [Color(0xFFC084FC), Color(0xFF7C3AED)];
      case BrightIconTone.cyan:
        return const [Color(0xFF38BDF8), Color(0xFF06B6D4)];
      case BrightIconTone.pink:
        return const [Color(0xFFF472B6), Color(0xFFE11D48)];
      case BrightIconTone.emerald:
        return const [Color(0xFF34D399), Color(0xFF059669)];
      case BrightIconTone.amber:
        return const [Color(0xFFFBBF24), Color(0xFFD97706)];
      case BrightIconTone.sky:
        return const [Color(0xFF60A5FA), Color(0xFF2563EB)];
      case BrightIconTone.rose:
        return const [Color(0xFFFB7185), Color(0xFFBE123C)];
      case BrightIconTone.indigo:
        return const [Color(0xFF818CF8), Color(0xFF4338CA)];
      case BrightIconTone.sunset:
        return const [Color(0xFFFF7E5F), Color(0xFFFEB47B)];
      case BrightIconTone.teal:
        return const [Color(0xFF2DD4BF), Color(0xFF0F766E)];
      case BrightIconTone.coral:
        return const [Color(0xFFFF6B6B), Color(0xFFFF8E53)];
    }
  }

  /// Flat representative colour (useful for glows and shadows).
  Color get base => stops.first;

  /// Outer glow color with preset opacity
  Color get glowColor => base.withValues(alpha: 0.45);
}

/// An icon glyph painted with a bright gradient.
///
/// Uses a [ShaderMask] so the gradient fills only the glyph itself, keeping
/// the shape crisp at any size.
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
    final colors = tone.stops;
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: active
            ? colors
            : [AppColors.textDim, AppColors.textDim.withValues(alpha: 0.65)],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}

/// A bright gradient glyph sitting on a glass disc with a soft coloured glow.
///
/// This is the building block for the app icon set: tinted glass, hairline
/// border, inner highlight and an outer bloom when active.
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
    final colors = tone.stops;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: (active && showGlow)
            ? [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.38),
                  blurRadius: size * 0.55,
                  spreadRadius: -size * 0.1,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? colors.first.withValues(alpha: 0.5)
                    : AppColors.glassBorder,
                width: 0.8,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: active
                    ? [
                        colors.first.withValues(alpha: 0.32),
                        colors.last.withValues(alpha: 0.12),
                      ]
                    : [
                        AppColors.glassBase.withValues(alpha: 0.4),
                        AppColors.glassBase.withValues(alpha: 0.15),
                      ],
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
          ),
        ),
      ),
    );
  }
}

/// Tappable version of [GlassBrightIcon] with a press-scale animation.
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
      end: 0.88,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        child: GlassBrightIcon(
          icon: widget.icon,
          size: widget.size,
          iconSize: widget.iconSize,
          tone: widget.tone,
          active: widget.active,
        ),
      ),
    );
    return widget.tooltip == null
        ? button
        : Tooltip(message: widget.tooltip!, child: button);
  }
}

/// A glowing interactive action button with glass container, optional border bloom, and haptic-like scale.
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
    this.borderRadius = 16,
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
    final colors = widget.tone.stops;
    final r = widget.isCircle ? BorderRadius.circular(widget.size / 2) : BorderRadius.circular(widget.borderRadius);

    Widget content = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.28),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.first.withValues(alpha: 0.25),
                  colors.last.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: colors.first.withValues(alpha: 0.35),
                width: 0.75,
              ),
            ),
            child: Center(
              child: BrightIcon(
                icon: widget.icon,
                size: widget.iconSize,
                tone: widget.tone,
              ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
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
  }
}

/// A rounded-rectangle glass "chip" containing a bright icon and a label.
/// Used for quick actions and settings rows.
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tone.base.withValues(alpha: 0.32),
            width: 0.8,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tone.stops.first.withValues(alpha: 0.24),
              tone.stops.last.withValues(alpha: 0.08),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: tone.base.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrightIcon(icon: icon, size: 18, tone: tone),
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
