import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';
import 'songs_api.dart';

final artistsApiProvider = Provider<ArtistsApi>((ref) {
  final songsApi = ref.watch(songsApiProvider);
  return ArtistsApi(songsApi);
});

/// Artists are directory-based on the file server. Heuristic:
/// prefer a root sub-directory named "Artists"; otherwise treat top-level
/// music folders as artist groupings (same v1 behavior as Albums).
class ArtistsApi {
  final SongsApi _songs;
  ArtistsApi(this._songs);

  Future<List<Artist>> getArtists({
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final rootId = await _songs.musicRootId();
    if (rootId == null) return [];
    final (_, dirs) = await _songs.browseDirectory(
      rootId: rootId,
      limit: limit,
    );
    final artistsDir = dirs
        .where((d) => d.name.toLowerCase() == 'artists')
        .toList();
    final source = artistsDir.isNotEmpty ? artistsDir : dirs;
    return source.map((d) => Artist(id: d.id, name: d.name)).toList();
  }

  Future<Artist> getArtist(String artistId) async {
    final path = NexoraFiles.parsePath(artistId);
    final name = path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path;
    return Artist(id: artistId, name: name);
  }

  Future<List<Song>> getArtistSongs(String artistId, {int limit = 200}) async {
    final root = NexoraFiles.parseRootId(artistId);
    final path = NexoraFiles.parsePath(artistId);
    final (songs, subDirs) = await _songs.browseDirectory(
      rootId: root,
      path: path,
    );
    if (songs.isEmpty && subDirs.isNotEmpty) {
      for (final d in subDirs.take(20)) {
        final p = NexoraFiles.parsePath(d.id);
        final (s2, _) = await _songs.browseDirectory(rootId: root, path: p);
        songs.addAll(s2);
        if (songs.length > limit) break;
      }
    }
    return songs;
  }
}
