import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Vivid, saturated tones used to tint app icons.
///
/// Each tone resolves to a two-stop gradient so glyphs read as "lit" rather
/// than flat, which is what gives the icon set its bright, glassy look.
enum BrightIconTone {
  violet,
  cyan,
  pink,
  emerald,
  amber,
  sky,
  rose,
  indigo,
}

extension BrightIconToneX on BrightIconTone {
  /// The two gradient stops for this tone.
  List<Color> get stops {
    switch (this) {
      case BrightIconTone.violet:
        return const [Color(0xFFA78BFA), Color(0xFF7C3AED)];
      case BrightIconTone.cyan:
        return const [Color(0xFF22D3EE), Color(0xFF0891B2)];
      case BrightIconTone.pink:
        return const [Color(0xFFF472B6), Color(0xFFDB2777)];
      case BrightIconTone.emerald:
        return const [Color(0xFF34D399), Color(0xFF059669)];
      case BrightIconTone.amber:
        return const [Color(0xFFFBBF24), Color(0xFFD97706)];
      case BrightIconTone.sky:
        return const [Color(0xFF60A5FA), Color(0xFF2563EB)];
      case BrightIconTone.rose:
        return const [Color(0xFFFB7185), Color(0xFFE11D48)];
      case BrightIconTone.indigo:
        return const [Color(0xFF818CF8), Color(0xFF4F46E5)];
    }
  }

  /// Flat representative colour (useful for glows and shadows).
  Color get base => stops.first;
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
                  color: colors.first.withValues(alpha: 0.35),
                  blurRadius: size * 0.5,
                  spreadRadius: -size * 0.12,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active
                    ? colors.first.withValues(alpha: 0.45)
                    : AppColors.glassBorder,
                width: 0.8,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: active
                    ? [
                        colors.first.withValues(alpha: 0.28),
                        colors.last.withValues(alpha: 0.10),
                      ]
                    : [
                        AppColors.glassBase.withValues(alpha: 0.35),
                        AppColors.glassBase.withValues(alpha: 0.12),
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
            color: tone.base.withValues(alpha: 0.3),
            width: 0.8,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tone.stops.first.withValues(alpha: 0.22),
              tone.stops.last.withValues(alpha: 0.08),
            ],
          ),
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
