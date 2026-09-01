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
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/playlist_cover.dart';
import '../../../ui/animations/app_animations.dart';

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
      body: AuroraBackground(
        child: playlistsAsync.when(
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
      ),
      floatingActionButton: GlassFAB(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Playlists',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
        ),
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
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => GlassDialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Playlist',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              EnhancedGlassSurface(
                opacity: 0.4,
                blur: 15,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Playlist name',
                    hintStyle: TextStyle(color: AppColors.textDim),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(c, controller.text.trim()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Create',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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

/// Resolves up to four distinct cover images for a playlist so the tile can
/// render a mosaic instead of reusing the same single artwork.
final _playlistCoversProvider = FutureProvider.family<List<String?>, Playlist>((
  ref,
  pl,
) async {
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

  // Fill the remaining slots by asking the server for thumbnails.
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
      } catch (_) {
        // Ignore individual failures; the mosaic just uses fewer tiles.
      }
    }
  }
  return covers;
});

class _PlaylistTile extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_playlistCoversProvider(playlist));
    return GlassCard(
      borderRadius: 18,
      onTap: () => context.push('/playlists/${playlist.id}', extra: playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: coversAsync.when(
                    data: (urls) => PlaylistCover(
                      artworkUrls: urls,
                      borderRadius: 18,
                      title: playlist.name,
                    ),
                    loading: () => PlaylistCover(
                      artworkUrls: const [],
                      borderRadius: 18,
                      title: playlist.name,
                    ),
                    error: (_, __) => PlaylistCover(
                      artworkUrls: const [],
                      borderRadius: 18,
                      title: playlist.name,
                    ),
                  ),
                ),
                // Track count badge
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${playlist.trackCount ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${playlist.trackCount ?? 0} songs',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 20,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (c, i) => SlideInAnimation(
        delay: Duration(milliseconds: i * 60),
        child: _PlaylistTile(playlist: list[i]),
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
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (c, i) {
        final p = list[i];
        return SlideInAnimation(
          delay: Duration(milliseconds: i * 50),
          child: GlassCard(
            borderRadius: 16,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            onTap: () => context.push('/playlists/${p.id}', extra: p),
            child: Row(
              children: [
                _PlaylistCoverBadge(playlist: p),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${p.trackCount ?? 0} songs${p.description != null && p.description!.isNotEmpty ? ' • ${p.description}' : ''}',
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
                Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
              ],
            ),
          ),
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
    final coversAsync = ref.watch(_playlistCoversProvider(playlist));
    return SizedBox(
      width: 56,
      height: 56,
      child: coversAsync.when(
        data: (urls) => PlaylistCover(
          artworkUrls: urls,
          borderRadius: 12,
          title: playlist.name,
          emptyIconSize: 24,
        ),
        loading: () => PlaylistCover(
          artworkUrls: const [],
          borderRadius: 12,
          title: playlist.name,
          emptyIconSize: 24,
        ),
        error: (_, __) => PlaylistCover(
          artworkUrls: const [],
          borderRadius: 12,
          title: playlist.name,
          emptyIconSize: 24,
        ),
      ),
    );
  }
}
