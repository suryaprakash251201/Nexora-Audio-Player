import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/history_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../player/providers/player_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {}),
        ],
      ),
      body: historyAsync.when(
        data: (items) => items.isEmpty
            ? const EmptyView(
                title: 'No history',
                subtitle: 'Played songs will appear here',
                icon: Icons.history,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_historyProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (c, i) {
                    final h = items[i];
                    final s = h.song;
                    return ListTile(
                      leading: ArtworkImage(
                        url: s?.coverUrl,
                        size: 48,
                        borderRadius: 8,
                      ),
                      title: Text(
                        s?.title ?? h.songId,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${s?.artist ?? ''} • ${_timeAgo(h.playedAt)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.play_arrow,
                        color: AppColors.textMuted,
                      ),
                      onTap: s != null
                          ? () =>
                                ref.read(playerProvider.notifier).playSongs([s])
                          : null,
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
