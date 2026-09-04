import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_service.dart';
import '../theme.dart';

/// Global connectivity UX.
///
/// - Offline → persistent amber pill pinned to the top.
/// - Back-online → transient green "syncing" pill, auto-hides (monitor).
///
/// Mount once in the app shell so every tab (Home/Search/Library/…)
/// gets it for free. The mini player stays mounted underneath, so
/// cached queue + downloads keep playing throughout.
class ConnectivityBanner extends ConsumerWidget {
  /// Top offset below the status bar.
  final double top;
  const ConnectivityBanner({super.key, this.top = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityMonitorProvider);
    final showOffline = state.isOffline;
    final showOnline = !showOffline && state.showBackOnline;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: showOffline
          ? _Pill(
              key: const ValueKey('offline'),
              top: top,
              icon: Icons.wifi_off_rounded,
              title: 'No internet — offline mode',
              subtitle: 'Queue & downloads still play',
              color: AppColors.warning,
            )
          : showOnline
          ? _Pill(
              key: const ValueKey('online'),
              top: top,
              icon: Icons.sync_rounded,
              title: 'Back online — syncing…',
              subtitle: 'Queued changes uploading',
              color: AppColors.success,
              spinning: true,
            )
          : SizedBox(key: const ValueKey('none'), height: top),
    );
  }
}

class _Pill extends StatefulWidget {
  final double top;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool spinning;

  const _Pill({
    super.key,
    required this.top,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.spinning = false,
  });

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (widget.spinning) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, widget.top + 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: isDark ? 0.88 : 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.45),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.15),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.35),
                  width: 0.7,
                ),
              ),
              child: widget.spinning
                  ? RotationTransition(
                      turns: _c,
                      child: Icon(widget.icon, size: 16, color: widget.color),
                    )
                  : Icon(widget.icon, size: 16, color: widget.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact offline chip for the full player (under the title) and anywhere
/// a screen wants an inline offline marker without the global banner.
class OfflineChip extends ConsumerWidget {
  const OfflineChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(
      connectivityMonitorProvider.select((s) => s.isOffline),
    );
    if (!offline) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 12, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            'OFFLINE — PLAYING CACHE & DOWNLOADS',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
