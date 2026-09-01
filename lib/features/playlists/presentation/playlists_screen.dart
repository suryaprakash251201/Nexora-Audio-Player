import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/playlists_repository.dart';
import '../../../data/api/files_api.dart';
import '../../../data/dto/file_dto.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});
  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  bool _grid = true; // Apple Music style: grid default, list toggle

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(_playlistsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Playlists'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: _grid ? 'List view' : 'Grid view',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            onPressed: () => setState(() => _grid = !_grid),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
      body: playlistsAsync.when(
        data: (list) => list.isEmpty
            ? const EmptyView(
                title: 'No playlists',
                subtitle: 'Create your first playlist',
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
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'New Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: AppColors.textDim),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(playlistsRepositoryProvider).createPlaylist(name);
      ref.invalidate(_playlistsProvider);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Created "$name"')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

final _playlistsProvider = FutureProvider(
  (ref) async => ref.watch(playlistsRepositoryProvider).getPlaylists(),
);

/// Cover for a playlist = first track's thumbnail (server extracts the
/// embedded cover; falls back to a cover image stored next to the track).
final _playlistCoverProvider = FutureProvider.family<String?, Playlist>((
  ref,
  pl,
) async {
  final tracks = pl.tracks ?? [];
  Song? first;
  for (final s in tracks) {
    if ((s.coverUrl ?? '').isNotEmpty) {
      first = s;
      break;
    }
    first ??= s; // remember first track as fallback
  }
  if (first == null) return null;
  if ((first.coverUrl ?? '').isNotEmpty) return first.coverUrl;
  final api = ref.watch(filesApiProvider);
  try {
    return await api.thumbnailUrl(
      NexoraFiles.parseRootId(first.id),
      NexoraFiles.parsePath(first.id),
      size: 512,
    );
  } catch (_) {
    return null;
  }
});

class _PlaylistTile extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(_playlistCoverProvider(playlist));
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: coverAsync.when(
              data: (url) => ArtworkImage(url: url, borderRadius: 14),
              loading: () => ArtworkImage(url: null, borderRadius: 14),
              error: (_, __) => ArtworkImage(url: null, borderRadius: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            '${playlist.trackCount ?? 0} songs',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  final List<Playlist> list;
  const _PlaylistGrid({required this.list});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (c, i) => _PlaylistTile(playlist: list[i]),
    );
  }
}

class _PlaylistList extends StatelessWidget {
  final List<Playlist> list;
  const _PlaylistList({required this.list});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          const Divider(color: AppColors.border, height: 1, indent: 84),
      itemBuilder: (c, i) {
        final p = list[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: _PlaylistCoverBadge(playlist: p),
          title: Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${p.trackCount ?? 0} songs${p.description != null && p.description!.isNotEmpty ? ' • ${p.description}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
          onTap: () => context.push('/playlists/${p.id}', extra: p),
        );
      },
    );
  }
}

class _PlaylistCoverBadge extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistCoverBadge({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(_playlistCoverProvider(playlist));
    return SizedBox(
      width: 56,
      height: 56,
      child: coverAsync.when(
        data: (url) => ArtworkImage(url: url, size: 56, borderRadius: 8),
        loading: () => ArtworkImage(url: null, size: 56, borderRadius: 8),
        error: (_, __) => ArtworkImage(url: null, size: 56, borderRadius: 8),
      ),
    );
  }
}
