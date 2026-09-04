import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/playback_history.dart';
import '../dto/file_dto.dart';

final historyApiProvider = Provider<HistoryApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return HistoryApi(c, s);
});

/// Real Nexora history = /recents (server records an access whenever a file
/// is streamed via /files/raw without a Range header).
/// GET /recents?limit= -> {items:[{root_id,root_name,path,name,accessed_at}]}
class HistoryApi {
  final ApiClient _client;
  final SecureStorageService _storage;
  HistoryApi(this._client, this._storage);

  /// Resolves the API base URL from secure storage (mirrors SongsApi).
  Future<String> _resolvedBaseUrl() async {
    final serverUrl = await _storage.getServerUrl();
    if (serverUrl != null && serverUrl.isNotEmpty) return serverUrl;
    return _client.dio.options.baseUrl;
  }

  /// Stream URL so a history entry is actually playable.
  Future<String> _streamUrl(String rootId, String path, String token) async {
    final t = Uri.encodeComponent(token);
    final base = await _resolvedBaseUrl();
    return '$base${ApiConstants.filesRaw}'
        '?root=${Uri.encodeComponent(rootId)}'
        '&path=${Uri.encodeComponent(path)}&token=$t';
  }

  /// Artwork URL so history cards show real cover art.
  Future<String> _artworkUrl(
    String rootId,
    String path,
    String token, {
    int size = 512,
  }) async {
    final t = Uri.encodeComponent(token);
    final base = await _resolvedBaseUrl();
    return '$base${ApiConstants.filesThumbnail}'
        '?root=${Uri.encodeComponent(rootId)}'
        '&path=${Uri.encodeComponent(path)}&size=$size&token=$t';
  }

  Future<List<PlaybackHistoryItem>> getHistory({
    int page = 1,
    int limit = 30,
  }) async {
    final res = await _client.get(
      ApiConstants.recents,
      query: {'limit': limit},
    );
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    // One token read for the whole page — not per history entry.
    final token = await _storage.getToken() ?? '';
    final out = <PlaybackHistoryItem>[];
    final seen = <String>{};
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final rootId = (raw['root_id'] ?? '').toString();
      final path = (raw['path'] ?? '').toString();
      final name = (raw['name'] ?? '').toString();
      if (rootId.isEmpty || path.isEmpty) continue;
      final extension = name.contains('.') ? name.split('.').last : '';
      // /recents can repeat the same file; keep only the most recent entry.
      final id = '$rootId|$path';
      if (!seen.add(id)) continue;
      DateTime playedAt;
      try {
        playedAt = DateTime.parse((raw['accessed_at'] ?? '').toString());
      } catch (_) {
        playedAt = DateTime.now();
      }
      final f = FileItemDto(
        name: name,
        path: path,
        size: (raw['size'] is int)
            ? raw['size'] as int
            : int.tryParse((raw['size'] ?? '0').toString()) ?? 0,
        isDir: false,
        modified: '',
        mime: '',
        rootId: rootId,
        extension: extension,
      );
      // /recents logs every streamed file (video, docs…) — the music
      // app only ever shows playable audio with real cover art.
      if (!NexoraFiles.isAudio(f)) continue;
      out.add(
        PlaybackHistoryItem(
          songId: NexoraFiles.songId(f),
          song: NexoraFiles.toSong(
            f,
            streamUrl: await _streamUrl(rootId, path, token),
            artworkUrl: await _artworkUrl(rootId, path, token),
          ),
          playedAt: playedAt,
        ),
      );
    }
    return out;
  }

  /// Streaming a track records recents server-side; no dedicated POST needed.
  /// Kept as a no-op-ish best-effort for alternate backends.
  Future<void> recordPlay(
    String songId, {
    int? duration,
    bool completed = false,
  }) async {
    // Server records access automatically on /files/raw; nothing to POST.
  }
}
