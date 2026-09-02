import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_tokens.dart';

/// Floating centered dialog with scale+fade entrance, backdrop blur/dim,
/// and staggered option entrance.
///
/// Replaces the old bottom-sheet pickers for Appearance → Theme & Player Style
/// so the choice appears as a front floating card rather than sliding from
/// the bottom.

Future<T?> showNexoraFloatingDialog<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: title,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.52),
    transitionDuration: NexoraDuration.medium,
    pageBuilder: (ctx, a1, a2) => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: Colors.transparent,
            child: NexoraFloatingCard(
              title: title,
              subtitle: subtitle,
              child: child,
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      final scaleTween = Tween<double>(
        begin: 0.92,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: scaleTween.animate(curved), child: child),
      );
    },
  );
}

class NexoraFloatingCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const NexoraFloatingCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.hairline),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated option tile used inside the floating card.
///
/// Includes press-scale feedback and a check indicator for selection.
/// Each tile animates in with a staggered slide+fade so the sheet feels
/// alive rather than static.
class NexoraFloatingOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  const NexoraFloatingOption({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.selected,
    required this.onTap,
    this.index = 0,
  });

  @override
  State<NexoraFloatingOption> createState() => _NexoraFloatingOptionState();
}

class _NexoraFloatingOptionState extends State<NexoraFloatingOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    // Staggered entrance
    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: NexoraDuration.tap,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: NexoraDuration.short,
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.accent.withValues(alpha: 0.10)
                    : AppColors.surfaceHigh.withValues(alpha: 0.0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.selected
                      ? AppColors.accent.withValues(alpha: 0.45)
                      : AppColors.border,
                  width: 0.6,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? AppColors.accent.withValues(alpha: 0.14)
                          : AppColors.surfaceHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.selected
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.selected
                                ? AppColors.accent
                                : AppColors.text,
                            fontWeight: widget.selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: -0.1,
                          ),
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.description!,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: NexoraDuration.micro,
                    transitionBuilder: (c, a) => ScaleTransition(
                      scale: a,
                      child: FadeTransition(opacity: a, child: c),
                    ),
                    child: widget.selected
                        ? Container(
                            key: const ValueKey('check'),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('empty'),
                            width: 22,
                            height: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
