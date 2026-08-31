import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../domain/entities/playlist.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final Playlist? initial;
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.initial,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  Playlist? _playlist;
  List<dynamic> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _playlist = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(playlistsRepositoryProvider);
      final p = await repo.getPlaylist(widget.playlistId);
      final tracks =
          p.tracks ?? await repo.getPlaylistTracks(widget.playlistId);
      setState(() {
        _playlist = p;
        _tracks = tracks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(
        appBar: AppBar(title: Text(_playlist?.name ?? 'Playlist')),
        body: const LoadingView(),
      );
    if (_error != null)
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    final p = _playlist!;
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: p.coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(p.coverUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(
                          Icons.queue_music,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.description ?? '',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_tracks.length} songs',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _tracks.isEmpty
                        ? null
                        : () => ref
                              .read(playerProvider.notifier)
                              .playSongs(_tracks.cast(), initialIndex: 0),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play all'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _tracks.isEmpty ? null : () {},
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          Expanded(
            child: _tracks.isEmpty
                ? const EmptyView(
                    title: 'Empty playlist',
                    subtitle: 'Add songs from library',
                    icon: Icons.queue_music_outlined,
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: _tracks.length,
                    onReorder: (oldIdx, newIdx) async {
                      if (newIdx > oldIdx) newIdx -= 1;
                      final item = _tracks.removeAt(oldIdx);
                      _tracks.insert(newIdx, item);
                      setState(() {});
                      try {
                        await ref
                            .read(playlistsRepositoryProvider)
                            .reorder(
                              p.id,
                              _tracks
                                  .map((e) => (e.itemRef ?? e.id) as String)
                                  .toList(),
                            );
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reorder failed: $e')),
                          );
                      }
                    },
                    itemBuilder: (c, i) {
                      final s = _tracks[i];
                      return ListTile(
                        key: ValueKey(s.id),
                        leading: ArtworkImage(
                          url: s.coverUrl,
                          size: 48,
                          borderRadius: 6,
                        ),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${s.artist ?? 'Unknown'} • ${formatDuration(Duration(seconds: s.duration ?? 0))}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.play_arrow,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => ref
                                  .read(playerProvider.notifier)
                                  .playSongs(_tracks.cast(), initialIndex: i),
                            ),
                            const Icon(
                              Icons.drag_handle,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ],
                        ),
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .playSongs(_tracks.cast(), initialIndex: i),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Rename',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(c),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete playlist',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(c);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (cx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text(
                      'Delete?',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This will delete the playlist.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(cx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(cx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await ref
                        .read(playlistsRepositoryProvider)
                        .deletePlaylist(widget.playlistId);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Delete failed: $e')),
                      );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
