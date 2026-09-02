import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/bright_icons.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/animations/app_animations.dart';
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
      body: AuroraBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: EnhancedGlassSurface(
                        opacity: 0.5,
                        blur: 25,
                        borderRadius: BorderRadius.circular(18),
                        showShimmer: true,
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'Songs, albums, artists, playlists',
                            hintStyle: TextStyle(color: AppColors.textDim),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                            ),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () {
                                      _controller.clear();
                                      ref.read(searchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : null,
                            filled: false,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (v) =>
                              ref.read(searchQueryProvider.notifier).state = v,
                        ),
                      ),
                    ),
                  ],
                ),
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
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withValues(alpha: 0.15),
                                        AppColors.secondary.withValues(
                                          alpha: 0.1,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Recent searches',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
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
                            const SizedBox(height: 12),
                            ...list.map(
                              (q) => SlideInAnimation(
                                child: GlassCard(
                                  borderRadius: 16,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  onTap: () {
                                    _controller.text = q;
                                    ref.read(searchQueryProvider.notifier).state = q;
                                  },
                                  child: Row(
                                    children: [
                                      Container(
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
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          q,
                                          style: TextStyle(color: AppColors.text),
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
                      padding: const EdgeInsets.only(bottom: 140),
                      children: [
                        if (res.songs.isNotEmpty) ...[
                          _resultHeader('Songs', Icons.music_note_rounded, BrightIconTone.violet),
                          ...res.songs.map(
                            (s) => SlideInAnimation(
                              child: _SongResultTile(
                                song: s,
                                onTap: () => ref
                                    .read(playerProvider.notifier)
                                    .playSongs(
                                      res.songs,
                                      initialIndex: res.songs.indexOf(s),
                                    ),
                              ),
                            ),
                          ),
                        ],
                        if (res.albums.isNotEmpty) ...[
                          _resultHeader('Albums', Icons.album_rounded, BrightIconTone.pink),
                          ...res.albums.map((a) => SlideInAnimation(
                            child: _AlbumResultTile(album: a),
                          )),
                        ],
                        if (res.artists.isNotEmpty) ...[
                          _resultHeader('Artists', Icons.person_rounded, BrightIconTone.cyan),
                          ...res.artists.map(
                            (ar) => SlideInAnimation(
                              child: GlassCard(
                                borderRadius: 18,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const GlassBrightIcon(
                                      icon: Icons.person_rounded,
                                      tone: BrightIconTone.cyan,
                                      size: 44,
                                      iconSize: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        ar.name,
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (res.playlists.isNotEmpty) ...[
                          _resultHeader('Playlists', Icons.queue_music_rounded, BrightIconTone.emerald),
                          ...res.playlists.map(
                            (p) => SlideInAnimation(
                              child: GlassCard(
                                borderRadius: 18,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const GlassBrightIcon(
                                      icon: Icons.queue_music_rounded,
                                      tone: BrightIconTone.emerald,
                                      size: 44,
                                      iconSize: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            '${p.trackCount ?? 0} tracks',
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
      ),
    );
  }

  Widget _resultHeader(String title, IconData icon, [BrightIconTone tone = BrightIconTone.violet]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          GlassBrightIcon(
            icon: icon,
            tone: tone,
            size: 38,
            iconSize: 18,
            active: true,
            showGlow: true,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
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
    return GlassSongTile(
      artworkUrl: song.coverUrl,
      title: song.title,
      subtitle: song.artist ?? '',
      isCurrent: isPlaying,
      isPlaying: isPlaying && ref.watch(playerProvider).isPlaying,
      onTap: onTap,
    );
  }
}

class _AlbumResultTile extends StatelessWidget {
  final dynamic album;
  const _AlbumResultTile({required this.album});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ArtworkImage(url: album.coverUrl, size: 48, borderRadius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  album.title,
                  style: TextStyle(color: AppColors.text),
                ),
                Text(
                  album.artist ?? '',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
