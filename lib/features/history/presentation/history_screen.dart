import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/history_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/widgets/bright_icons.dart';
import '../../../ui/animations/app_animations.dart';
import '../../player/providers/player_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'History',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const GlassBrightIcon(
              icon: Icons.delete_outline_rounded,
              tone: BrightIconTone.rose,
              size: 38,
              iconSize: 20,
              active: true,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AuroraBackground(
        child: historyAsync.when(
          data: (items) => items.isEmpty
              ? const EmptyView(
                  title: 'No history',
                  subtitle: 'Played songs will appear here',
                  icon: Icons.history_rounded,
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_historyProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (c, i) {
                      final h = items[i];
                      final s = h.song;
                      final isCurrent =
                          ref.watch(playerProvider).currentTrack?.id == s?.id;
                      return SlideInAnimation(
                        delay: Duration(milliseconds: (i % 10) * 40),
                        child: GlassSongTile(
                          artworkUrl: s?.coverUrl,
                          title: s?.title ?? h.songId,
                          subtitle: '${s?.artist ?? 'Unknown'} • ${_timeAgo(h.playedAt)}',
                          isCurrent: isCurrent,
                          isPlaying: isCurrent && ref.watch(playerProvider).isPlaying,
                          onTap: s != null
                              ? () => ref.read(playerProvider.notifier).playSongs([s])
                              : () {},
                        ),
                      );
                    },
                  ),
                ),
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(_historyProvider),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

final _historyProvider = FutureProvider(
  (ref) async =>
      ref.watch(historyRepositoryProvider).getHistory(page: 1, limit: 50),
);
