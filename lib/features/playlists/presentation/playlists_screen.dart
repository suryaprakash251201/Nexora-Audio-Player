import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dto/file_dto.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../data/api/files_api.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/playlist_cover.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});
  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(_playlistsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        title: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Playlists',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            icon: Icon(
              _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        elevation: 1,
        child: const Icon(Icons.add_rounded, size: 24),
      ),
      body: playlistsAsync.when(
        data: (list) => list.isEmpty
            ? const EmptyView(
                title: 'No playlists',
                subtitle: 'Tap + to create your first one',
                icon: Icons.queue_music_rounded,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_playlistsProvider),
                child: _grid
                    ? _PlaylistGrid(list: list)
                    : _PlaylistList(list: list),
              ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_playlistsProvider),
        ),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border, width: 0.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'NEW PLAYLIST',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  hintText: 'Playlist name',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(c, controller.text.trim()),
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(playlistsRepositoryProvider).createPlaylist(name);
      ref.invalidate(_playlistsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "$name"')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}

final _playlistsProvider = FutureProvider(
  (ref) async => ref.watch(playlistsRepositoryProvider).getPlaylists(),
);

final _playlistCoversProvider =
    FutureProvider.family<List<String?>, Playlist>((ref, pl) async {
      final tracks = pl.tracks ?? [];
      final covers = <String?>[];
      final pending = <Song>[];
      final directCover = pl.coverUrl;
      if (directCover != null && directCover.isNotEmpty) {
        covers.add(directCover);
      }

      for (final s in tracks) {
        final cover = s.coverUrl ?? s.artworkUrl;
        if (cover != null && cover.isNotEmpty) {
          covers.add(cover);
        } else {
          pending.add(s);
        }
        if (covers.length >= 4) break;
      }

      if (covers.length < 4 && pending.isNotEmpty) {
        final api = ref.watch(filesApiProvider);
        for (final s in pending) {
          if (covers.length >= 4) break;
          try {
            final url = await api.thumbnailUrl(
              NexoraFiles.parseRootId(s.id),
              NexoraFiles.parsePath(s.id),
              size: 256,
            );
            covers.add(url);
          } catch (_) {}
        }
      }
      return covers;
    });

class _PlaylistGrid extends StatelessWidget {
  final List<Playlist> list;
  const _PlaylistGrid({required this.list});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: list.length,
      itemBuilder: (c, i) => _PlaylistCard(
        playlist: list[i],
        onTap: () =>
            context.push('/playlists/${list[i].id}', extra: list[i]),
      ),
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  const _PlaylistCard({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_playlistCoversProvider(playlist));
    final trackCount = playlist.trackCount ?? 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: coversAsync.when(
              data: (urls) => PlaylistCover(
                artworkUrls: urls,
                borderRadius: 6,
                title: playlist.name,
              ),
              loading: () => PlaylistCover(
                artworkUrls: const [],
                borderRadius: 6,
                title: playlist.name,
              ),
              error: (_, __) => PlaylistCover(
                artworkUrls: const [],
                borderRadius: 6,
                title: playlist.name,
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
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$trackCount ${trackCount == 1 ? 'song' : 'songs'}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistList extends StatelessWidget {
  final List<Playlist> list;
  const _PlaylistList({required this.list});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (c, i) {
        final p = list[i];
        return _PlaylistRow(
          playlist: p,
          onTap: () => context.push('/playlists/${p.id}', extra: p),
        );
      },
    );
  }
}

class _PlaylistRow extends ConsumerWidget {
  final Playlist playlist;
  final VoidCallback onTap;
  const _PlaylistRow({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_playlistCoversProvider(playlist));
    final trackCount = playlist.trackCount ?? 0;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: coversAsync.when(
                data: (urls) => PlaylistCover(
                  artworkUrls: urls,
                  borderRadius: 6,
                  title: playlist.name,
                  emptyIconSize: 24,
                ),
                loading: () => PlaylistCover(
                  artworkUrls: const [],
                  borderRadius: 6,
                  title: playlist.name,
                  emptyIconSize: 24,
                ),
                error: (_, __) => PlaylistCover(
                  artworkUrls: const [],
                  borderRadius: 6,
                  title: playlist.name,
                  emptyIconSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$trackCount ${trackCount == 1 ? 'song' : 'songs'}',
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
              color: AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}