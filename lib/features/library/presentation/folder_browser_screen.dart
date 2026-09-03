import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/files_api.dart';
import '../../../data/dto/file_dto.dart';
import '../../../ui/theme.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../player/providers/player_provider.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/widgets/track_menu_box.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';

/// A folder in the Nexora Music root, with a lazily resolved cover.
class FolderEntry {
  final String rootId;
  final String path;
  final String name;

  FolderEntry({required this.rootId, required this.path, required this.name});

  String get id => '$rootId|$path';

  Future<String?> coverUrl(FilesApi api) async {
    return api.folderCoverUrl(rootId, path);
  }
}

class FolderContent {
  final List<FolderEntry> folders;
  final List<dynamic> songs;
  FolderContent({required this.folders, required this.songs});
}

/// Loads a folder: sub-folders + audio songs.
final folderContentProvider = FutureProvider.autoDispose
    .family<FolderContent, ({String rootId, String path})>((ref, args) async {
      final api = ref.watch(filesApiProvider);
      final items = await api.list(args.rootId, args.path, limit: 500);

      final folders = <FolderEntry>[];
      final songs = <dynamic>[];

      for (final f in items) {
        if (f.isDir) {
          final dirPath = f.path.isEmpty ? f.name : f.path;
          folders.add(
            FolderEntry(rootId: args.rootId, path: dirPath, name: f.name),
          );
        } else if (NexoraFiles.isAudio(f)) {
          final song = NexoraFiles.toSong(
            f,
            streamUrl: await api.rawUrl(args.rootId, f.path),
            artworkUrl: await api.thumbnailUrl(args.rootId, f.path, size: 512),
          );
          songs.add(song);
        }
      }
      return FolderContent(folders: folders, songs: songs);
    });

final folderCoverProvider = FutureProvider.autoDispose.family<String?, String>((
  ref,
  folderId,
) async {
  final api = ref.watch(filesApiProvider);
  final idx = folderId.indexOf('|');
  if (idx <= 0) return null;
  final rootId = folderId.substring(0, idx);
  final path = folderId.substring(idx + 1);
  return api.folderCoverUrl(rootId, path);
});

/// Folder browser — audiophile redesign.
///
/// Large hero artwork, editorial title block, Play/Shuffle actions,
/// folders grid, and tracks list with hairline dividers.
class FolderBrowserScreen extends ConsumerWidget {
  final String rootId;
  final String path;
  const FolderBrowserScreen({super.key, required this.rootId, this.path = ''});

