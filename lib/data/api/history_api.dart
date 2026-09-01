import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/playback_history.dart';
import '../dto/file_dto.dart';

final historyApiProvider = Provider<HistoryApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return HistoryApi(c);
});

/// Real Nexora history = /recents (server records an access whenever a file
/// is streamed via /files/raw without a Range header).
/// GET /recents?limit= -> {items:[{root_id,root_name,path,name,accessed_at}]}
class HistoryApi {
  final ApiClient _client;
  HistoryApi(this._client);

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
    final out = <PlaybackHistoryItem>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final rootId = (raw['root_id'] ?? '').toString();
      final path = (raw['path'] ?? '').toString();
      final name = (raw['name'] ?? '').toString();
      if (rootId.isEmpty || path.isEmpty) continue;
      DateTime playedAt;
      try {
        playedAt = DateTime.parse((raw['accessed_at'] ?? '').toString());
      } catch (_) {
        playedAt = DateTime.now();
      }
      final f = FileItemDto(
        name: name,
        path: path,
        size: 0,
        isDir: false,
        modified: '',
        mime: '',
        rootId: rootId,
        extension: name.contains('.') ? name.split('.').last : '',
      );
      out.add(
        PlaybackHistoryItem(
          songId: NexoraFiles.songId(f),
          song: NexoraFiles.toSong(f),
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
