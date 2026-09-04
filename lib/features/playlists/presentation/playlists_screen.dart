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
import '../../../ui/widgets/track_menu_box.dart';

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

enum _PlaylistSort { recent, name, tracks }

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  bool _grid = true;
  bool _discover = false;
  _PlaylistSort _sort = _PlaylistSort.recent;

  /// Client-side ordering. `recent` keeps server order (already newest
  /// first); missing counts sort last so nothing ever crashes.
  List<Playlist> _sorted(List<Playlist> list) {
    final out = List<Playlist>.of(list);
    switch (_sort) {
      case _PlaylistSort.name:
        out.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _PlaylistSort.tracks:
        out.sort(
          (a, b) => (b.trackCount ?? b.tracks?.length ?? 0).compareTo(
            a.trackCount ?? a.tracks?.length ?? 0,
          ),
        );
      case _PlaylistSort.recent:
        break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(
      _discover ? _publicPlaylistsProvider : _playlistsProvider,
    );
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(color: AppColors.hairline, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 8),
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
                _ViewToggle(
                  grid: _grid,
                  onChanged: (v) => setState(() => _grid = v),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Mine | Discover scope switch + sort.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _ScopePill(
                  label: 'Mine',
                  selected: !_discover,
                  onTap: () => setState(() => _discover = false),
                ),
                const SizedBox(width: 8),
                _ScopePill(
                  label: 'Discover',
                  selected: _discover,
                  onTap: () => setState(() => _discover = true),
                ),
                const Spacer(),
                _SortButton(
                  sort: _sort,
                  onChanged: (v) => setState(() => _sort = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: playlistsAsync.when(
              data: (list) => list.isEmpty
                  ? (_discover
                        ? const _EmptyDiscover()
                        : _EmptyPlaylists(
                            isDark: isDark,
                            onCreate: _createPlaylist,
                          ))
                  : RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.card,
                      onRefresh: () async => ref.invalidate(
                        _discover
                            ? _publicPlaylistsProvider
                            : _playlistsProvider,
                      ),
                      child: _grid
                          ? _PlaylistGrid(
                              list: _sorted(list),
                              showOwner: _discover,
                              showCreate: !_discover,
                              onCreate: _createPlaylist,
                            )
                          : _PlaylistList(
                              list: _sorted(list),
                              showOwner: _discover,
                              showCreate: !_discover,
                              onCreate: _createPlaylist,
                            ),
                    ),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(
                  _discover ? _publicPlaylistsProvider : _playlistsProvider,
                ),
              ),
            ),
          ),
        ],
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

final _publicPlaylistsProvider = FutureProvider(
  (ref) async => ref.watch(playlistsRepositoryProvider).getPublicPlaylists(),
);

/// Mine | Discover scope pill.
class _ScopePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ScopePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.accentGradientHorizontal : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.border,
            width: 0.7,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyDiscover extends StatelessWidget {
  const _EmptyDiscover();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: NexoraEmptyState(
          icon: Icons.explore_outlined,
          title: 'Nothing shared yet',
          subtitle:
              'Public playlists from other listeners will appear here. Offline? Discovery needs a connection.',
        ),
      ),
    );
  }
}

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

