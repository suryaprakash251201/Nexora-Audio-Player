import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
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
  List<Song> _tracks = [];
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
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, title: Text(_playlist?.name ?? 'Playlist')),
        body: const LoadingView(),
      );
    if (_error != null)
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Playlist')),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    final p = _playlist!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            pinned: true,
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _firstTrackArtwork(p, blur: true),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _firstTrackArtwork(p),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p.description ?? 'Playlist • ${_tracks.length} songs',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: _showOptions,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _tracks.isEmpty
                          ? null
                          : () => ref
                                .read(playerProvider.notifier)
                                .playSongs(_tracks, initialIndex: 0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 24),
                          SizedBox(width: 8),
                          Text('Play', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceRaised,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _tracks.isEmpty ? null : () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shuffle_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Shuffle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _tracks.isEmpty
              ? const SliverFillRemaining(
                  child: EmptyView(
                    title: 'Empty playlist',
                    subtitle: 'Add songs from library',
                    icon: Icons.queue_music_outlined,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (c, i) {
                      final s = _tracks[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        key: ValueKey(s.id),
                        leading: ArtworkImage(
                          url: s.coverUrl,
                          size: 52,
                          borderRadius: 8,
                        ),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${s.artist ?? 'Unknown'} • ${formatDuration(Duration(seconds: s.duration ?? 0))}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => ref
                                  .read(playerProvider.notifier)
                                  .playSongs(_tracks, initialIndex: i),
                            ),
                            const Icon(
                              Icons.drag_handle_rounded,
                              color: AppColors.textDim,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () => ref
                            .read(playerProvider.notifier)
                            .playSongs(_tracks, initialIndex: i),
                      );
                    },
                    childCount: _tracks.length,
                  ),
                ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _firstTrackArtwork(Playlist p, {bool blur = false}) {
    // Server playlists don't carry coverUrl; use the first track's artwork.
    final tracks = p.tracks ?? [];
    String? url;
    if (tracks.isNotEmpty) {
      url = tracks.first.coverUrl;
    } else if (p.coverUrl != null) {
      url = p.coverUrl;
    }
    
    if (url != null) {
      if (blur) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ArtworkImage(url: url, size: double.infinity, borderRadius: 0),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ],
        );
      }
      return ArtworkImage(url: url, size: 140, borderRadius: 12);
    }
    
    return Container(
      width: blur ? double.infinity : 140,
      height: blur ? double.infinity : 140,
      decoration: BoxDecoration(
        color: blur ? AppColors.background : AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(blur ? 0 : 12),
      ),
      child: Icon(
        Icons.music_note,
        size: blur ? 100 : 40,
        color: blur ? AppColors.textDim.withValues(alpha: 0.2) : AppColors.textMuted,
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
