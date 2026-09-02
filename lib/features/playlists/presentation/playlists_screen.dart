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
    final isLight = AppColors.mode == AppThemeMode.light;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 22,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (c, i) => SlideInAnimation(
        delay: Duration(milliseconds: (i.clamp(0, 14)) * 40),
        duration: const Duration(milliseconds: 420),
        child: _ModernPlaylistCard(
          playlist: list[i],
          isLight: isLight,
          onTap: () => context.push('/playlists/${list[i].id}', extra: list[i]),
        ),
      ),
    );
  }
}

class _ModernPlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  final bool isLight;
  final VoidCallback onTap;
  const _ModernPlaylistCard({
    required this.playlist,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_playlistCoversProvider(playlist));
    return GestureDetector(
      onTap: onTap,
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
                      borderRadius: 20,
                      title: playlist.name,
                    ),
                    loading: () => PlaylistCover(
                      artworkUrls: const [],
                      borderRadius: 20,
                      title: playlist.name,
                    ),
                    error: (_, __) => PlaylistCover(
                      artworkUrls: const [],
                      borderRadius: 20,
                      title: playlist.name,
                    ),
                  ),
                ),
                // Track count pill — calm, theme-aware
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLight
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isLight
                            ? AppColors.hairline
                            : Colors.white.withValues(alpha: 0.18),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          size: 11,
                          color: isLight ? AppColors.text : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.trackCount ?? 0}',
                          style: TextStyle(
                            color: isLight ? AppColors.text : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Play overlay (top-right circle)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLight ? AppColors.text : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isLight ? 0.18 : 0.35,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: isLight ? Colors.white : AppColors.background,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${playlist.trackCount ?? 0} ${(playlist.trackCount ?? 0) == 1 ? "song" : "songs"}',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
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
    final isLight = AppColors.mode == AppThemeMode.light;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (c, i) {
        final p = list[i];
        return SlideInAnimation(
          delay: Duration(milliseconds: (i.clamp(0, 14)) * 32),
          duration: const Duration(milliseconds: 420),
          child: _ModernPlaylistRow(
            playlist: p,
            isLight: isLight,
            index: i,
            onTap: () => context.push('/playlists/${p.id}', extra: p),
          ),
        );
      },
    );
  }
}

class _ModernPlaylistRow extends ConsumerWidget {
  final Playlist playlist;
  final bool isLight;
  final int index;
  final VoidCallback onTap;
  const _ModernPlaylistRow({
    required this.playlist,
    required this.isLight,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coversAsync = ref.watch(_playlistCoversProvider(playlist));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.85)
              : AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLight ? AppColors.hairline : AppColors.glassBorderStrong,
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.18),
              blurRadius: isLight ? 14 : 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            SizedBox(
              width: 60,
              height: 60,
              child: coversAsync.when(
                data: (urls) => PlaylistCover(
                  artworkUrls: urls,
                  borderRadius: 14,
                  title: playlist.name,
                  emptyIconSize: 26,
                ),
                loading: () => PlaylistCover(
                  artworkUrls: const [],
                  borderRadius: 14,
                  title: playlist.name,
                  emptyIconSize: 26,
                ),
                error: (_, __) => PlaylistCover(
                  artworkUrls: const [],
                  borderRadius: 14,
                  title: playlist.name,
                  emptyIconSize: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Identity
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
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(playlist),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Modern play dot + chevron
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLight
                    ? AppColors.surfaceRaised
                    : AppColors.glassBase.withValues(alpha: 0.55),
                border: Border.all(
                  color: isLight
                      ? AppColors.hairline
                      : AppColors.glassBorderStrong,
                  width: 0.6,
                ),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: AppColors.text,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Playlist p) {
    final count = p.trackCount ?? 0;
    final songs = '$count ${count == 1 ? 'song' : 'songs'}';
    final desc = p.description;
    if (desc != null && desc.trim().isNotEmpty) {
      return '$songs • ${desc.trim()}';
    }
    return songs;
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
