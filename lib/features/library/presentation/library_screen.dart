import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/songs_repository.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../data/api/albums_api.dart';
import '../../../data/api/artists_api.dart';
import '../../../data/api/files_api.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/playlist.dart';
import '../../../ui/widgets/playlist_cover.dart';
import '../../../ui/widgets/track_menu_box.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart' show nexoraArtworkCache;
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';
import '../../../core/download/download_manager.dart';
import 'folder_browser_screen.dart';

/// Library — five editorial lanes behind a confident header.
///
/// Audiophile redesign: large page title, tonal segmented tab bar
/// (adaptive, with custom layout), and a content area that swaps in
/// real lists/grids with calm hover/select states.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  static const _tabs = ['Songs', 'Albums', 'Artists', 'Playlists', 'Folders'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Page header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Library',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your collection, organized.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NexoraIconButton(
                    icon: Icons.search_rounded,
                    onTap: () => context.go('/search'),
                    tooltip: 'Search',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SegmentedTabs(controller: _tab, tabs: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const BouncingScrollPhysics(),
                children: const [
                  _SongsTab(),
                  _AlbumsTab(),
                  _ArtistsTab(),
                  _PlaylistsTab(),
                  _FoldersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEGMENTED TABS
// ═══════════════════════════════════════════════════════════════

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  const _SegmentedTabs({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (c, i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (c, _) {
              final selected = controller.index == i;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.animateTo(i),
                  borderRadius: BorderRadius.circular(24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.accentGradient : null,
                      color: selected ? null : AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.20)
                            : AppColors.border.withValues(alpha: 0.9),
                        width: 0.8,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.30),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SONGS TAB
// ═══════════════════════════════════════════════════════════════

class _SongsTab extends ConsumerStatefulWidget {
  const _SongsTab();
  @override
  ConsumerState<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<_SongsTab> {
  int _page = 1;
  final _songs = <Song>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _songs.clear();
      _hasMore = true;
      _loadingMore = false;
    } else {
      if (_loadingMore || !_hasMore) return;
      _loadingMore = true;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(songsRepositoryProvider);
      final p = await repo.getSongs(page: _page, limit: 20);
      if (!mounted) return;
      final combined = SongsRepository.deduplicateById([..._songs, ...p.data]);
      setState(() {
        _songs
          ..clear()
          ..addAll(combined);
        _hasMore = p.hasNext;
        _page++;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return ErrorView(message: _error!, onRetry: () => _load(refresh: true));
    if (_loading && _songs.isEmpty) return const LoadingView();
    if (_songs.isEmpty)
      return const EmptyView(
        title: 'No songs',
        subtitle: 'Check server connection or pull to refresh',
        icon: Icons.music_note_outlined,
      );
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: () => _load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          top: 8,
          bottom: NexoraSpacing.dockBottomReserve,
        ),
        itemCount: _songs.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const NexoraDivider(indent: 64, endIndent: 0),
        itemBuilder: (c, i) {
          if (i >= _songs.length) {
            if (!_loading && !_loadingMore && _hasMore) {
              Future.microtask(() => _load());
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final s = _songs[i];
          final isCurrent =
              ref.watch(playerProvider.select((s) => s.currentTrack?.id)) ==
              s.id;
          return NexoraTrackRow(
            artworkUrl: s.coverUrl,
            title: s.title,
            subtitle:
                '${s.artist ?? 'Unknown'} • ${s.album ?? 'Unknown Album'}',
            duration: formatDuration(s.durationDuration),
            indexLabel: (i + 1).toString().padLeft(2, '0'),
            isCurrent: isCurrent,
            isPlaying:
                isCurrent &&
                ref.watch(playerProvider.select((s) => s.isPlaying)),
            isFavorite: s.isFavorite,
            isDownloaded:
                s.isDownloaded ||
                ref.watch(downloadedIdsProvider).contains(s.id),
            onTap: () => ref
                .read(playerProvider.notifier)
                .playSongs(_songs, initialIndex: i),
            onMoreAt: (anchor) => _showSongMenu(s, anchor),
          );
        },
      ),
    );
  }

  void _showSongMenu(Song song, Rect anchor) {
    showTrackMenuBox(
      context: context,
      anchor: anchor,
      options: trackMenuOptions(ref: ref, context: context, song: song),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ALBUMS TAB
// ═══════════════════════════════════════════════════════════════

final _albumsLibraryProvider = FutureProvider<List<Album>>((ref) async {
  return ref.watch(albumsApiProvider).getAlbums(limit: 200);
});

/// Folder cover for an album id ("root|path") — albums are directories,
/// so the cover is the image inside the folder (cover.jpg / first track
/// art), resolved lazily per card.
final _albumCoverProvider = FutureProvider.family<String?, String>((
  ref,
  albumId,
) async {
  final api = ref.watch(filesApiProvider);
  final idx = albumId.indexOf('|');
  if (idx <= 0) return null;
  try {
    return await api.folderCoverUrl(
      albumId.substring(0, idx),
      albumId.substring(idx + 1),
    );
  } catch (_) {
    return null;
  }
});

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_albumsLibraryProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_albumsLibraryProvider),
      ),
      data: (albums) => albums.isEmpty
          ? const EmptyView(
              title: 'No albums',
              subtitle: 'Albums appear when the server has music folders',
              icon: Icons.album_outlined,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                NexoraSpacing.dockBottomReserve,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: albums.length,
              itemBuilder: (c, i) => _AlbumGridCard(album: albums[i]),
            ),
    );
  }
}

/// Album card with lazily resolved folder cover (image inside the album
/// folder). Falls back to the artwork icon while loading / when missing.
class _AlbumGridCard extends ConsumerWidget {
  final Album album;
  const _AlbumGridCard({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(_albumCoverProvider(album.id));
    final url = coverAsync.value ?? album.coverUrl;
    return NexoraAlbumCard(
      coverUrl: url,
      title: album.title,
      subtitle: album.artist ?? 'Album',
      size: 170,
      onTap: () => context.push(
        '/album/${Uri.encodeComponent(album.id)}',
        extra: Album(
          id: album.id,
          title: album.title,
          artist: album.artist,
          artistId: album.artistId,
          year: album.year,
          genre: album.genre,
          coverUrl: url,
          trackCount: album.trackCount,
          duration: album.duration,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ARTISTS TAB
// ═══════════════════════════════════════════════════════════════

final _artistsLibraryProvider = FutureProvider<List<Artist>>((ref) async {
  return ref.watch(artistsApiProvider).getArtists(limit: 200);
});

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_artistsLibraryProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_artistsLibraryProvider),
      ),
      data: (artists) => artists.isEmpty
          ? const EmptyView(
              title: 'No artists',
              subtitle: 'Artists appear when the server has music folders',
              icon: Icons.person_outline_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(
                top: 4,
                bottom: NexoraSpacing.dockBottomReserve,
              ),
              itemCount: artists.length,
              separatorBuilder: (_, __) =>
                  const NexoraDivider(indent: 88, endIndent: 0),
              itemBuilder: (c, i) => NexoraArtistRow(
                artworkUrl: artists[i].artworkUrl,
                name: artists[i].name,
                subtitle:
                    '${artists[i].albumCount ?? 0} albums • ${artists[i].trackCount ?? 0} tracks',
                onTap: () => context.push(
                  '/artist/${Uri.encodeComponent(artists[i].id)}',
                  extra: artists[i],
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PLAYLISTS TAB
// ═══════════════════════════════════════════════════════════════

/// All playlists, inline in Library (same source as the Playlists tab).
final _libraryPlaylistsProvider = FutureProvider<List<Playlist>>((ref) async {
  return ref.watch(playlistsRepositoryProvider).getPlaylists();
});

/// Mosaic covers for a library playlist card (direct cover + track art).
final _libraryPlaylistCoversProvider =
    FutureProvider.family<List<String?>, String>((ref, playlistId) async {
      final repo = ref.watch(playlistsRepositoryProvider);
      try {
        final p = await repo.getPlaylist(playlistId);
        final urls = <String?>[];
        if (p.coverUrl != null && p.coverUrl!.isNotEmpty) {
          urls.add(p.coverUrl);
        }
        var tracks = p.tracks ?? const <Song>[];
        if (tracks.isEmpty) {
          try {
            tracks = await repo.getPlaylistTracks(playlistId);
          } catch (_) {}
        }
        for (final t in tracks) {
          final u = t.coverUrl ?? t.artworkUrl;
          if (u != null && u.isNotEmpty) {
            urls.add(u);
            if (urls.length >= 4) break;
          }
        }
        return urls;
      } catch (_) {
        return const <String?>[];
      }
    });

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_libraryPlaylistsProvider);
    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_libraryPlaylistsProvider),
      ),
      data: (list) => list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.22),
                          width: 0.7,
                        ),
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        color: AppColors.accent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'No playlists yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create one from the Playlists tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    NexoraTextButton(
                      label: 'Open Playlists',
                      icon: Icons.arrow_forward_rounded,
                      primary: true,
                      onTap: () => context.go('/playlists'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: () async => ref.invalidate(_libraryPlaylistsProvider),
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  NexoraSpacing.dockBottomReserve,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.76,
                ),
                itemCount: list.length,
                itemBuilder: (c, i) => _LibraryPlaylistCard(playlist: list[i]),
              ),
            ),
    );
  }
}

class _LibraryPlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  const _LibraryPlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_libraryPlaylistCoversProvider(playlist.id));
    final count = playlist.trackCount ?? playlist.tracks?.length ?? 0;
    return NexoraPressable(
      onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'playlist-cover-${playlist.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.mode == AppThemeMode.dark
                      ? null
                      : NexoraShadow.card(false),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: coversAsync.when(
                    data: (urls) => PlaylistCover(
                      artworkUrls: urls,
                      borderRadius: 0,
                      title: playlist.name,
                    ),
                    loading: () => PlaylistCover(
                      artworkUrls: const [],
                      borderRadius: 0,
                      title: playlist.name,
                    ),
                    error: (_, __) => PlaylistCover(
                      artworkUrls: const [],
                      borderRadius: 0,
                      title: playlist.name,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count ${count == 1 ? 'song' : 'songs'}',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOLDERS TAB
// ═══════════════════════════════════════════════════════════════

class _FoldersTab extends ConsumerWidget {
  const _FoldersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootIdAsync = ref.watch(_musicRootProvider);
    return rootIdAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_musicRootProvider),
      ),
      data: (rootId) => rootId == null
          ? const EmptyView(
              title: 'No music root',
              subtitle: 'No storage root found on the server',
              icon: Icons.folder_off_outlined,
            )
          : _FolderGrid(rootId: rootId),
    );
  }
}

