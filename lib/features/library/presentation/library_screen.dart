import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/songs_repository.dart';
import '../../../data/api/albums_api.dart';
import '../../../data/api/artists_api.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(controller: _tab, indicatorColor: AppColors.primary, labelColor: Colors.white, unselectedLabelColor: AppColors.textMuted, tabs: const [Tab(text: 'Songs'), Tab(text: 'Albums'), Tab(text: 'Artists'), Tab(text: 'Downloads')]),
      ),
      body: TabBarView(controller: _tab, children: [
        _SongsTab(),
        _AlbumsTab(),
        _ArtistsTab(),
        _DownloadsTab(),
      ]),
    );
  }
}

class _SongsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<_SongsTab> {
  int _page = 1;
  final _songs = <dynamic>[];
  bool _loading = true;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) { _page = 1; _songs.clear(); _hasMore = true; }
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(songsRepositoryProvider);
      final p = await repo.getSongs(page: _page, limit: 20);
      setState(() { _songs.addAll(p.data); _hasMore = p.hasNext; _page++; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return ErrorView(message: _error!, onRetry: () => _load(refresh: true));
    if (_loading && _songs.isEmpty) return const LoadingView();
    if (_songs.isEmpty) return const EmptyView(title: 'No songs', subtitle: 'Check server connection or pull to refresh');
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _songs.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
        itemBuilder: (c, i) {
          if (i >= _songs.length) {
            if (!_loading) Future.microtask(() => _load());
            return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          }
          final s = _songs[i];
          return ListTile(
            leading: ArtworkImage(url: s.coverUrl, size: 48, borderRadius: 8),
            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text('${s.artist ?? 'Unknown'} • ${formatDuration(s.durationDuration)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (s.codec != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: Text(s.codec!.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10))),
              IconButton(icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 18), onPressed: () => _showSongMenu(s)),
            ]),
            onTap: () => ref.read(playerProvider.notifier).playSongs(_songs.cast(), initialIndex: i),
            onLongPress: () => _showSongMenu(s),
          );
        },
      ),
    );
  }

  void _showSongMenu(dynamic song) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.play_arrow, color: Colors.white), title: const Text('Play next', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(c); ref.read(playerProvider.notifier).playNext(song); }),
      ListTile(leading: const Icon(Icons.queue_music, color: Colors.white), title: const Text('Add to queue', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(c); ref.read(playerProvider.notifier).addToQueue(song); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to queue'))); }),
      ListTile(leading: const Icon(Icons.playlist_add, color: Colors.white), title: const Text('Add to playlist', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(c)),
    ])));
  }
}

class _AlbumsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(_albumsProvider);
    return albumsAsync.when(
      data: (list) => list.isEmpty ? const EmptyView(title: 'No albums', icon: Icons.album_outlined) : GridView.builder(padding: const EdgeInsets.all(16).copyWith(bottom: 100), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85), itemCount: list.length, itemBuilder: (c, i) {
        final a = list[i];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: ArtworkImage(url: a.coverUrl, borderRadius: 12)), const SizedBox(height: 8), Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), Text(a.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))]);
      }),
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

final _albumsProvider = FutureProvider((ref) async => (await ref.watch(albumsApiProvider).getAlbums(page: 1, limit: 50)).data);

class _ArtistsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(_artistsProvider);
    return artistsAsync.when(
      data: (list) => list.isEmpty ? const EmptyView(title: 'No artists', icon: Icons.person_outline) : ListView.separated(padding: const EdgeInsets.only(bottom: 100), separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1), itemCount: list.length, itemBuilder: (c, i) {
        final ar = list[i];
        return ListTile(leading: CircleAvatar(backgroundColor: AppColors.surfaceRaised, backgroundImage: ar.artworkUrl != null ? NetworkImage(ar.artworkUrl!) : null, child: ar.artworkUrl == null ? const Icon(Icons.person, color: AppColors.textMuted) : null), title: Text(ar.name, style: const TextStyle(color: Colors.white)), subtitle: Text('${ar.albumCount ?? 0} albums • ${ar.trackCount ?? 0} songs', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), trailing: const Icon(Icons.chevron_right, color: AppColors.textDim));
      }),
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

final _artistsProvider = FutureProvider((ref) async => (await ref.watch(artistsApiProvider).getArtists(page: 1, limit: 50)).data);

class _DownloadsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const EmptyView(title: 'No downloads', subtitle: 'Download tracks for offline playback', icon: Icons.download_outlined);
  }
}
