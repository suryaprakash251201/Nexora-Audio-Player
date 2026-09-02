import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/playlists_repository.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_artwork.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
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
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.text),
        ),
        body: const LoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.text),
        ),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    final p = _playlist!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: IconThemeData(color: AppColors.text),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: _showOptions,
                ),
              ],
            ),
            SliverToBoxAdapter(child: _hero(p)),
            SliverToBoxAdapter(child: _actions(p)),
            if (_tracks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: NexoraEmptyState(
                    icon: Icons.queue_music_outlined,
                    title: 'Empty playlist',
                    subtitle: 'Add songs from your library to begin.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(
                  bottom: NexoraSpacing.dockBottomReserve,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (c, i) {
                      final s = _tracks[i];
                      final isCurrent = ref
                          .watch(playerProvider)
                          .currentTrack
                          ?.id ==
                          s.id;
                      return Column(
                        children: [
                          NexoraTrackRow(
                            artworkUrl: s.coverUrl,
                            title: s.title,
                            subtitle:
                                '${s.artist ?? 'Unknown'} • ${formatDuration(Duration(seconds: s.duration ?? 0))}',
                            indexLabel:
                                (i + 1).toString().padLeft(2, '0'),
                            isCurrent: isCurrent,
                            isPlaying:
                                isCurrent &&
                                ref.watch(playerProvider).isPlaying,
                            isFavorite: s.isFavorite,
                            isDownloaded: s.isDownloaded,
                            onTap: () => ref
                                .read(playerProvider.notifier)
                                .playSongs(_tracks, initialIndex: i),
                            onMore: () {},
                          ),
                          if (i != _tracks.length - 1)
                            const NexoraDivider(
                                indent: 64, endIndent: 0),
                        ],
                      );
                    },
                    childCount: _tracks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero(Playlist p) {
    final cover = _firstTrackArtwork(p);
    final count = p.trackCount ?? _tracks.length;
    final total = _totalDuration();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: cover,
            ),
          ),
          const SizedBox(height: NexoraSpacing.s24),
          Text(
            p.name,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          if (p.description != null && p.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              p.description!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            [
              '$count ${count == 1 ? 'track' : 'tracks'}',
              if (total != null) formatDuration(total),
            ].join(' • '),
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(Playlist p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: NexoraTextButton(
              label: 'Play',
              icon: Icons.play_arrow_rounded,
              primary: true,
              onTap: _tracks.isEmpty
                  ? null
                  : () => ref
                      .read(playerProvider.notifier)
                      .playSongs(_tracks, initialIndex: 0),
            ),
          ),
          const SizedBox(width: NexoraSpacing.s12),
          Expanded(
            child: NexoraTextButton(
              label: 'Shuffle',
              icon: Icons.shuffle_rounded,
              onTap: _tracks.isEmpty
                  ? null
                  : () => ref.read(playerProvider.notifier).playSongs(
                        [..._tracks]..shuffle(),
                        initialIndex: 0,
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Duration? _totalDuration() {
    if (_tracks.isEmpty) return null;
    final seconds = _tracks.fold<int>(0, (s, t) => s + (t.duration ?? 0));
    if (seconds == 0) return null;
    return Duration(seconds: seconds);
  }

  Widget _firstTrackArtwork(Playlist p) {
    String? url = p.coverUrl;
    for (final t in p.tracks ?? const []) {
      final trackUrl = t.coverUrl ?? t.artworkUrl;
      if (trackUrl != null && trackUrl.isNotEmpty) {
        url ??= trackUrl;
        break;
      }
    }
    return NexoraArtwork(url: url, size: 220);
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: NexoraRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textDim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.text),
                title: Text('Rename',
                    style: TextStyle(color: AppColors.text)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text(
                  'Delete playlist',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (cx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text(
                        'Delete?',
                        style: TextStyle(color: AppColors.text),
                      ),
                      content: Text(
                        'This will delete the playlist.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(cx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(cx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
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
      ),
    );
  }
}