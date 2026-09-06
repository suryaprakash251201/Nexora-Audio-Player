import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/nexora/nexora_page_header.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/track_menu_box.dart';
import '../../../core/download/download_manager.dart';
import '../../../core/utils/formatters.dart';
import '../providers/search_provider.dart';
import '../../../data/repositories/search_repository.dart';
import '../../player/providers/player_provider.dart';

/// Search — a calm, focused search experience.
///
/// Audiophile redesign: full-bleed header with inline search field, a
/// "browse" state with tonal filter chips + recents, and a result state
/// that surfaces four distinct lanes (songs / albums / artists / playlists)
/// with editorial headers and rich tiles.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static final _filters = <_FilterChipData>[
    _FilterChipData('All', Icons.apps_rounded, AppColors.accent),
    _FilterChipData('Songs', Icons.music_note_rounded, AppColors.hueViolet),
    _FilterChipData('Albums', Icons.album_rounded, AppColors.hueTeal),
    _FilterChipData('Artists', Icons.person_rounded, AppColors.warning),
    _FilterChipData(
      'Playlists',
      Icons.queue_music_rounded,
      AppColors.accentPink,
    ),
  ];

  int _selectedFilter = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final recent = ref.watch(recentSearchesProvider);
    final isDark = AppColors.mode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Unified top-level header — Search is a tab, not a pushed
            // route, so no back button (the old maybePop could pop the
            // whole shell). Same 32px rhythm as Library/Settings.
            NexoraPageHeader(
              title: 'Search',
              subtitle: 'Songs, albums, artists, playlists',
              actions: [
                if (query.isNotEmpty)
                  NexoraIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Clear search',
                    onTap: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      _focusNode.requestFocus();
                    },
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                keyboardType: TextInputType.text,
                style: TextStyle(color: AppColors.text, fontSize: 15),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  hintText: 'Songs, albums, artists, playlists',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            _focusNode.requestFocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border, width: 0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.border, width: 0.7),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.accent, width: 1.4),
                  ),
                ),
                onChanged: (v) =>
                    ref.read(searchQueryProvider.notifier).state = v,
                onSubmitted: (v) async {
                  ref.read(searchQueryProvider.notifier).state = v;
                  await ref.read(searchRepositoryProvider).saveRecentSearch(v);
                  ref.invalidate(recentSearchesProvider);
                },
              ),
            ),
            if (query.isNotEmpty)
              SizedBox(
                // 44px min touch target (was 40) + semantic selection.
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (c, i) {
                    final f = _filters[i];
                    final selected = _selectedFilter == i;
                    return Semantics(
                      selected: selected,
                      button: true,
                      label: 'Filter ${f.label}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => setState(() => _selectedFilter = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? f.color
                                  : (isDark
                                        ? AppColors.surfaceRaised
                                        : AppColors.card),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: selected
                                    ? Colors.white.withValues(alpha: 0.20)
                                    : AppColors.border.withValues(alpha: 0.8),
                                width: 0.8,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: f.color.withValues(alpha: 0.32),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  f.icon,
                                  size: 14,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f.label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.text,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: query.isEmpty
                  ? _buildBrowseState(recent, isDark)
                  : _buildResultState(results, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseState(AsyncValue recent, bool isDark) {
    return recent.when(
      data: (list) => list.isEmpty
          ? _BrowseEmpty(isDark: isDark)
          : ListView(
              // Unified dock reserve (was 168, clipped behind mini+nav).
              padding: const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                NexoraSpacing.dockBottomReserve,
              ),
              children: [
                _ResultHeader(
                  label: 'Recent searches',
                  action: 'Clear all',
                  onAction: () async {
                    await ref.read(searchRepositoryProvider).clearRecent();
                    ref.invalidate(recentSearchesProvider);
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.7),
                    boxShadow: isDark ? null : NexoraShadow.card(false),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < list.length; i++) ...[
                          _RecentSearchTile(
                            query: list[i],
                            onTap: () {
                              _controller.text = list[i];
                              ref.read(searchQueryProvider.notifier).state =
                                  list[i];
                            },
                          ),
                          if (i != list.length - 1)
                            Divider(
                              color: AppColors.hairline,
                              height: 0.5,
                              thickness: 0.5,
                              indent: 52,
                              endIndent: 0,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _ResultHeader(label: 'Browse'),
                const SizedBox(height: 12),
                _BrowseGrid(isDark: isDark),
              ],
            ),
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }

  Widget _buildResultState(AsyncValue<dynamic> results, bool isDark) {
    return results.when(
      data: (res) {
        if (res == null || res.isEmpty) {
          return EmptyView(
            title: 'No results',
            subtitle: 'Try a different query or check your spelling',
            icon: Icons.search_off_rounded,
          );
        }
        // Sliver-virtualized: songs recycle via SliverList.builder instead
        // of one giant Column (was jank with 50+ hits). Albums/artists/
        // playlists stay grouped cards — typically <20 items.
        final songs = List.from(res.songs);
        final showSongs = _selectedFilter == 0 || _selectedFilter == 1;
        final showAlbums = _selectedFilter == 0 || _selectedFilter == 2;
        final showArtists = _selectedFilter == 0 || _selectedFilter == 3;
        final showPlaylists = _selectedFilter == 0 || _selectedFilter == 4;
        return CustomScrollView(
          slivers: [
            if (songs.isNotEmpty && showSongs) ...[
              SliverToBoxAdapter(
                child: _ResultHeader(
                  label: 'Songs',
                  count: songs.length,
                  action: 'Play all',
                  onAction: () => ref
                      .read(playerProvider.notifier)
                      .playSongs(songs.cast(), initialIndex: 0),
                ),
              ),
              _SongResultSliver(songs: songs),
            ],
            if (res.albums.isNotEmpty && showAlbums) ...[
              SliverToBoxAdapter(
                child: _ResultHeader(label: 'Albums', count: res.albums.length),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: res.albums.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (c, i) {
                      final a = res.albums[i];
                      return _AlbumSearchCard(
                        coverUrl: a.coverUrl,
                        title: a.title,
                        subtitle: a.artist,
                        onTap: () => context.push(
                          '/album/${Uri.encodeComponent(a.id)}',
                          extra: a,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            if (res.artists.isNotEmpty && showArtists) ...[
              SliverToBoxAdapter(
                child: _ResultHeader(
                  label: 'Artists',
                  count: res.artists.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.7),
                    boxShadow: isDark ? null : NexoraShadow.card(false),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < res.artists.length; i++) ...[
                          _ArtistResultTile(artist: res.artists[i]),
                          if (i != res.artists.length - 1)
                            Divider(
                              color: AppColors.hairline,
                              height: 0.5,
                              thickness: 0.5,
                              indent: 70,
                              endIndent: 0,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (res.playlists.isNotEmpty && showPlaylists) ...[
              SliverToBoxAdapter(
                child: _ResultHeader(
                  label: 'Playlists',
                  count: res.playlists.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.7),
                    boxShadow: isDark ? null : NexoraShadow.card(false),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < res.playlists.length; i++) ...[
                          _PlaylistResultTile(playlist: res.playlists[i]),
                          if (i != res.playlists.length - 1)
                            Divider(
                              color: AppColors.hairline,
                              height: 0.5,
                              thickness: 0.5,
                              indent: 70,
                              endIndent: 0,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: NexoraSpacing.dockBottomReserve),
            ),
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (e, st) => ErrorView(message: e.toString()),
    );
  }
}

class _FilterChipData {
  final String label;
  final IconData icon;
  final Color color;
  const _FilterChipData(this.label, this.icon, this.color);
}

class _BrowseEmpty extends StatelessWidget {
  final bool isDark;
  const _BrowseEmpty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  width: 0.7,
                ),
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Find your sound',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Search across your whole library — songs, albums,\nartists, and playlists.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseGrid extends StatelessWidget {
  final bool isDark;
  const _BrowseGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final entries = <_BrowseEntry>[
      _BrowseEntry('Songs', Icons.music_note_rounded, AppColors.hueViolet),
      _BrowseEntry('Albums', Icons.album_rounded, AppColors.hueTeal),
      _BrowseEntry('Artists', Icons.person_rounded, AppColors.warning),
      _BrowseEntry(
        'Playlists',
        Icons.queue_music_rounded,
        AppColors.accentPink,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: [
        for (final e in entries) _BrowseTile(entry: e, isDark: isDark),
      ],
    );
  }
}

class _BrowseEntry {
  final String label;
  final IconData icon;
  final Color color;
  _BrowseEntry(this.label, this.icon, this.color);
}

class _BrowseTile extends StatelessWidget {
  final _BrowseEntry entry;
  final bool isDark;
  const _BrowseTile({required this.entry, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/library'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.7),
            boxShadow: isDark ? null : NexoraShadow.card(false),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: entry.color.withValues(alpha: 0.20),
                    width: 0.6,
                  ),
                ),
                child: Icon(entry.icon, color: entry.color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                entry.label,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  const _RecentSearchTile({required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  query,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.north_west_rounded,
                size: 16,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String label;
  final int? count;
  final String? action;
  final VoidCallback? onAction;
  const _ResultHeader({
    required this.label,
    this.count,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count!.toString(),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(
                action!,
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Virtualized song hits — one [NexoraTrackRow] per sliver item so 50+
/// results recycle instead of building a single giant Column. Same row
/// language as Library (index, artwork, favorite/download dots, anchored
/// overflow menu) with hairline separators.
class _SongResultSliver extends ConsumerWidget {
  final List<dynamic> songs;
  const _SongResultSliver({required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(
      playerProvider.select((s) => s.currentTrack?.id),
    );
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));
    final downloadedIds = ref.watch(downloadedIdsProvider);
    return SliverList.builder(
      itemCount: songs.length,
      itemBuilder: (c, i) {
        final song = songs[i];
        final isCurrent = currentId == song.id;
        String? subtitle;
        try {
          subtitle = song.artist as String? ?? 'Unknown';
        } catch (_) {
          subtitle = 'Unknown';
        }
        String? durationLabel;
        try {
          final secs = song.duration as int?;
          if (secs != null) {
            durationLabel = formatDuration(Duration(seconds: secs));
          }
        } catch (_) {}
        String? cover;
        try {
          cover = song.coverUrl as String?;
        } catch (_) {}
        bool fav = false;
        try {
          fav = (song.isFavorite as bool?) ?? false;
        } catch (_) {}
        String songId = '';
        try {
          songId = (song.id as String?) ?? '';
        } catch (_) {}
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NexoraTrackRow(
              artworkUrl: cover,
              title: (song.title as String?) ?? '-',
              subtitle: subtitle,
              duration: durationLabel,
              indexLabel: (i + 1).toString().padLeft(2, '0'),
              isCurrent: isCurrent,
              isPlaying: isCurrent && isPlaying,
              isFavorite: fav,
              isDownloaded: downloadedIds.contains(songId),
              onTap: () => ref
                  .read(playerProvider.notifier)
                  .playSongs(songs.cast(), initialIndex: i),
              onMoreAt: (anchor) {
                try {
                  showTrackMenuBox(
                    context: context,
                    anchor: anchor,
                    options: trackMenuOptions(
                      ref: ref,
                      context: context,
                      song: song,
                    ),
                  );
                } catch (_) {}
              },
            ),
            if (i != songs.length - 1)
              const NexoraDivider(indent: 64, endIndent: 12),
          ],
        );
      },
    );
  }
}

class _AlbumSearchCard extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _AlbumSearchCard({
    required this.coverUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkImage(
              url: coverUrl,
              size: 140,
              borderRadius: 14,
              showShadow: true,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle ?? 'Album',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistResultTile extends StatelessWidget {
  final dynamic artist;
  const _ArtistResultTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '/artist/${Uri.encodeComponent(artist.id)}',
          extra: artist,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              ClipOval(
                child: ArtworkImage(
                  url: artist.artworkUrl,
                  size: 48,
                  borderRadius: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    if ((artist.albumCount ?? 0) > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${artist.albumCount} albums',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistResultTile extends StatelessWidget {
  final dynamic playlist;
  const _PlaylistResultTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.30),
                      AppColors.accent.withValues(alpha: 0.10),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  color: AppColors.accent,
                  size: 22,
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.trackCount ?? 0} tracks',
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
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
