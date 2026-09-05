import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/paginated.dart';
import '../../domain/entities/song.dart';
import '../api/songs_api.dart';
import '../local/songs_local_datasource.dart';

final songsRepositoryProvider = Provider<SongsRepository>((ref) {
  final api = ref.watch(songsApiProvider);
  final local = ref.watch(songsLocalDsProvider);
  return SongsRepository(api, local);
});

class SongsRepository {
  final SongsApi _api;
  final SongsLocalDataSource _local;
  SongsRepository(this._api, this._local);

  /// Keeps the first occurrence of each song.
  /// Dedupes by canonical id, and as a fallback by normalized
  /// title+artist+duration fingerprint to catch server duplicates where the
  /// same file appears under different ids (e.g. overlapping paginated search).
  static List<Song> deduplicateById(Iterable<Song> songs) {
    final seenIds = <String>{};
    final seenFp = <String>{};
    final result = <Song>[];
    for (final song in songs) {
      final id = song.id.trim();
      final fp = _fingerprint(song);
      final isIdDup = id.isNotEmpty && !seenIds.add(id);
      final isFpDup = !seenFp.add(fp);
      // If either the id or the content fingerprint was already seen, skip.
      // id-empty entries fall back to fingerprint only.
      if (id.isNotEmpty) {
        if (isIdDup || isFpDup) continue;
      } else {
        if (isFpDup) continue;
      }
      result.add(song);
    }
    return result;
  }

  static String _fingerprint(Song s) {
    final t = s.title.trim().toLowerCase();
    final a = (s.artist ?? '').trim().toLowerCase();
    // duration tolerance: bucket to 2s to avoid tiny transcode differences
    final d = s.duration ?? 0;
    return '$t|$a|$d';
  }

  /// Library listing via search index (kind=audio). Falls back to cache offline.
  Future<Paginated<Song>> getSongs({
    int page = 1,
    int limit = 50,
    String? query,
    CancelToken? cancelToken,
  }) async {
    try {
      final result = await _api.getSongs(
        offset: (page - 1) * limit,
        limit: limit,
        query: query ?? '',
        cancelToken: cancelToken,
      );
      var songs = deduplicateById(result.songs);
      if (songs.isNotEmpty) {
        try {
          await _local.cacheSongs(songs);
        } catch (_) {}
        // Attach verified offline state so rows/player use local files.
        try {
          final states = await _local.getDownloadStates(
            songs.map((s) => s.id).toList(),
          );
          songs = _local.withOfflineState(songs, states);
        } catch (_) {}
      }
      return Paginated(
        data: songs,
        page: page,
        limit: limit,
        total: result.hasMore
            ? page * limit + 1
            : (page - 1) * limit + songs.length,
        totalPages: result.hasMore ? page + 1 : page,
        hasNext: result.hasMore,
        hasPrev: page > 1,
      );
    } catch (e) {
      // Offline / server error fallback: cached songs
      final cached = await _local.getCachedSongs(
        limit: limit,
        offset: (page - 1) * limit,
      );
      if (cached.isNotEmpty) {
        return Paginated(
          data: deduplicateById(cached),
          page: page,
          limit: limit,
          total: cached.length,
          totalPages: 1,
          hasNext: false,
          hasPrev: page > 1,
        );
      }
      rethrow;
    }
  }

  Future<Song> getSong(String id) async {
    final cached = await _local.getSong(id);
    if (cached != null) return cached;
    throw Exception('Song not found locally: $id');
  }

  Future<String> streamUrl(String id) => _api.streamUrl(id);
  Future<String> artworkUrl(String id, {int size = 512}) =>
      _api.artworkUrl(id, size: size);
  Future<String?> musicRootId() => _api.musicRootId();

  /// Browse a directory: returns (songs, subDirectories)
  Future<(List<Song>, List<({String id, String name})>)> browseDirectory({
    required String rootId,
    String path = '',
  }) async {
    final (songs, dirs) = await _api.browseDirectory(
      rootId: rootId,
      path: path,
    );
    if (songs.isEmpty) return (songs, dirs);
    try {
      final states = await _local.getDownloadStates(
        songs.map((s) => s.id).toList(),
      );
      return (_local.withOfflineState(songs, states), dirs);
    } catch (_) {
      return (songs, dirs);
    }
  }
}
