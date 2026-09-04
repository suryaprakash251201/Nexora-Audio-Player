import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/download/download_manager.dart';
import '../../data/api/shares_api.dart';
import '../../data/api/tags_api.dart';
import '../../data/dto/file_dto.dart';
import '../../data/repositories/songs_repository.dart';
import '../../domain/entities/song.dart';
import '../../features/player/providers/player_provider.dart';
import '../../features/playlists/presentation/add_to_playlist_sheet.dart';
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

/// Creates a public link for a track and opens the OS share sheet.
/// Keeps the manage-shares list fresh for the Shares screen.
Future<void> shareTrack(WidgetRef ref, BuildContext context, Song song) async {
  void say(String message) {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {}
  }

  try {
    final parts = NexoraFiles.splitId(song.id);
    final link = await ref
        .read(sharesApiProvider)
        .createShare(root: parts.root, path: parts.path);
    ref.invalidate(sharesProvider);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Listen: ${song.title}\n${link.url}',
        subject: song.title,
      ),
    );
  } catch (e) {
    say('Share failed: $e');
  }
}

/// Tag picker sheet for one track (apply existing or create new).
/// There is no per-file tag listing endpoint, so this sheet applies
/// tags and manages the tag collection rather than showing assignments.
Future<void> showTagSheet(BuildContext context, WidgetRef ref, Song song) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (c) => _TagSheet(song: song),
  );
}

class _TagSheet extends ConsumerStatefulWidget {
  final Song song;
  const _TagSheet({required this.song});

  @override
  ConsumerState<_TagSheet> createState() => _TagSheetState();
}

class _TagSheetState extends ConsumerState<_TagSheet> {
  final _nameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _apply(NexoraTag tag) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final parts = NexoraFiles.splitId(widget.song.id);
      await ref
          .read(tagsApiProvider)
          .tagFile(tagId: tag.id, rootId: parts.root, path: parts.path);
      ref.invalidate(tagsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tagged “${tag.name}”')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tag failed: $e')));
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final tag = await ref.read(tagsApiProvider).createTag(name);
      ref.invalidate(tagsProvider);
      _nameController.clear();
      await _apply(tag);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Add tag',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: tagsAsync.when(
                  data: (tags) => tags.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            'No tags yet — create your first below.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: tags.length,
                          itemBuilder: (c, i) {
                            final tag = tags[i];
                            return ListTile(
                              leading: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tag.color,
                                ),
                              ),
                              title: Text(
                                tag.name,
                                style: TextStyle(color: AppColors.text),
                              ),
                              subtitle: Text(
                                '${tag.count} files',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_rounded,
                                      color: AppColors.textDim,
                                    ),
                              onTap: _busy ? null : () => _apply(tag),
                            );
                          },
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      'Could not load tags: $e',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _create(),
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'New tag name',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _busy ? null : _create,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider entry for [showTrackMenuBox] option lists (see below).
class TrackMenuDivider {
  const TrackMenuDivider();
}

/// Standard option set for any track, in usage order: playback first,
/// library actions second. [trailing] appends screen-specific actions
/// (e.g. Remove from playlist) after a divider.
List<Object> trackMenuOptions({
  required WidgetRef ref,
  required BuildContext context,
  required Song song,
  List<TrackMenuOption>? trailing,
}) {
  return [
    TrackMenuOption(
      icon: Icons.play_arrow_rounded,
      label: 'Play next',
      onTap: () => ref.read(playerProvider.notifier).playNext(song),
    ),
    TrackMenuOption(
      icon: Icons.queue_music_rounded,
      label: 'Add to queue',
      onTap: () {
        ref.read(playerProvider.notifier).addToQueue(song);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to queue')));
      },
    ),
    downloadMenuOption(ref, context, song),
    const TrackMenuDivider(),
    TrackMenuOption(
      icon: Icons.share_outlined,
      label: 'Share link',
      onTap: () => shareTrack(ref, context, song),
    ),
    TrackMenuOption(
      icon: Icons.playlist_add_rounded,
      label: 'Add to playlist',
      onTap: () => showAddToPlaylistSheet(context, song: song),
    ),
    TrackMenuOption(
      icon: Icons.label_outline_rounded,
      label: 'Add tag…',
      onTap: () => showTagSheet(context, ref, song),
    ),
    if (trailing != null && trailing.isNotEmpty) ...[
      const TrackMenuDivider(),
      ...trailing,
    ],
  ];
}

/// Small anchored menu box for a track's ⋯ button.
///
/// Replaces the old full-width bottom sheets: a compact popup pinned near
/// the tapped button (right side, vertically clamped on-screen).
Future<void> showTrackMenuBox({
  required BuildContext context,
  required Rect anchor,
  required List<Object> options,
}) {
  HapticFeedback.selectionClick();
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
      for (final entry in options)
        if (entry is TrackMenuDivider)
          const PopupMenuDivider(height: 8)
        else if (entry is TrackMenuOption)
          PopupMenuItem<void>(
            padding: EdgeInsets.zero,
            height: 46,
            onTap: entry.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    entry.icon,
                    size: 19,
                    color: entry.danger ? AppColors.error : AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: entry.danger ? AppColors.error : AppColors.text,
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
