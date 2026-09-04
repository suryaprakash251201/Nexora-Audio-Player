import 'package:flutter/material.dart';

import '../theme.dart';

/// Severity levels for [showNexoraSnack]. Each level tints the leading
/// status dot so feedback is scannable at a glance.
enum NexoraSnackSeverity { info, success, warning, error }

/// The single entry point for transient feedback across the app.
///
/// Replaces ad-hoc `ScaffoldMessenger.showSnackBar` calls so every message
/// shares one visual language: floating pill, hairline border, status dot,
/// theme-driven colors. Never break a flow with a dialog when a snack will
/// do — that is what this helper is for.
void showNexoraSnack(
  BuildContext context,
  String message, {
  NexoraSnackSeverity severity = NexoraSnackSeverity.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 2600),
}) {
  final Color statusColor = switch (severity) {
    NexoraSnackSeverity.success => AppColors.success,
    NexoraSnackSeverity.warning => AppColors.warning,
    NexoraSnackSeverity.error => AppColors.error,
    NexoraSnackSeverity.info => AppColors.accent,
  };

  final snackBar = SnackBar(
    content: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.45),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: AppColors.surfaceHigh.withValues(alpha: 0.97),
    behavior: SnackBarBehavior.floating,
    elevation: 12,
    duration: duration,
    action: (actionLabel != null && onAction != null)
        ? SnackBarAction(
            label: actionLabel,
            textColor: AppColors.accentSoft,
            onPressed: onAction,
          )
        : null,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