  String get _folderName {
    if (path.isEmpty) return 'Library';
    return path.split('/').where((s) => s.isNotEmpty).last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(
      folderContentProvider((rootId: rootId, path: path)),
    );
    final isDark = AppColors.mode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: contentAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            folderContentProvider((rootId: rootId, path: path)),
          ),
        ),
        data: (content) => CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 64,
              flexibleSpace: const NexoraSliverAppBarBackground(),
              title: Text(
                _folderName,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              actions: [
                if (content.songs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .playSongs(content.songs.cast(), initialIndex: 0),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero artwork
                    AspectRatio(
                      aspectRatio: 1,
                      child: _FolderHero(
                        content: content,
                        rootId: rootId,
                        path: path,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title + count
                    Text(
                      _folderName,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${content.songs.length} ${content.songs.length == 1 ? 'song' : 'songs'}'
                      '${content.folders.isNotEmpty ? ' • ${content.folders.length} folders' : ''}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    // Actions
                    if (content.songs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryAction(
                              icon: Icons.play_arrow_rounded,
                              label: 'Play',
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .playSongs(
                                    content.songs.cast(),
                                    initialIndex: 0,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SecondaryAction(
                              icon: Icons.shuffle_rounded,
                              label: 'Shuffle',
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .playSongs(
                                    [...content.songs]..shuffle(),
                                    initialIndex: 0,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Folders grid
                    if (content.folders.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      NexoraSectionHeader(
                        label: 'Folders',
                        accent: const Color(0xFF2EC4B6),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: content.folders.length,
                        itemBuilder: (c, i) =>
                            _FolderCard(folder: content.folders[i]),
                      ),
                    ],
                    // Tracks
                    if (content.songs.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      NexoraSectionHeader(
                        label: 'Tracks',
                        accent: AppColors.accent,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Songs list
            if (content.songs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: NexoraRadius.card,
                      border: Border.all(color: AppColors.border, width: 0.7),
                      boxShadow: isDark ? null : NexoraShadow.card(false),
                    ),
                    child: ClipRRect(
                      borderRadius: NexoraRadius.card,
                      child: Column(
                        children: [
                          for (var i = 0; i < content.songs.length; i++) ...[
                            _SongRow(
                              index: i + 1,
                              song: content.songs[i],
                              isCurrent:
                                  ref.watch(playerProvider).currentTrack?.id ==
                                  content.songs[i].id,
                              onTap: () => ref
                                  .read(playerProvider.notifier)
                                  .playSongs(
                                    content.songs.cast(),
                                    initialIndex: i,
                                  ),
                              onMoreAt: (anchor) => _showSongMenu(
                                context,
                                ref,
                                content.songs[i],
                                anchor,
                              ),
                            ),
                            if (i != content.songs.length - 1)
                              const NexoraDivider(indent: 64, endIndent: 0),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: NexoraSpacing.dockBottomReserve),
            ),
          ],
        ),
      ),
    );
  }

  void _showSongMenu(
    BuildContext context,
    WidgetRef ref,
    dynamic song,
    Rect anchor,
  ) {
    final s = song as Song;
    showTrackMenuBox(
      context: context,
      anchor: anchor,
      options: [
        TrackMenuOption(
          icon: Icons.play_arrow_rounded,
          label: 'Play next',
          onTap: () => ref.read(playerProvider.notifier).playNext(s),
        ),
        TrackMenuOption(
          icon: Icons.queue_music_rounded,
          label: 'Add to queue',
          onTap: () {
            ref.read(playerProvider.notifier).addToQueue(s);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Added to queue')));
          },
        ),
        TrackMenuOption(
          icon: Icons.playlist_add_rounded,
          label: 'Add to playlist',
          onTap: () => showAddToPlaylistSheet(context, song: s),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PrimaryAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SecondaryAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.text, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderHero extends ConsumerWidget {
  final FolderContent content;
  final String rootId;
  final String path;
  const _FolderHero({
    required this.content,
    required this.rootId,
    required this.path,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderId = '$rootId|$path';
    final coverAsync = ref.watch(folderCoverProvider(folderId));
    final firstSongCover = content.songs.isNotEmpty
        ? content.songs.first.coverUrl as String?
        : null;
    final url = coverAsync.value ?? firstSongCover;
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : NexoraShadow.card(false),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ArtworkImage(url: url, borderRadius: 0, showShadow: false),
      ),
    );
  }
}

class _FolderCard extends ConsumerWidget {
  final FolderEntry folder;
  const _FolderCard({required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(folderCoverProvider(folder.id));
    return GestureDetector(
      onTap: () => context.push(
        '/folder?root=${folder.rootId}&path=${Uri.encodeComponent(folder.path)}',
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
                border: Border.all(color: AppColors.border, width: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ArtworkImage(url: coverAsync.value, borderRadius: 0),
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
                    const Positioned(
                      right: 8,
                      bottom: 8,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            folder.name,
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

class _SongRow extends StatelessWidget {
  final int index;
  final dynamic song;
  final bool isCurrent;
  final VoidCallback onTap;
  final void Function(Rect anchor)? onMoreAt;
  const _SongRow({
    required this.index,
    required this.song,
    required this.isCurrent,
    required this.onTap,
    this.onMoreAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    final titleColor = isCurrent ? AppColors.onSelection : AppColors.text;
    final subtitleColor = isCurrent
        ? AppColors.onSelection.withValues(alpha: 0.82)
        : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isCurrent ? AppColors.selectionGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(
                      alpha: isDark ? 0.38 : 0.26,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Index
                SizedBox(
                  width: 28,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: isCurrent
                          ? AppColors.onSelection.withValues(alpha: 0.90)
                          : AppColors.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                // Artwork
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isCurrent
                        ? Colors.white.withValues(alpha: 0.22)
                        : AppColors.surfaceRaised,
                    image: song.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(song.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: song.coverUrl == null
                      ? Icon(
                          Icons.music_note_rounded,
                          color: isCurrent
                              ? AppColors.onSelection
                              : AppColors.textDim,
                          size: 20,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Title + artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 14.5,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artist ?? song.album ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Codec badge
                if (song.codec != null) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isCurrent
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.transparent,
                      border: Border.all(
                        color: isCurrent
                            ? Colors.white.withValues(alpha: 0.40)
                            : AppColors.accent.withValues(alpha: 0.35),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      song.codec!.toUpperCase(),
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.onSelection
                            : AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                // More button — anchored mini menu when available.
                Builder(
                  builder: (btnContext) => IconButton(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: isCurrent
                          ? AppColors.onSelection.withValues(alpha: 0.90)
                          : AppColors.textDim,
                    ),
                    onPressed: () {
                      final box = btnContext.findRenderObject() as RenderBox?;
                      if (box == null || !box.hasSize || onMoreAt == null) {
                        return;
                      }
                      final pos = box.localToGlobal(Offset.zero);
                      onMoreAt!(
                        Rect.fromLTWH(
                          pos.dx,
                          pos.dy,
                          box.size.width,
                          box.size.height,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
