import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/premium_widgets.dart';
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
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Songs, albums, artists, playlists',
                hintStyle: const TextStyle(color: AppColors.textDim),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          if (query.isEmpty)
            Expanded(
              child: recent.when(
                data: (list) => list.isEmpty
                    ? const EmptyView(
                        title: 'Search Nexora',
                        subtitle: 'Type to search across your library',
                        icon: Icons.search_rounded,
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.12),
                                      AppColors.secondary.withValues(
                                        alpha: 0.08,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Recent searches',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
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
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...list.map(
                            (q) => ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceRaised,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 0.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.history_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: Text(
                                q,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: const Icon(
                                Icons.north_west_rounded,
                                size: 16,
                                color: AppColors.textDim,
                              ),
                              onTap: () {
                                _controller.text = q;
                                ref.read(searchQueryProvider.notifier).state =
                                    q;
                              },
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
                  if (res == null || res.isEmpty)
                    return const EmptyView(
                      title: 'No results',
                      subtitle: 'Try a different query',
                      icon: Icons.search_off_rounded,
                    );
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      if (res.songs.isNotEmpty) ...[
                        _resultHeader('Songs', Icons.music_note_rounded),
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
                        _resultHeader('Albums', Icons.album_rounded),
                        ...res.albums.map((a) => _AlbumResultTile(album: a)),
                      ],
                      if (res.artists.isNotEmpty) ...[
                        _resultHeader('Artists', Icons.person_rounded),
                        ...res.artists.map(
                          (ar) => ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.secondary.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              ar.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                      if (res.playlists.isNotEmpty) ...[
                        _resultHeader('Playlists', Icons.queue_music_rounded),
                        ...res.playlists.map(
                          (p) => ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.secondary.withValues(alpha: 0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.queue_music_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              p.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${p.trackCount ?? 0} tracks',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
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
    );
  }

  Widget _resultHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
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
    final isPlaying = ref.watch(playerProvider).currentTrack?.id == song.id;
    return ListTile(
      leading: Stack(
        children: [
          ArtworkImage(url: song.coverUrl, size: 48, borderRadius: 10),
          if (isPlaying)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: NowPlayingIndicator(height: 14, width: 14),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isPlaying ? AppColors.primaryLight : Colors.white,
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        song.artist ?? '',
        style: const TextStyle(color: AppColors.textMuted),
      ),
      onTap: onTap,
    );
  }
}

class _AlbumResultTile extends StatelessWidget {
  final dynamic album;
  const _AlbumResultTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ArtworkImage(url: album.coverUrl, size: 48, borderRadius: 10),
      title: Text(album.title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        album.artist ?? '',
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
