import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../core/utils/formatters.dart';
import '../providers/search_provider.dart';
import '../../../data/repositories/search_repository.dart';
import '../../player/providers/player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final recent = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        hintText: 'Songs, albums, artists, playlists',
                        hintStyle: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                        ),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                    ),
                  ),
                ],
              ),
            ),
            if (query.isEmpty)
              Expanded(
                child: recent.when(
                  data: (list) => list.isEmpty
                      ? const EmptyView(
                          title: 'Search your library',
                          subtitle: 'Find songs, albums, artists, playlists',
                          icon: Icons.search_rounded,
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                          children: [
                            Row(
                              children: [
                                Text(
                                  'RECENT SEARCHES',
                                  style: TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(searchRepositoryProvider)
                                        .clearRecent();
                                    ref.invalidate(recentSearchesProvider);
                                  },
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final q in list)
                              InkWell(
                                onTap: () {
                                  _controller.text = q;
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .state = q;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.hairline,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 16,
                                        color: AppColors.textDim,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          q,
                                          style: TextStyle(
                                            color: AppColors.text,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.north_west_rounded,
                                        size: 16,
                                        color: AppColors.textDim,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString()),
                ),
              )
            else
              Expanded(
                child: results.when(
                  data: (res) {
                    if (res == null || res.isEmpty) {
                      return const EmptyView(
                        title: 'No results',
                        subtitle: 'Try a different query',
                        icon: Icons.search_off_rounded,
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 140),
                      children: [
                        if (res.songs.isNotEmpty) ...[
                          _resultHeader('Songs'),
                          ...res.songs.map(
                            (s) => _SongResultTile(
                              song: s,
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .playSongs(
                                    res.songs,
                                    initialIndex: res.songs.indexOf(s),
                                  ),
                            ),
                          ),
                        ],
                        if (res.albums.isNotEmpty) ...[
                          _resultHeader('Albums'),
                          ...res.albums.map((a) => _AlbumResultTile(album: a)),
                        ],
                        if (res.artists.isNotEmpty) ...[
                          _resultHeader('Artists'),
                          ...res.artists.map((a) => _ArtistResultTile(artist: a)),
                        ],
                        if (res.playlists.isNotEmpty) ...[
                          _resultHeader('Playlists'),
                          ...res.playlists.map((p) => _PlaylistResultTile(playlist: p)),
                        ],
                      ],
                    );
                  },
                  loading: () => const LoadingView(),
                  error: (e, st) => ErrorView(message: e.toString()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _resultHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textDim,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SongResultTile extends ConsumerWidget {
  final dynamic song;
  final VoidCallback onTap;
  const _SongResultTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying =
        ref.watch(playerProvider).currentTrack?.id == song.id;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.hairline, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.surfaceRaised,
                image: song.coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(song.coverUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: song.coverUrl == null
                  ? Icon(
                      Icons.music_note_rounded,
                      color: AppColors.textDim,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying ? AppColors.accent : AppColors.text,
                      fontWeight: isPlaying
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (song.duration != null)
              Text(
                formatDuration(
                  Duration(seconds: song.duration as int? ?? 0),
                ),
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumResultTile extends StatelessWidget {
  final dynamic album;
  const _AlbumResultTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          ArtworkImage(
            url: album.coverUrl,
            size: 48,
            borderRadius: 6,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  album.artist ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
}

class _ArtistResultTile extends StatelessWidget {
  final dynamic artist;
  const _ArtistResultTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceRaised,
              border: Border.all(color: AppColors.border, width: 0.6),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistResultTile extends StatelessWidget {
  final dynamic playlist;
  const _PlaylistResultTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.surfaceRaised,
            ),
            child: Icon(
              Icons.queue_music_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${playlist.trackCount ?? 0} tracks',
                  style: TextStyle(
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
}