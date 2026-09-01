import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
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
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs, albums, artists, playlists',
                hintStyle: const TextStyle(color: AppColors.textDim),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                        icon: Icons.search,
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Recent searches',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  // Actually clear stored searches, then refresh
                                  await ref
                                      .read(searchRepositoryProvider)
                                      .clearRecent();
                                  ref.invalidate(recentSearchesProvider);
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                          ...list.map(
                            (q) => ListTile(
                              leading: const Icon(
                                Icons.history,
                                color: AppColors.textMuted,
                              ),
                              title: Text(
                                q,
                                style: const TextStyle(color: Colors.white),
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
                      icon: Icons.search_off,
                    );
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      if (res.songs.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Songs',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...res.songs.map(
                          (s) => ListTile(
                            leading: ArtworkImage(
                              url: s.coverUrl,
                              size: 48,
                              borderRadius: 8,
                            ),
                            title: Text(
                              s.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              s.artist ?? '',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Albums',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...res.albums.map(
                          (a) => ListTile(
                            leading: ArtworkImage(
                              url: a.coverUrl,
                              size: 48,
                              borderRadius: 8,
                            ),
                            title: Text(
                              a.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              a.artist ?? '',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (res.artists.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Artists',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...res.artists.map(
                          (ar) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.surfaceRaised,
                              child: const Icon(
                                Icons.person,
                                color: AppColors.textMuted,
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
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            'Playlists',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...res.playlists.map(
                          (p) => ListTile(
                            leading: const Icon(
                              Icons.queue_music,
                              color: AppColors.primary,
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
}
