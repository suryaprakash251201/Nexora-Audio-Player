import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/download/download_manager.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/track_menu_box.dart';
import '../../player/providers/player_provider.dart';

/// Downloaded tracks with full metadata. Rebuilds whenever the live
/// download set changes (download finished / removed).
final downloadedTracksProvider = FutureProvider<List<Song>>((ref) async {
  ref.watch(downloadedIdsProvider);
  return ref.watch(downloadManagerProvider).downloadedTracks();
});

/// Downloads — real offline library.
///
/// Lists every downloaded track (playable offline via its local file),
/// with play, queue actions and removal. Pull to refresh.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(downloadedTracksProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        toolbarHeight: 64,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Downloads',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  letterSpacing: -0.6,
                ),
              ),
              Text(
                tracksAsync.value != null && tracksAsync.value!.isNotEmpty
                    ? '${tracksAsync.value!.length} tracks available offline'
                    : 'Offline playback',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      body: tracksAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(downloadedTracksProvider),
        ),
        data: (tracks) {
          if (tracks.isEmpty) return const _EmptyDownloads();
          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.card,
            onRefresh: () async {
              await ref.read(downloadedIdsProvider.notifier).refresh();
              ref.invalidate(downloadedTracksProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 168),
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final s = tracks[i];
                final isCurrent =
                    ref.watch(
                      playerProvider.select((s) => s.currentTrack?.id),
                    ) ==
                    s.id;
                return NexoraTrackRow(
                  artworkUrl: s.coverUrl,
                  title: s.title,
                  subtitle:
                      '${s.artist ?? 'Unknown'} • ${formatDuration(Duration(seconds: s.duration ?? 0))}',
                  indexLabel: (i + 1).toString().padLeft(2, '0'),
                  isCurrent: isCurrent,
                  isPlaying:
                      isCurrent &&
                      ref.watch(playerProvider.select((s) => s.isPlaying)),
                  isDownloaded: true,
                  onTap: () => ref
                      .read(playerProvider.notifier)
                      .playSongs(tracks, initialIndex: i),
                  onMoreAt: (anchor) => showTrackMenuBox(
                    context: context,
                    anchor: anchor,
                    options: trackMenuOptions(
                      ref: ref,
                      context: context,
                      song: s,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.hueTeal.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.hueTeal.withValues(alpha: 0.22),
                  width: 0.7,
                ),
              ),
              child: Icon(
                Icons.download_rounded,
                color: AppColors.hueTeal,
                size: 36,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'No downloads',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the ⋯ menu on any track and choose Download.\nDownloaded tracks play fully offline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
