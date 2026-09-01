import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/files_api.dart';
import '../../../data/dto/file_dto.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../player/providers/player_provider.dart';

/// A folder in the Nexora Music root, with a lazily resolved cover.
class FolderEntry {
  final String rootId;
  final String path; // relative path inside the root
  final String name;

  FolderEntry({required this.rootId, required this.path, required this.name});

  String get id => '$rootId|$path';

  /// Cover = a cover.jpeg/cover.png in the folder if present, otherwise the
  /// thumbnail of the first audio file inside the folder.
  Future<String?> coverUrl(FilesApi api) async {
    return api.folderCoverUrl(rootId, path);
  }
}

class FolderContent {
  final List<FolderEntry> folders;
  final List<dynamic> songs; // Song entities with stream+artwork attached
  FolderContent({required this.folders, required this.songs});
}

/// Breadcrumb path segments for display.
List<(String, String)> breadcrumbSegments(String path) {
  final segs = path.split('/').where((s) => s.isNotEmpty).toList();
  final out = <(String, String)>[]; // (label, path)
  out.add(('Music', ''));
  var acc = '';
  for (final s in segs) {
    acc = acc.isEmpty ? s : '$acc/$s';
    out.add((s, acc));
  }
  return out;
}

/// Loads a folder: sub-folders + audio songs (with stream + artwork attached).
final folderContentProvider = FutureProvider.autoDispose
    .family<FolderContent, ({String rootId, String path})>((ref, args) async {
      final api = ref.watch(filesApiProvider);
      final items = await api.list(args.rootId, args.path, limit: 500);

      final folders = <FolderEntry>[];
      final songs = <dynamic>[];
      String? firstAudioPath;

      for (final f in items) {
        if (f.isDir) {
          final dirPath = f.path.isEmpty ? f.name : f.path;
          folders.add(
            FolderEntry(rootId: args.rootId, path: dirPath, name: f.name),
          );
        } else if (NexoraFiles.isAudio(f)) {
          firstAudioPath ??= f.path;
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

/// Lazily resolves a folder cover (cover.jpeg/cover.png, else first audio
/// file's thumbnail).
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

/// Apple Music style folder browser: breadcrumb, folder grid with covers,
/// song list with covers, and a Play All action.
class FolderBrowserScreen extends ConsumerWidget {
  final String rootId;
  final String path;
  const FolderBrowserScreen({super.key, required this.rootId, this.path = ''});

  String get _folderName {
    if (path.isEmpty) return 'Music';
    return path.split('/').where((s) => s.isNotEmpty).last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(
      folderContentProvider((rootId: rootId, path: path)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_folderName),
        backgroundColor: Colors.transparent,
        actions: [
          contentAsync.maybeWhen(
            data: (c) => c.songs.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
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
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    tooltip: 'Play all',
                    onPressed: () => ref
                        .read(playerProvider.notifier)
                        .playSongs(c.songs.cast(), initialIndex: 0),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: contentAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            folderContentProvider((rootId: rootId, path: path)),
          ),
        ),
        data: (content) {
          final crumbs = breadcrumbSegments(path);
          return ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              if (crumbs.length > 1) ...[
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: crumbs.length,
                    separatorBuilder: (_, __) => Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textDim,
                    ),
                    itemBuilder: (c, i) {
                      final (label, p) = crumbs[i];
                      final isLast = i == crumbs.length - 1;
                      return Center(
                        child: InkWell(
                          onTap: isLast
                              ? null
                              : () => context.push(
                                  '/folder?root=$rootId&path=${Uri.encodeComponent(p)}',
                                ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isLast
                                  ? AppColors.text
                                  : AppColors.primary,
                              fontSize: 13,
                              fontWeight: isLast
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (content.folders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    'Folders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: content.folders.length,
                  itemBuilder: (c, i) =>
                      _FolderCard(folder: content.folders[i]),
                ),
              ],
              if (content.songs.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                  child: Text(
                    'Songs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...content.songs.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final isCurrent =
                      ref.watch(playerProvider).currentTrack?.id == s.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    leading: isCurrent
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ArtworkImage(
                                url: s.coverUrl,
                                size: 48,
                                borderRadius: 10,
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: NowPlayingIndicator(
                                    height: 14,
                                    width: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ArtworkImage(
                            url: s.coverUrl,
                            size: 48,
                            borderRadius: 10,
                          ),
                    title: Text(
                      s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.primaryLight
                            : AppColors.text,
                        fontSize: 15,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      s.artist ?? s.album ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.codec != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
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
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () =>
                              _showSongMenu(context, ref, s, content.songs, i),
                        ),
                      ],
                    ),
                    onTap: () => ref
                        .read(playerProvider.notifier)
                        .playSongs(content.songs.cast(), initialIndex: i),
                  );
                }),
              ],
              if (content.folders.isEmpty && content.songs.isEmpty)
                const EmptyView(
                  title: 'Empty folder',
                  subtitle: 'No songs or sub-folders here',
                  icon: Icons.folder_open,
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSongMenu(
    BuildContext context,
    WidgetRef ref,
    dynamic song,
    List<dynamic> allSongs,
    int index,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow, color: AppColors.text),
              title: Text('Play next', style: TextStyle(color: AppColors.text)),
              onTap: () {
                Navigator.pop(c);
                ref.read(playerProvider.notifier).playNext(song);
              },
            ),
            ListTile(
              leading: Icon(Icons.queue_music, color: AppColors.text),
              title: Text(
                'Add to queue',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pop(c);
                ref.read(playerProvider.notifier).addToQueue(song);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Added to queue')));
              },
            ),
          ],
        ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(
        '/folder?root=${folder.rootId}&path=${Uri.encodeComponent(folder.path)}',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: coverAsync.when(
              data: (url) => ArtworkImage(url: url, borderRadius: 16),
              loading: () => ArtworkImage(url: null, borderRadius: 16),
              error: (_, __) => ArtworkImage(url: null, borderRadius: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
