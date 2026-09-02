import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/albums_api.dart';
import '../../../data/api/files_api.dart';
import '../../../data/dto/file_dto.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_artwork.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;
  final Album? initial;
  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.initial,
  });

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
      String? cover;
      try {
        cover = await ref.read(filesApiProvider).thumbnailUrl(
              NexoraFiles.parseRootId(widget.albumId),
              NexoraFiles.parsePath(widget.albumId),
              size: 600,
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
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(child: _hero(album)),
            SliverToBoxAdapter(child: _actions()),
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
                                '${s.artist ?? album.artist ?? 'Unknown'} • ${album.title}',
                            duration:
                                formatDuration(Duration(seconds: s.duration ?? 0)),
                            indexLabel:
                                (s.trackNumber ?? (i + 1)).toString().padLeft(2, '0'),
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

  Widget _hero(Album album) {
    final totalSec = _tracks.fold<int>(0, (s, t) => s + (t.duration ?? 0));
    final year = _tracks.map((t) => t.year).firstWhere(
          (y) => y != null,
          orElse: () => null,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: NexoraArtwork(url: _coverUrl, size: 260),
            ),
          ),
          const SizedBox(height: NexoraSpacing.s24),
          Text(
            album.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            album.artist ?? 'Unknown Artist',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (year != null) '$year',
              '${_tracks.length} ${_tracks.length == 1 ? 'track' : 'tracks'}',
              if (totalSec > 0) formatDuration(Duration(seconds: totalSec)),
            ].join(' • '),
            style: const TextStyle(
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

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: NexoraTextButton(
              label: 'Play All',
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
}