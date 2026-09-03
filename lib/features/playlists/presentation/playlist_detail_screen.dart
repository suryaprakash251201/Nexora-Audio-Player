import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/playlists_repository.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/playlist_cover.dart';
import '../../../ui/widgets/track_menu_box.dart';
import 'add_to_playlist_sheet.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

/// Playlist detail — full audiophile redesign.
///
/// Big square mosaic cover as the hero, editorial title block, two
/// primary actions (Play / Shuffle) as full-width tonal buttons, then
/// the tracklist in a contained card so hairlines read consistently
/// across the whole list.
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
      // FIX #6: p.tracks is often null/empty even when the playlist has
      // songs — always fall back to the dedicated tracks endpoint.
      List<Song> tracks = p.tracks ?? const [];
      if (tracks.isEmpty) {
        try {
          tracks = await repo.getPlaylistTracks(widget.playlistId);
        } catch (_) {
          tracks = p.tracks ?? const [];
        }
      }
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
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: AppColors.text),
              flexibleSpace: const NexoraSliverAppBarBackground(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: _showOptions,
                ),
              ],
            ),
            SliverToBoxAdapter(child: _hero(p)),
            SliverToBoxAdapter(child: _actions(p)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'TRACKS',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _tracks.length.toString(),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_tracks.isNotEmpty)
                      Text(
                        '${formatDuration(_totalDuration() ?? Duration.zero)} total',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_tracks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: NexoraEmptyState(
                    icon: Icons.queue_music_outlined,
                    title: 'Empty playlist',
                    subtitle: 'Add songs from your library to begin.',
                  ),
                ),
              )
            else
              // #6 Card UI: each song is its own card (not a single box
              // with hairlines) so touch targets, artwork + playing state
              // all read clearly and the list never renders blank.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((c, i) {
                    final s = _tracks[i];
                    final isCurrent =
                        ref.watch(playerProvider).currentTrack?.id == s.id;
                    final playing =
                        isCurrent && ref.watch(playerProvider).isPlaying;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? AppColors.selectionGradientHorizontal
                              : null,
                          color: isCurrent
                              ? null
                              : AppColors.card.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white.withValues(alpha: 0.22)
                                : AppColors.border,
                            width: 0.7,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : (AppColors.mode == AppThemeMode.dark
                                    ? null
                                    : NexoraShadow.card(false)),
                        ),
                        child: NexoraTrackRow(
                          artworkUrl: s.coverUrl ?? s.artworkUrl,
                          title: s.title,
                          subtitle:
                              '${s.artist ?? 'Unknown'} • ${formatDuration(Duration(seconds: s.duration ?? 0))}',
                          indexLabel: (i + 1).toString().padLeft(2, '0'),
                          isCurrent: isCurrent,
                          isPlaying: playing,
                          isFavorite: s.isFavorite,
                          isDownloaded: s.isDownloaded,
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .playSongs(_tracks, initialIndex: i),
                          onMoreAt: (anchor) => _showTrackOptions(s, anchor),
                        ),
                      ),
                    );
                  }, childCount: _tracks.length),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: NexoraSpacing.dockBottomReserve),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(Playlist p) {
    final count = p.trackCount ?? _tracks.length;
    final total = _totalDuration();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Hero(
                tag: 'playlist-cover-${p.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.mode == AppThemeMode.dark
                        ? null
                        : NexoraShadow.card(false),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _firstTrackArtwork(p),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            p.name,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
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
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaPill(
                icon: Icons.music_note_rounded,
                label: '$count ${count == 1 ? 'track' : 'tracks'}',
              ),
              const SizedBox(width: 8),
              if (total != null)
                _MetaPill(
                  icon: Icons.schedule_rounded,
                  label: formatDuration(total),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(Playlist p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _PrimaryAction(
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onTap: _tracks.isEmpty
                  ? null
                  : () => ref
                        .read(playerProvider.notifier)
                        .playSongs(_tracks, initialIndex: 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SecondaryAction(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              onTap: _tracks.isEmpty
                  ? null
                  : () => ref
                        .read(playerProvider.notifier)
                        .playSongs([..._tracks]..shuffle(), initialIndex: 0),
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
    // FIX #6: hero must use loaded _tracks (p.tracks is usually empty).
    final urls = <String?>[];
    final direct = p.coverUrl;
    if (direct != null && direct.isNotEmpty) urls.add(direct);
    final source = _tracks.isNotEmpty ? _tracks : (p.tracks ?? const []);
    for (final t in source) {
      final u = t.coverUrl ?? t.artworkUrl;
      if (u != null && u.isNotEmpty) {
        urls.add(u);
        if (urls.length >= 4) break;
      }
    }
    return PlaylistCover(artworkUrls: urls, borderRadius: 0, title: p.name);
  }

  void _showTrackOptions(Song s, Rect anchor) {
    final canRemove = (s.itemRef ?? '').isNotEmpty;
    showTrackMenuBox(
      context: context,
      anchor: anchor,
      options: [
        TrackMenuOption(
          icon: Icons.play_arrow_rounded,
          label: 'Play next',
          onTap: () => ref.read(playerProvider.notifier).playNext(s),
        ),
        TrackMenuOption(
          icon: Icons.queue_music_rounded,
          label: 'Add to queue',
          onTap: () {
            ref.read(playerProvider.notifier).addToQueue(s);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Added to queue')));
          },
        ),
        TrackMenuOption(
          icon: Icons.playlist_add_rounded,
          label: 'Add to playlist',
          onTap: () => showAddToPlaylistSheet(context, song: s),
        ),
        if (canRemove)
          TrackMenuOption(
            icon: Icons.delete_outline_rounded,
            label: 'Remove from playlist',
            danger: true,
            onTap: () => _removeFromPlaylist(s),
          ),
      ],
    );
  }

  Future<void> _removeFromPlaylist(Song s) async {
    try {
      await ref
          .read(playlistsRepositoryProvider)
          .removeTrack(widget.playlistId, s.itemRef!);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from playlist')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
      }
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: NexoraRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
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
                  color: AppColors.textFaint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.text),
                title: Text('Rename', style: TextStyle(color: AppColors.text)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete playlist',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (cx) => AlertDialog(
                      backgroundColor: AppColors.card,
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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.text, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
