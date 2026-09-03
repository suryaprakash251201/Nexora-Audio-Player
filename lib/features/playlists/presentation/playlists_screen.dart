import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dto/file_dto.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../data/api/files_api.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/playlist_cover.dart';

/// Playlists — full audiophile redesign.
///
/// Header with a large title, count summary, and view toggle (grid/list).
/// Grids use rich playlist tiles with mosaic covers; list mode uses
/// horizontal rows that feel closer to a hi-fi library list.
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
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Playlists',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        playlistsAsync.value != null &&
                                playlistsAsync.value!.isNotEmpty
                            ? '${playlistsAsync.value!.length} collections, ready to play.'
                            : 'Curated collections, ready to play.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13.5,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _grid = !_grid),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 0.7),
                      ),
                      child: Icon(
                        _grid
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: AppColors.text,
                        size: 19,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _createPlaylist,
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, size: 24),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: playlistsAsync.when(
          data: (list) => list.isEmpty
              ? _EmptyPlaylists(isDark: isDark, onCreate: _createPlaylist)
              : RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.card,
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
    );
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border, width: 0.7),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.20),
                        width: 0.6,
                      ),
                    ),
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'New playlist',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: AppColors.text, fontSize: 15),
                cursorColor: AppColors.accent,
                decoration: InputDecoration(
                  hintText: 'Playlist name',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surfaceRaised.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 0.7),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border, width: 0.7),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border, width: 0.7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(c, controller.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Created "$name"')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}

class _EmptyPlaylists extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCreate;
  const _EmptyPlaylists({required this.isDark, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
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
                size: 36,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'No playlists yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Curate your favorite tracks into a playlist\nand revisit them any time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            NexoraTextButton(
              label: 'Create your first playlist',
              icon: Icons.add_rounded,
              primary: true,
              onTap: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

final _playlistsProvider = FutureProvider(
  (ref) async => ref.watch(playlistsRepositoryProvider).getPlaylists(),
);

final _playlistCoversProvider = FutureProvider.family<List<String?>, Playlist>((
  ref,
  pl,
) async {
  // FIX #6: playlists from getPlaylists() usually carry no tracks, so
  // covers stayed empty. Fetch tracks on demand for the mosaic.
  List<Song> tracks = pl.tracks ?? [];
  if (tracks.isEmpty) {
    try {
      tracks = await ref
          .watch(playlistsRepositoryProvider)
          .getPlaylistTracks(pl.id);
    } catch (_) {
      tracks = pl.tracks ?? [];
    }
  }
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: list.length,
      itemBuilder: (c, i) => _PlaylistCard(
        playlist: list[i],
        onTap: () => context.push('/playlists/${list[i].id}', extra: list[i]),
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
    final trackCount = playlist.trackCount ?? playlist.tracks?.length ?? 0;
    final isDark = AppColors.mode == AppThemeMode.dark;
    return NexoraPressable(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'playlist-cover-${playlist.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : const Color(0xFF0F1D3A).withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      coversAsync.when(
                        data: (urls) => PlaylistCover(
                          artworkUrls: urls,
                          borderRadius: 0,
                          title: playlist.name,
                        ),
                        loading: () =>
                            Container(color: AppColors.surfaceRaised),
                        error: (_, __) => PlaylistCover(
                          artworkUrls: const [],
                          borderRadius: 0,
                          title: playlist.name,
                        ),
                      ),
                      // Bottom scrim + floating play button.
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.38),
                            ],
                            stops: const [0.62, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
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
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$trackCount ${trackCount == 1 ? 'song' : 'songs'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final trackCount = playlist.trackCount ?? playlist.tracks?.length ?? 0;
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 0.7),
            boxShadow: isDark ? null : NexoraShadow.card(false),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'playlist-cover-${playlist.id}',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.12,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: coversAsync.when(
                      data: (urls) => PlaylistCover(
                        artworkUrls: urls,
                        borderRadius: 0,
                        title: playlist.name,
                        emptyIconSize: 24,
                      ),
                      loading: () => Container(color: AppColors.surfaceRaised),
                      error: (_, __) => PlaylistCover(
                        artworkUrls: const [],
                        borderRadius: 0,
                        title: playlist.name,
                        emptyIconSize: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          size: 11,
                          color: AppColors.textFaint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$trackCount ${trackCount == 1 ? 'song' : 'songs'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
