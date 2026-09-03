import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/download/download_manager.dart';
import '../../data/repositories/songs_repository.dart';
import '../../domain/entities/song.dart';
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

/// Download / remove-download option reflecting live download state.
/// Label is resolved synchronously from [downloadedIdsProvider], so the
/// menu never needs an async gap before opening.
TrackMenuOption downloadMenuOption(
  WidgetRef ref,
  BuildContext context,
  Song song,
) {
  final downloaded = ref.read(downloadedIdsProvider).contains(song.id);
  return TrackMenuOption(
    icon: downloaded ? Icons.download_done_rounded : Icons.download_rounded,
    label: downloaded ? 'Remove download' : 'Download',
    onTap: () => toggleDownload(ref, context, song, downloaded),
  );
}

/// Performs the download (or removal), updates live state, and confirms.
/// Fire-and-forget safe: all failures surface as a snackbar, never silent.
Future<void> toggleDownload(
  WidgetRef ref,
  BuildContext context,
  Song song,
  bool currentlyDownloaded,
) async {
  final manager = ref.read(downloadManagerProvider);
  final ids = ref.read(downloadedIdsProvider.notifier);
  void say(String message) {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {}
  }

  try {
    if (currentlyDownloaded) {
      await manager.removeTrackDownload(song.id);
      ids.markRemoved(song.id);
      say('Download removed');
      return;
    }
    final url =
        song.streamUrl ??
        await ref.read(songsRepositoryProvider).streamUrl(song.id);
    final saved = await manager.downloadTrack(song.id, url);
    if (saved == null) {
      say('Download failed — check connection and storage');
      return;
    }
    ids.markDownloaded(song.id);
    say('Downloaded for offline playback');
  } catch (e) {
    say('Download failed: $e');
  }
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
