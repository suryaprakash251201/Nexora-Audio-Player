import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/album.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';
import 'songs_api.dart';

final albumsApiProvider = Provider<AlbumsApi>((ref) {
  final songsApi = ref.watch(songsApiProvider);
  return AlbumsApi(songsApi);
});

/// Albums are directories in the Music root on the real Nexora file server.
class AlbumsApi {
  final SongsApi _songs;
  AlbumsApi(this._songs);

  Future<List<Album>> getAlbums({
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final rootId = await _songs.musicRootId();
    if (rootId == null) return [];
    final (_, dirs) = await _songs.browseDirectory(
      rootId: rootId,
      limit: limit,
    );
    return dirs
        .map(
          (d) => Album(
            id: d.id,
            title: d.name,
            artist: null,
            coverUrl: null,
            trackCount: null,
          ),
        )
        .toList();
  }

  Future<Album> getAlbum(String albumId) async {
    final path = NexoraFiles.parsePath(albumId);
    final name = path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path;
    return Album(id: albumId, title: name, artist: null);
  }

  /// Audio files inside an album directory (recursive=False like the server).
  Future<List<Song>> getAlbumTracks(
    String albumId, {
    CancelToken? cancelToken,
  }) async {
    final root = NexoraFiles.parseRootId(albumId);
    final path = NexoraFiles.parsePath(albumId);
    final (songs, subDirs) = await _songs.browseDirectory(
      rootId: root,
      path: path,
    );
    // If this dir has no audio but has sub-dirs, pull first-level of each (best effort, capped).
    if (songs.isEmpty && subDirs.isNotEmpty) {
      for (final d in subDirs.take(20)) {
        final p = NexoraFiles.parsePath(d.id);
        final (s2, _) = await _songs.browseDirectory(rootId: root, path: p);
        songs.addAll(s2);
        if (songs.length > 200) break;
      }
    }
    return songs;
  }
}
