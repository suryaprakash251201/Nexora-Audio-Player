import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/history_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../player/providers/player_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'History',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ),
      body: historyAsync.when(
        data: (items) => items.isEmpty
            ? const EmptyView(
                title: 'No history',
                subtitle: 'Played songs will appear here',
                icon: Icons.history_rounded,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_historyProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 140),
                  itemCount: items.length,
                  itemBuilder: (c, i) {
                    final h = items[i];
                    final s = h.song;
                    final isCurrent =
                        ref.watch(playerProvider).currentTrack?.id == s?.id;
                    return InkWell(
                      onTap: s != null
                          ? () => ref
                              .read(playerProvider.notifier)
                              .playSongs([s])
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.hairline,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      color: AppColors.surfaceRaised,
                                      image: s?.coverUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                s!.coverUrl!,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: s?.coverUrl == null
                                        ? Icon(
                                            Icons.music_note_rounded,
                                            color: AppColors.textDim,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  if (isCurrent)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.equalizer_rounded,
                                        size: 18,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s?.title ?? h.songId,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? AppColors.accent
                                          : AppColors.text,
                                      fontSize: 15,
                                      fontWeight: isCurrent
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s?.artist ?? 'Unknown'} • ${_timeAgo(h.playedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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