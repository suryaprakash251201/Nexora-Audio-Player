import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../core/logging/app_logger.dart';
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

  Future<Paginated<Song>> getSongs({int page = 1, int limit = 20, String? query, CancelToken? cancelToken}) async {
    try {
      final remote = await _api.getSongs(page: page, limit: limit, query: query, cancelToken: cancelToken);
      // Cache first page
      if (remote.data.isNotEmpty) {
        try {
          await _local.cacheSongs(remote.data);
        } catch (e) {
          AppLogger.cache('cacheSongs failed: $e');
        }
      }
      return remote;
    } on NoInternetException {
      // Offline fallback
      final cached = await _local.getCachedSongs(limit: limit, offset: (page - 1) * limit);
      if (cached.isNotEmpty) {
        return Paginated(data: cached, page: page, limit: limit, total: cached.length, totalPages: 1, hasNext: false, hasPrev: page > 1);
      }
      rethrow;
    } on ApiException {
      rethrow;
    } catch (e) {
      // Fallback to cache for any network error
      try {
        final cached = await _local.getCachedSongs(limit: limit, offset: (page - 1) * limit);
        if (cached.isNotEmpty) return Paginated(data: cached, page: page, limit: limit, total: cached.length, totalPages: 1, hasNext: false, hasPrev: page > 1);
      } catch (_) {}
      rethrow;
    }
  }

  Future<Song> getSong(String id) async {
    try {
      final song = await _api.getSong(id);
      await _local.cacheSongs([song]);
      return song;
    } catch (e) {
      final cached = await _local.getSong(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  String streamUrl(String id) => _api.streamUrl(id);
  String artworkUrl(String id) => _api.artworkUrl(id);
}
