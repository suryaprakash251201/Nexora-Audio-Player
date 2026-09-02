import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/artists_api.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_artwork.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final Artist? initial;
  const ArtistDetailScreen({
    super.key,
    required this.artistId,
    this.initial,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() =>
      _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  Artist? _artist;
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _artist = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(artistsApiProvider);
      final artist = _artist ?? await api.getArtist(widget.artistId);
      final songs = await api.getArtistSongs(widget.artistId);
      if (!mounted) return;
      setState(() {
        _artist = artist;
        _songs = songs;
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
          iconTheme: const IconThemeData(color: AppColors.text),
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
          iconTheme: const IconThemeData(color: AppColors.text),
        ),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    final a = _artist!;
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
              iconTheme: const IconThemeData(color: AppColors.text),
            ),
            SliverToBoxAdapter(child: _hero(a)),
            SliverToBoxAdapter(child: _actions()),
            if (_songs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: NexoraEmptyState(
                    icon: Icons.person_outline_rounded,
                    title: 'No tracks',
                    subtitle: 'We could not find tracks for this artist.',
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
                      final s = _songs[i];
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
                                s.album ?? 'Single',
                            duration:
                                formatDuration(Duration(seconds: s.duration ?? 0)),
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
                                .playSongs(_songs, initialIndex: i),
                            onMore: () {},
                          ),
                          if (i != _songs.length - 1)
                            const NexoraDivider(
                                indent: 64, endIndent: 0),
                        ],
                      );
                    },
                    childCount: _songs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _hero(Artist a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipOval(
            child: NexoraArtwork(
              url: a.artworkUrl,
              size: 140,
              radius: BorderRadius.zero,
              placeholderIcon: Icons.person_rounded,
            ),
          ),
          const SizedBox(width: NexoraSpacing.s20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ARTIST',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  a.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${a.albumCount ?? 0} albums • ${a.trackCount ?? _songs.length} tracks',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: NexoraTextButton(
              label: 'Play All',
              icon: Icons.play_arrow_rounded,
              primary: true,
              onTap: _songs.isEmpty
                  ? null
                  : () => ref
                      .read(playerProvider.notifier)
                      .playSongs(_songs, initialIndex: 0),
            ),
          ),
          const SizedBox(width: NexoraSpacing.s12),
          Expanded(
            child: NexoraTextButton(
              label: 'Shuffle',
              icon: Icons.shuffle_rounded,
              onTap: _songs.isEmpty
                  ? null
                  : () => ref.read(playerProvider.notifier).playSongs(
                        [..._songs]..shuffle(),
                        initialIndex: 0,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}