import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// One row inside the track options mini menu.
class TrackMenuOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const TrackMenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
}

/// Small anchored menu box for a track's ⋯ button.
///
/// Replaces the old full-width bottom sheets: a compact popup pinned near
/// the tapped button (right side, vertically clamped on-screen).
Future<void> showTrackMenuBox({
  required BuildContext context,
  required Rect anchor,
  required List<TrackMenuOption> options,
}) {
  final screen = MediaQuery.sizeOf(context);
  const menuWidth = 224.0;
  final left = math.max(12.0, screen.width - menuWidth - 12);
  final maxTop = math.max(70.0, screen.height - 300);
  final top = (anchor.center.dy - 70).clamp(70.0, maxTop);
  final isDark = AppColors.mode == AppThemeMode.dark;

  return showMenu<void>(
    context: context,
    position: RelativeRect.fromLTRB(left, top, 12, 12),
    color: AppColors.card,
    elevation: 14,
    shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.border, width: 0.8),
    ),
    items: [
      for (final option in options)
        PopupMenuItem<void>(
          padding: EdgeInsets.zero,
          height: 46,
          onTap: option.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 19,
                  color: option.danger ? AppColors.error : AppColors.accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: option.danger ? AppColors.error : AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
