import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_primitives.dart';
import 'nexora_tokens.dart';

/// Unified page header — single source of truth for top-level screens.
///
/// Replaces four one-off header variants (Home SliverAppBar, Library Column,
/// Search back-button row, Settings SliverAppBar) with one rhythm:
///
/// - 32px extrabold title, -0.8 tracking, 1.05 height
/// - 13.5px muted subtitle
/// - 20px horizontal gutter, 14px top, 4px bottom
/// - Optional trailing action(s) in 46px [NexoraIconButton] tiles
///
/// Use inside [SafeArea] for tab screens. For sliver screens, prefer
/// [NexoraSliverHeaderDelegate] below so Home/Settings keep their
/// pinned blur while sharing the same typography.
class NexoraPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final EdgeInsets padding;

  const NexoraPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                      letterSpacing: -0.1,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[const SizedBox(width: 12), ...actions],
        ],
      ),
    );
  }
}

/// Sliver variant — pinned frosted bar with the same 32→20 collapsing
/// typography. Drop-in for Home/Settings SliverAppBars so they share
/// language with [NexoraPageHeader] without losing blur + pin behavior.
class NexoraSliverPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  const NexoraSliverPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 68,
      flexibleSpace: const NexoraSliverAppBarBackground(blur: 20),
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.7,
              height: 1.1,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
        ],
      ),
      actions: [...actions, if (actions.isNotEmpty) const SizedBox(width: 8)],
    );
  }
}

/// Standard list bottom padding — content never hides behind the floating
/// dock (mini 68 + gap 8 + nav 68 + margins 24 + system inset).
/// Screens should use this instead of hard-coded 168/188 values.
class NexoraListPadding extends StatelessWidget {
  final Widget child;
  final double top;
  final double horizontal;

  const NexoraListPadding({
    super.key,
    required this.child,
    this.top = 8,
    this.horizontal = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        top,
        horizontal,
        NexoraSpacing.dockBottomReserve + bottomInset,
      ),
      child: child,
    );
  }
}

/// Bottom padding value for slivers / ListViews (no wrapper widget needed).
EdgeInsets nexoraDockPadding({double top = 8, double horizontal = 0}) {
  return EdgeInsets.only(
    top: top,
    left: horizontal,
    right: horizontal,
    // Base reserve already accounts for nav+mini+margins; callers add
    // MediaQuery inset separately where they need pixel perfection.
    bottom: NexoraSpacing.dockBottomReserve,
  );
}
