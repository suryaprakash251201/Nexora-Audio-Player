import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/songs_repository.dart';
import '../../../data/api/albums_api.dart';
import '../../../data/api/artists_api.dart';
import '../../../data/api/files_api.dart';
import '../../../domain/entities/song.dart';
import '../../../domain/entities/album.dart';
import '../../../domain/entities/artist.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';
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
    final isDark = AppColors.mode == AppThemeMode.dark;
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
    final isDark = AppColors.mode == AppThemeMode.dark;
    return SizedBox(
      height: 44,
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
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.text
                          : (isDark ? AppColors.surfaceRaised : AppColors.card),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected
                            ? AppColors.text
                            : AppColors.border.withValues(alpha: 0.8),
                        width: 0.7,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: selected ? AppColors.background : AppColors.text,
                        fontSize: 12.5,
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
    final isDark = AppColors.mode == AppThemeMode.dark;
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
          final isCurrent = ref.watch(playerProvider).currentTrack?.id == s.id;
          return NexoraTrackRow(
            artworkUrl: s.coverUrl,
            title: s.title,
            subtitle:
                '${s.artist ?? 'Unknown'} • ${s.album ?? 'Unknown Album'}',
            duration: formatDuration(s.durationDuration),
            indexLabel: (i + 1).toString().padLeft(2, '0'),
            isCurrent: isCurrent,
            isPlaying: isCurrent && ref.watch(playerProvider).isPlaying,
            isFavorite: s.isFavorite,
            isDownloaded: s.isDownloaded,
            onTap: () => ref
                .read(playerProvider.notifier)
                .playSongs(_songs, initialIndex: i),
            onMore: () => _showSongMenu(s),
          );
        },
      ),
    );
  }

  void _showSongMenu(Song song) {
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
                leading: Icon(Icons.play_arrow_rounded, color: AppColors.text),
                title: Text(
                  'Play next',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(playerProvider.notifier).playNext(song);
                },
              ),
              ListTile(
                leading: Icon(Icons.queue_music_rounded, color: AppColors.text),
                title: Text(
                  'Add to queue',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(playerProvider.notifier).addToQueue(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ALBUMS TAB
// ═══════════════════════════════════════════════════════════════

final _albumsLibraryProvider = FutureProvider<List<Album>>((ref) async {
  return ref.watch(albumsApiProvider).getAlbums(limit: 200);
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
                16,
                16,
                NexoraSpacing.dockBottomReserve,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.80,
              ),
              itemCount: albums.length,
              itemBuilder: (c, i) => NexoraAlbumCard(
                coverUrl: albums[i].coverUrl,
                title: albums[i].title,
                subtitle: albums[i].artist,
                size: 170,
                onTap: () => context.push(
                  '/album/${Uri.encodeComponent(albums[i].id)}',
                  extra: albums[i],
                ),
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

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
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
              'Playlists, your way',
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
              'Curated collections live in their own section.\nOpen the Playlists tab in the bottom bar.',
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
                16,
                16,
                NexoraSpacing.dockBottomReserve,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.80,
              ),
              itemCount: folders.length,
              itemBuilder: (c, i) => NexoraAlbumCard(
                coverUrl: null,
                title: folders[i].name,
                subtitle: 'Folder',
                size: 170,
                onTap: () => context.push(
                  '/folder?root=${folders[i].rootId}&path=${Uri.encodeComponent(folders[i].path)}',
                ),
              ),
            ),
    );
  }
}
