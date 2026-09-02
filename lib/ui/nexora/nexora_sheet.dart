import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_tokens.dart';

/// Calm bottom-sheet wrapper. No translucent layer; the sheet itself sits
/// on a quiet dark surface. Used for Queue, Audio Details, Sleep Timer,
/// and Player Visual Mode picker.
class NexoraSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final double initialHeight;
  final double maxHeight;

  const NexoraSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.initialHeight = 0.6,
    this.maxHeight = 0.85,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    List<Widget>? actions,
    double initialHeight = 0.6,
    double maxHeight = 0.85,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (c) => NexoraSheet(
        title: title ?? '',
        subtitle: subtitle,
        actions: actions,
        child: child,
        initialHeight: initialHeight,
        maxHeight: maxHeight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialHeight,
      minChildSize: 0.32,
      maxChildSize: maxHeight,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: NexoraRadius.sheetTop,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 0.6),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textDim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
