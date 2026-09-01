import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';

final songsApiProvider = Provider<SongsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return SongsApi(c, s);
});

/// Real Nexora file-server backed songs API.
/// Songs are audio files; the search index (kind=audio) is the library.
class SongsApi {
  final ApiClient _client;
  final SecureStorageService _storage;
  SongsApi(this._client, this._storage);

  static const audioExt =
      'mp3,flac,wav,m4a,aac,ogg,opus,wma,alac,aiff,ape,dsf,wv,mka';

  /// Stream URL for a song: /files/raw?root=&path=&token=
  /// Token as query param bypasses CSRF; the audio player also sends the
  /// Authorization header (see queue_manager). Both are accepted by Nexora.
  Future<String> streamUrl(String songId) async {
    final root = NexoraFiles.parseRootId(songId);
    final path = Uri.encodeComponent(NexoraFiles.parsePath(songId));
    final token = await _storage.getToken() ?? '';
    final base = _client.dio.options.baseUrl;
    return '$base${ApiConstants.filesRaw}?root=$root&path=$path&token=$token';
  }

  /// Artwork (embedded cover fallback chain on the server).
  Future<String> artworkUrl(String songId, {int size = 512}) async {
    final root = NexoraFiles.parseRootId(songId);
    final path = Uri.encodeComponent(NexoraFiles.parsePath(songId));
    final token = await _storage.getToken() ?? '';
    final base = _client.dio.options.baseUrl;
    return '$base${ApiConstants.filesThumbnail}?root=$root&path=$path&size=$size&token=$token';
  }

  /// Download URL for offline.
  Future<String> downloadUrl(String songId) async {
    final root = NexoraFiles.parseRootId(songId);
    final path = Uri.encodeComponent(NexoraFiles.parsePath(songId));
    final token = await _storage.getToken() ?? '';
    final base = _client.dio.options.baseUrl;
    return '$base${ApiConstants.filesDownload}?root=$root&path=$path&token=$token';
  }

  /// Search-index based library listing (kind=audio). Empty query lists all.
  Future<PaginatedSongs> getSongs({
    int offset = 0,
    int limit = 50,
    String query = '',
    String? rootId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get(
      ApiConstants.search,
      query: {
        'q': query,
        'kind': 'audio',
        'offset': offset,
        'limit': limit,
        if (rootId != null) 'root': rootId,
      },
      cancelToken: cancelToken,
    );
    final data = res.data;
    List<dynamic> items = [];
    bool hasMore = false;
    if (data is Map<String, dynamic>) {
      items = (data['items'] as List?) ?? [];
      hasMore = data['has_more'] == true;
    } else if (data is List) {
      items = data;
    }
    final songs = <Song>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final f = FileItemDto.fromJson(raw);
      if (!NexoraFiles.isAudio(f)) continue;
      songs.add(NexoraFiles.toSong(
        f,
        streamUrl: await streamUrl(NexoraFiles.songId(f)),
        artworkUrl: await artworkUrl(NexoraFiles.songId(f), size: 512),
      ));
    }
    return PaginatedSongs(
      songs: songs,
      offset: offset,
      limit: limit,
      hasMore: hasMore,
    );
  }

  /// List a directory (used for album/artist browsing).
  /// Returns (songs with artwork+stream URLs attached, sub-directories).
  Future<(List<Song>, List<({String id, String name})>)> browseDirectory({
    required String rootId,
    String path = '',
    int limit = 500,
  }) async {
    final res = await _client.get(
      ApiConstants.files,
      query: {
        'root': rootId,
        'path': path,
        'limit': limit,
        'offset': 0,
        'dirs_first': 'true',
      },
    );
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? (data['items'] as List?) : null) ?? [];
    final songs = <Song>[];
    final dirs = <({String id, String name})>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final f = FileItemDto.fromJson(raw);
      if (f.isDir) {
        final dirPath = f.path.isEmpty ? f.name : f.path;
        dirs.add((id: '$rootId|$dirPath', name: f.name));
      } else if (NexoraFiles.isAudio(f)) {
        songs.add(NexoraFiles.toSong(
          f,
          streamUrl: await streamUrl(NexoraFiles.songId(f)),
          artworkUrl: await artworkUrl(NexoraFiles.songId(f), size: 512),
        ));
      }
    }
    return (songs, dirs);
  }

  /// Resolve the best "music" root id (icon/name heuristic, else first root).
  Future<String?> musicRootId() async {
    try {
      final res = await _client.get(ApiConstants.roots);
      final data = res.data;
      final roots =
          (data is Map<String, dynamic> ? data['roots'] as List? : null) ?? [];
      String? music;
      String? first;
      for (final raw in roots) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['enabled'] == false) continue;
        final id = (raw['id'] ?? '').toString();
        final name = (raw['name'] ?? '').toString().toLowerCase();
        final icon = (raw['icon'] ?? '').toString().toLowerCase();
        first ??= id;
        if (icon == 'music' ||
            name.contains('music') ||
            name.contains('songs')) {
          music = id;
          break;
        }
      }
      return music ?? first;
    } catch (_) {
      return null;
    }
  }

  /// ffprobe-backed audio metadata (codec, bitrate, sample rate, duration).
  Future<Map<String, dynamic>?> getAudioInfo(String songId) async {
    try {
      final root = NexoraFiles.parseRootId(songId);
      final path = NexoraFiles.parsePath(songId);
      final res = await _client.get(
        ApiConstants.audioInfo,
        query: {'root': root, 'path': path},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}
    return null;
  }
}

class PaginatedSongs {
  final List<Song> songs;
  final int offset;
  final int limit;
  final bool hasMore;
  PaginatedSongs({
    required this.songs,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });
}
