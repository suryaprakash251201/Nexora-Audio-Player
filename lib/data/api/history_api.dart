import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/playback_history.dart';
import '../dto/song_dto.dart';

final historyApiProvider = Provider<HistoryApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return HistoryApi(c);
});

class HistoryApi {
  final ApiClient _client;
  HistoryApi(this._client);

  Future<List<PlaybackHistoryItem>> getHistory({int page = 1, int limit = 20}) async {
    final res = await _client.get(ApiConstants.history, query: {'page': page, 'limit': limit});
    final data = res.data;
    List<dynamic> list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) list = data['data'] as List;
      else if (data['history'] is List) list = data['history'] as List;
      else if (data['items'] is List) list = data['items'] as List;
      else list = [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    return list.whereType<Map<String, dynamic>>().map((e) {
      final songJson = e['song'] is Map ? e['song'] as Map<String, dynamic> : e;
      final song = e['song'] != null ? SongDto.fromJson(songJson).toEntity() : null;
      final id = (e['songId'] ?? e['song_id'] ?? song?.id ?? '').toString();
      DateTime playedAt;
      try {
        final raw = e['playedAt'] ?? e['played_at'] ?? e['createdAt'];
        playedAt = raw is int ? DateTime.fromMillisecondsSinceEpoch(raw) : DateTime.parse(raw.toString());
      } catch (_) {
        playedAt = DateTime.now();
      }
      return PlaybackHistoryItem(
        songId: id,
        song: song,
        playedAt: playedAt,
        playDuration: e['playDuration'] is int ? e['playDuration'] as int : int.tryParse((e['playDuration'] ?? '').toString()),
        completion: (e['completion'] as num?)?.toDouble(),
      );
    }).toList();
  }

  Future<void> recordPlay({required String songId, DateTime? playedAt, int? duration, bool completed = false}) async {
    await _client.post(ApiConstants.history, data: {
      'songId': songId,
      'playedAt': (playedAt ?? DateTime.now()).toIso8601String(),
      if (duration != null) 'duration': duration,
      'completed': completed,
    });
  }

  Future<void> clearHistory() async {
    await _client.delete(ApiConstants.history);
  }
}
