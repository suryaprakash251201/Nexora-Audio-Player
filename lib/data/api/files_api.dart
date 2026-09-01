import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../dto/file_dto.dart';

final filesApiProvider = Provider<FilesApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return FilesApi(c, s);
});

/// Browsing of the real Nexora file server.
///
/// Artwork strategy (verified against the live server):
/// - `GET /files/thumbnail?root=&path=&size=&token=` returns a JPEG for any
///   audio file: embedded cover first, then a cover image stored next to the
///   file (folder cover). The `?token=` query fully authenticates the request
///   (verified: 200 image/jpeg with token only, no headers needed), so plain
///   `Image.network` and `MediaItem.artUri` both work without headers.
/// - Thumbnail on a directory path returns 415, so a folder card uses the
///   thumbnail of the first audio file found inside that folder.
class FilesApi {
  final ApiClient _client;
  final SecureStorageService _storage;
  FilesApi(this._client, this._storage);

  String _base() => _client.dio.options.baseUrl;

  Future<String> _token() async {
    final t = await _storage.getToken();
    return t ?? '';
  }

  /// Thumbnail URL for any audio file path. Works for plain Image.network
  /// because the `?token=` query authenticates the request.
  Future<String> thumbnailUrl(
    String rootId,
    String path, {
    int size = 512,
  }) async {
    final token = await _token();
    return '${_base()}${ApiConstants.filesThumbnail}'
        '?root=$rootId&path=${Uri.encodeComponent(path)}'
        '&size=$size&token=$token';
  }

  /// Stream URL for an audio file path (works with plain URL, token in query).
  Future<String> rawUrl(String rootId, String path) async {
    final token = await _token();
    return '${_base()}${ApiConstants.filesRaw}'
        '?root=$rootId&path=${Uri.encodeComponent(path)}'
        '&token=$token';
  }

  /// List a directory. Returns raw file items (both dirs and files).
  Future<List<FileItemDto>> list(
    String rootId,
    String path, {
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
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FileItemDto.fromJson)
        .toList(growable: false);
  }

  /// First audio file (if any) directly inside a folder — used for covers.
  Future<FileItemDto?> firstAudioFile(String rootId, String path) async {
    try {
      final items = await list(rootId, path, limit: 100);
      for (final f in items) {
        if (NexoraFiles.isAudio(f)) return f;
      }
    } catch (_) {}
    return null;
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
}
