import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';

/// A single timed lyric cue.
class LyricCue {
  final double time; // seconds; -1 for unsynced
  final String text;

  const LyricCue({required this.time, required this.text});

  factory LyricCue.fromJson(Map<String, dynamic> j) => LyricCue(
    time: (j['time'] as num?)?.toDouble() ?? -1,
    text: (j['text'] as String? ?? '').toString(),
  );

  bool get isSynced => time >= 0;
}

/// Parsed lyrics response from /audio/lyrics.
class LyricsData {
  final bool hasLyrics;
  final String raw;
  final String format; // lrc | plain
  final String source; // auto | user | ""
  final bool synced;
  final List<LyricCue> cues;

  LyricsData({
    required this.hasLyrics,
    required this.raw,
    required this.format,
    required this.source,
    required this.synced,
    required this.cues,
  });

  factory LyricsData.fromJson(Map<String, dynamic> j) => LyricsData(
    hasLyrics: j['has_lyrics'] as bool? ?? false,
    raw: (j['raw'] as String? ?? '').toString(),
    format: (j['format'] as String? ?? 'plain').toString(),
    source: (j['source'] as String? ?? '').toString(),
    synced: j['synced'] as bool? ?? false,
    cues: ((j['cues'] as List?) ?? [])
        .map((c) => LyricCue.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}

class LyricsApi {
  final ApiClient _client;
  final SecureStorageService _storage;
  LyricsApi(this._client, this._storage);

  Future<String> _base() async {
    final url = await _storage.getServerUrl();
    if (url == null || url.isEmpty) {
      throw Exception('Server URL not configured');
    }
    return url;
  }

  Future<LyricsData> getLyrics(String rootId, String path) async {
    final base = await _base();
    final res = await _client.get(
      '${base}${ApiConstants.audioLyrics}',
      query: {'root': rootId, 'path': path},
    );
    return LyricsData.fromJson(res.data as Map<String, dynamic>);
  }
}

final lyricsApiProvider = Provider<LyricsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return LyricsApi(c, s);
});

/// Provider keyed by (rootId, path).
final lyricsProvider =
    FutureProvider.family<LyricsData, ({String rootId, String path})>((
      ref,
      key,
    ) async {
      try {
        final api = ref.watch(lyricsApiProvider);
        return await api.getLyrics(key.rootId, key.path);
      } catch (_) {
        return LyricsData(
          hasLyrics: false,
          raw: '',
          format: 'plain',
          source: '',
          synced: false,
          cues: [],
        );
      }
    });