/// Segmented grid|list switch (same Nexora pill language as scope).
class _ViewToggle extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.grid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleItem(
            icon: Icons.grid_view_rounded,
            selected: grid,
            onTap: () => onChanged(true),
          ),
          _ViewToggleItem(
            icon: Icons.view_list_rounded,
            selected: !grid,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ViewToggleItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 34,
        height: 30,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.accentGradientHorizontal : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Sort control reusing the anchored menu-box language.
class _SortButton extends StatelessWidget {
  final _PlaylistSort sort;
  final ValueChanged<_PlaylistSort> onChanged;
  const _SortButton({required this.sort, required this.onChanged});

  String get _label {
    switch (sort) {
      case _PlaylistSort.name:
        return 'A–Z';
      case _PlaylistSort.tracks:
        return 'Tracks';
      case _PlaylistSort.recent:
        return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (btnContext) => GestureDetector(
        onTap: () {
          final box = btnContext.findRenderObject() as RenderBox?;
          if (box == null || !box.hasSize) return;
          final pos = box.localToGlobal(Offset.zero);
          showTrackMenuBox(
            context: context,
            anchor: Rect.fromLTWH(
              pos.dx,
              pos.dy,
              box.size.width,
              box.size.height,
            ),
            options: [
              for (final mode in _PlaylistSort.values)
                TrackMenuOption(
                  icon: switch (mode) {
                    _PlaylistSort.name => Icons.sort_by_alpha_rounded,
                    _PlaylistSort.tracks => Icons.queue_music_rounded,
                    _PlaylistSort.recent => Icons.schedule_rounded,
                  },
                  label: switch (mode) {
                    _PlaylistSort.name => 'Name A–Z',
                    _PlaylistSort.tracks => 'Most tracks',
                    _PlaylistSort.recent => 'Recently created',
                  },
                  selected: mode == sort,
                  onTap: () => onChanged(mode),
                ),
            ],
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                _label,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed inline-create tile (grid) / row (list) — replaces the FAB.
class _CreateTile extends StatelessWidget {
  final VoidCallback onCreate;
  const _CreateTile({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onCreate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                color: AppColors.accent.withValues(alpha: 0.07),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'New',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create playlist',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateRow extends StatelessWidget {
  final VoidCallback onCreate;
  const _CreateRow({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCreate,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.45),
              width: 1.2,
            ),
            color: AppColors.accent.withValues(alpha: 0.07),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Create new playlist',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  final List<Playlist> list;
  final bool showOwner;
  final bool showCreate;
  final VoidCallback onCreate;
  const _PlaylistGrid({
    required this.list,
    this.showOwner = false,
    this.showCreate = false,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 168),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length + (showCreate ? 1 : 0),
      itemBuilder: (c, i) {
        if (showCreate && i == 0) return _CreateTile(onCreate: onCreate);
        final p = list[showCreate ? i - 1 : i];
        return _PlaylistCard(
          playlist: p,
          owner: showOwner ? p.ownerId : null,
          onTap: () => context.push('/playlists/${p.id}', extra: p),
        );
      },
    );
  }
}

class _PlaylistCard extends ConsumerWidget {
  final Playlist playlist;
  final String? owner;
  final VoidCallback onTap;
  const _PlaylistCard({
    required this.playlist,
    this.owner,
    required this.onTap,
  });

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
            owner != null && owner!.isNotEmpty
                ? 'by $owner • $trackCount ${trackCount == 1 ? 'song' : 'songs'}'
                : '$trackCount ${trackCount == 1 ? 'song' : 'songs'}',
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
  final bool showOwner;
  final bool showCreate;
  final VoidCallback onCreate;
  const _PlaylistList({
    required this.list,
    this.showOwner = false,
    this.showCreate = false,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 168),
      itemCount: list.length + (showCreate ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (c, i) {
        if (showCreate && i == 0) return _CreateRow(onCreate: onCreate);
        final p = list[showCreate ? i - 1 : i];
        return _PlaylistRow(
          playlist: p,
          owner: showOwner ? p.ownerId : null,
          onTap: () => context.push('/playlists/${p.id}', extra: p),
        );
      },
    );
  }
}

class _PlaylistRow extends ConsumerWidget {
  final Playlist playlist;
  final String? owner;
  final VoidCallback onTap;
  const _PlaylistRow({required this.playlist, this.owner, required this.onTap});

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
                            owner != null && owner!.isNotEmpty
                                ? 'by $owner • $trackCount ${trackCount == 1 ? 'song' : 'songs'}'
                                : '$trackCount ${trackCount == 1 ? 'song' : 'songs'}',
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
