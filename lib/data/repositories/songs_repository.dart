import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
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
      if (result.songs.isNotEmpty) {
        try {
          await _local.cacheSongs(result.songs);
        } catch (_) {}
      }
      return Paginated(
        data: result.songs,
        page: page,
        limit: limit,
        total: result.hasMore
            ? page * limit + 1
            : (page - 1) * limit + result.songs.length,
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
          data: cached,
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
  }) => _api.browseDirectory(rootId: rootId, path: path);
}
