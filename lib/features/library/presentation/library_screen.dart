import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/songs_repository.dart';
import '../../../domain/entities/song.dart';
import '../../../data/api/files_api.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/animations/app_animations.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';
import 'folder_browser_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                pinned: true,
                floating: true,
                title: Text(
                  'Library',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                bottom: TabBar(
                  controller: _tab,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: AppColors.text,
                  unselectedLabelColor: AppColors.textDim,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  dividerColor: AppColors.border,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Songs'),
                    Tab(text: 'Folders'),
                    Tab(text: 'Downloads'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tab,
            children: [_SongsTab(), _FoldersTab(), _DownloadsTab()],
          ),
        ),
      ),
    );
  }
}

class _SongsTab extends ConsumerStatefulWidget {
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
      // Guard against the pagination race: the "load more" sentinel can be
      // built several times before the first request sets `_loading`, which
      // previously fetched the same page twice and duplicated every song.
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
      // De-duplicate the accumulated pages by canonical id, preserving the
      // first occurrence when server pages overlap.
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
      );
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 140),
        itemCount: _songs.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 4),
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
          return SlideInAnimation(
            delay: Duration(milliseconds: (i % 10) * 50),
            child: GlassSongTile(
              artworkUrl: s.coverUrl,
              title: s.title,
              subtitle:
                  '${s.artist ?? 'Unknown'} • ${formatDuration(s.durationDuration)}',
              isCurrent: isCurrent,
              isPlaying: isCurrent && ref.watch(playerProvider).isPlaying,
              onTap: () => ref
                  .read(playerProvider.notifier)
                  .playSongs(_songs, initialIndex: i),
              onMore: () => _showSongMenu(s),
              trailing: s.codec != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        s.codec!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _showSongMenu(dynamic song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => GlassBottomSheet(
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textDim.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.play_arrow_rounded, color: AppColors.text),
                title: Text(
                  'Play next',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Navigator.pop(c);
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
                  Navigator.pop(c);
                  ref.read(playerProvider.notifier).addToQueue(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.text,
                ),
                title: Text(
                  'Add to playlist',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () => Navigator.pop(c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoldersTab extends ConsumerWidget {
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
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(_foldersProvider(rootId)),
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 190,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.78,
                ),
                itemCount: folders.length,
                itemBuilder: (c, i) => SlideInAnimation(
                  delay: Duration(milliseconds: i * 60),
                  child: _FolderCard(folder: folders[i]),
                ),
              ),
            ),
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

class _FolderCard extends ConsumerWidget {
  final FolderEntry folder;
  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(folderCoverProvider(folder.id));
    return GlassCard(
      borderRadius: 18,
      onTap: () => context.push(
        '/folder?root=${folder.rootId}&path=${Uri.encodeComponent(folder.path)}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: coverAsync.when(
              data: (url) => ArtworkImage(url: url, borderRadius: 18),
              loading: () => ArtworkImage(url: null, borderRadius: 18),
              error: (_, __) => ArtworkImage(url: null, borderRadius: 18),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EmptyView(
      title: 'No downloads',
      subtitle: 'Download tracks for offline playback',
      icon: Icons.download_outlined,
    );
  }
}
