import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/albums_api.dart';
import '../../../data/api/files_api.dart';
import '../../../data/dto/file_dto.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart' show nexoraArtworkCache;
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/track_menu_box.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';
import '../../../core/download/download_manager.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';

/// Album detail — audiophile redesign.
///
/// Large 260px cover with shadow, editorial title block with uppercase
/// album title, year • track count • duration metadata pills, two
/// full-width tonal action buttons (Play All / Shuffle), and tracks
/// inside a contained card with hairlines.
class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;
  final Album? initial;
  const AlbumDetailScreen({super.key, required this.albumId, this.initial});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  Album? _album;
  List<Song> _tracks = [];
  String? _coverUrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _album = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(albumsApiProvider);
      final album = _album ?? await api.getAlbum(widget.albumId);
      final tracks = await api.getAlbumTracks(widget.albumId);
      // Album cover = image inside the album folder (cover art / first
      // track art). thumbnailUrl on a *directory* path 404s — use the
      // folder-cover resolver instead.
      String? cover;
      try {
        cover = await ref
            .read(filesApiProvider)
            .folderCoverUrl(
              NexoraFiles.parseRootId(widget.albumId),
              NexoraFiles.parsePath(widget.albumId),
            );
      } catch (_) {
        cover = null;
      }
      if (!mounted) return;
      setState(() {
        _album = album;
        _tracks = tracks;
        _coverUrl = cover;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    final album = _album!;
    final isDark = AppColors.mode == AppThemeMode.dark;
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
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(child: _hero(album, isDark)),
            SliverToBoxAdapter(child: _actions()),
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
                  ],
                ),
              ),
            ),
            if (_tracks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: NexoraEmptyState(
                    icon: Icons.album_outlined,
                    title: 'No tracks',
                    subtitle: 'This album folder has no audio files yet.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: NexoraRadius.card,
                      border: Border.all(color: AppColors.border, width: 0.7),
                      boxShadow: isDark ? null : NexoraShadow.card(false),
                    ),
                    child: ClipRRect(
                      borderRadius: NexoraRadius.card,
                      child: Column(
                        children: [
                          for (var i = 0; i < _tracks.length; i++) ...[
                            Builder(
                              builder: (c) {
                                final s = _tracks[i];
                                final isCurrent =
                                    ref.watch(playerProvider.select((s) => s.currentTrack?.id)) ==
                                    s.id;
                                return NexoraTrackRow(
                                  artworkUrl: s.coverUrl,
                                  title: s.title,
                                  subtitle:
                                      '${s.artist ?? album.artist ?? 'Unknown'} • ${album.title}',
                                  duration: formatDuration(
                                    Duration(seconds: s.duration ?? 0),
                                  ),
                                  indexLabel: (s.trackNumber ?? (i + 1))
                                      .toString()
                                      .padLeft(2, '0'),
                                  isCurrent: isCurrent,
                                  isPlaying:
                                      isCurrent &&
                                      ref.watch(playerProvider.select((s) => s.isPlaying)),
                                  isFavorite: s.isFavorite,
                                  isDownloaded:
                                      s.isDownloaded ||
                                      ref
                                          .watch(downloadedIdsProvider)
                                          .contains(s.id),
                                  onTap: () => ref
                                      .read(playerProvider.notifier)
                                      .playSongs(_tracks, initialIndex: i),
                                  onMoreAt: (anchor) =>
                                      _showSongMenu(s, anchor),
                                );
                              },
                            ),
                            if (i != _tracks.length - 1)
                              const NexoraDivider(indent: 64, endIndent: 0),
                          ],
                        ],
                      ),
                    ),
                  ),
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

  Widget _hero(Album album, bool isDark) {
    final totalSec = _tracks.fold<int>(0, (s, t) => s + (t.duration ?? 0));
    final year = _tracks
        .map((t) => t.year)
        .firstWhere((y) => y != null, orElse: () => null);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ]
                    : NexoraShadow.card(false),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: _coverUrl!,
                        fit: BoxFit.cover,
                        cacheManager: nexoraArtworkCache,
                        errorWidget: (_, _, _) => Container(
                          color: AppColors.surfaceRaised,
                          child: Icon(
                            Icons.album_rounded,
                            size: 64,
                            color: AppColors.textDim,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.surfaceRaised,
                        child: Icon(
                          Icons.album_rounded,
                          size: 64,
                          color: AppColors.textDim,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: NexoraSpacing.s24),
          Text(
            album.title.toUpperCase(),
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.artist ?? 'Unknown Artist',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (year != null)
                NexoraTag(
                  label: year.toString(),
                  icon: Icons.calendar_today_rounded,
                ),
              NexoraTag(
                label:
                    '${_tracks.length} ${_tracks.length == 1 ? 'track' : 'tracks'}',
                icon: Icons.music_note_rounded,
              ),
              if (totalSec > 0)
                NexoraTag(
                  label: formatDuration(Duration(seconds: totalSec)),
                  icon: Icons.schedule_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSongMenu(Song s, Rect anchor) {
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
        downloadMenuOption(ref, context, s),
        TrackMenuOption(
          icon: Icons.share_outlined,
          label: 'Share link',
          onTap: () => shareTrack(ref, context, s),
        ),
        TrackMenuOption(
          icon: Icons.label_outline_rounded,
          label: 'Add tag…',
          onTap: () => showTagSheet(context, ref, s),
        ),
      ],
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _PrimaryAction(
              icon: Icons.play_arrow_rounded,
              label: 'Play All',
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
    return GestureDetector(
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
    return GestureDetector(
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
