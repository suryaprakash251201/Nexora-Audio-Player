import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_primitives.dart';
import 'nexora_tokens.dart';

/// Editorial settings row used by Settings and detail pages.
///
/// Left icon slot + label + subtitle + optional trailing. Tap area is the
/// whole row. Matches Apple's native Settings pattern visually.
class NexoraSettingsRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const NexoraSettingsRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor =
        destructive ? AppColors.error : AppColors.text;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: NexoraSpacing.s20,
        vertical: NexoraSpacing.s12,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: NexoraSpacing.s16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.surfaceHigh.withValues(alpha: 0.4),
        highlightColor: AppColors.surfaceHigh.withValues(alpha: 0.2),
        child: row,
      ),
    );
  }
}

/// Card-like grouping container with a quiet surface and hairline border.
/// Used to group settings entries and other list sections without
/// competing with the artwork.
class NexoraGroupedList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const NexoraGroupedList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(
      horizontal: NexoraSpacing.s16,
      vertical: NexoraSpacing.s8,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i != children.length - 1) {
        items.add(
          const NexoraDivider(indent: NexoraSpacing.s20, endIndent: 0),
        );
      }
    }
    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: NexoraRadius.card,
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
      ),
    );
  }
}