final _musicRootProvider = FutureProvider<String?>((ref) async {
  final api = ref.watch(filesApiProvider);
  return api.musicRootId();
});

final _foldersProvider = FutureProvider.family<List<FolderEntry>, String>((
  ref,
  rootId,
) async {
  final api = ref.watch(filesApiProvider);
  final items = await api.list(rootId, '', limit: 500);
  return [
    for (final f in items)
      if (f.isDir)
        FolderEntry(
          rootId: rootId,
          path: f.path.isEmpty ? f.name : f.path,
          name: f.name,
        ),
  ];
});

/// Folder cover = image inside the folder (cover art / first track art).
final _libraryFolderCoverProvider = FutureProvider.family<String?, String>((
  ref,
  folderId,
) async {
  final api = ref.watch(filesApiProvider);
  final idx = folderId.indexOf('|');
  if (idx <= 0) return null;
  try {
    return await api.folderCoverUrl(
      folderId.substring(0, idx),
      folderId.substring(idx + 1),
    );
  } catch (_) {
    return null;
  }
});

class _FolderGrid extends ConsumerWidget {
  final String rootId;
  const _FolderGrid({required this.rootId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(_foldersProvider(rootId));
    return foldersAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(_foldersProvider(rootId)),
      ),
      data: (folders) => folders.isEmpty
          ? const EmptyView(
              title: 'No folders',
              subtitle: 'The music root is empty',
              icon: Icons.folder_open,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                NexoraSpacing.dockBottomReserve,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
              itemCount: folders.length,
              itemBuilder: (c, i) => _LibraryFolderCard(entry: folders[i]),
            ),
    );
  }
}

/// Folder card — cover image from inside the folder, gradient overlay +
/// folder badge + name. Same visual language as album cards.
class _LibraryFolderCard extends ConsumerWidget {
  final FolderEntry entry;
  const _LibraryFolderCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(_libraryFolderCoverProvider(entry.id));
    return GestureDetector(
      onTap: () => context.push(
        '/folder?root=${entry.rootId}&path=${Uri.encodeComponent(entry.path)}',
      ),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppColors.mode == AppThemeMode.dark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : NexoraShadow.card(false),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    coverAsync.when(
                      data: (url) => url != null && url.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              cacheManager: nexoraArtworkCache,
                              errorWidget: (_, _, _) => const _FolderFallback(),
                            )
                          : const _FolderFallback(),
                      loading: () => Container(
                        color: AppColors.surfaceRaised,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (_, __) => const _FolderFallback(),
                    ),
                    // Bottom gradient for badge legibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Folder',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _FolderFallback extends StatelessWidget {
  const _FolderFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Icon(Icons.folder_rounded, color: AppColors.textDim, size: 40),
      ),
    );
  }
}
