import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';

final serverStatsApiProvider = Provider<ServerStatsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return ServerStatsApi(c, s);
});

/// Server-side library stats (`GET /stats?root=`) + quota
/// (`GET /home/usage`). Null-tolerant: any failure means "hide the card".
class ServerLibraryStats {
  final int totalFiles;
  final int totalSize;
  final int audioCount;
  final int audioSize;
  final int quotaTotal;
  final int quotaUsed;

  const ServerLibraryStats({
    this.totalFiles = 0,
    this.totalSize = 0,
    this.audioCount = 0,
    this.audioSize = 0,
    this.quotaTotal = 0,
    this.quotaUsed = 0,
  });

  bool get isEmpty => totalFiles == 0 && audioCount == 0;

  double get quotaFraction {
    if (quotaTotal <= 0) return 0;
    return (quotaUsed / quotaTotal).clamp(0.0, 1.0);
  }
}

class ServerStatsApi {
  final ApiClient _client;
  final SecureStorageService _storage;
  ServerStatsApi(this._client, this._storage);

  Future<String> _base() async {
    final url = await _storage.getServerUrl();
    if (url == null || url.isEmpty) throw Exception('no server');
    return url;
  }

  static int _i(dynamic v) =>
      v is int ? v : int.tryParse((v ?? '0').toString()) ?? 0;

  Future<ServerLibraryStats?> getLibraryStats() async {
    try {
      final base = await _base();
      final rootId = await ServerStatsApi._musicRoot(_client);
      if (rootId == null) return null;
      final res = await _client.get('${base}/stats', query: {'root': rootId});
      final data = res.data;
      if (data is! Map<String, dynamic>) return null;
      final breakdown = data['breakdown'];
      var audioCount = 0;
      var audioSize = 0;
      if (breakdown is Map) {
        final audio = breakdown['audio'];
        if (audio is Map) {
          audioCount = _i(audio['count']);
          audioSize = _i(audio['size']);
        }
      }
      var quotaTotal = 0;
      var quotaUsed = 0;
      try {
        final usage = await _client.get('${base}/home/usage');
        final u = usage.data;
        if (u is Map<String, dynamic>) {
          quotaTotal = _i(u['total']);
          quotaUsed = _i(u['used']);
        }
      } catch (_) {}
      return ServerLibraryStats(
        totalFiles: _i(data['total_files']),
        totalSize: _i(data['total_size']),
        audioCount: audioCount,
        audioSize: audioSize,
        quotaTotal: quotaTotal,
        quotaUsed: quotaUsed,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _musicRoot(ApiClient client) async {
    try {
      final res = await client.get('/roots');
      final data = res.data;
      final roots =
          (data is Map<String, dynamic> ? data['roots'] as List? : null) ?? [];
      String? first;
      for (final raw in roots) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['enabled'] == false) continue;
        final id = (raw['id'] ?? '').toString();
        if (id.isEmpty) continue;
        first ??= id;
        final name = (raw['name'] ?? '').toString().toLowerCase();
        final icon = (raw['icon'] ?? '').toString().toLowerCase();
        if (icon == 'music' ||
            name.contains('music') ||
            name.contains('songs')) {
          return id;
        }
      }
      return first;
    } catch (_) {
      return null;
    }
  }
}

/// Server library numbers for the stats screen. Null (or empty) hides the
/// card — local listening stats always render regardless.
final serverLibraryStatsProvider = FutureProvider<ServerLibraryStats?>((
  ref,
) async {
  final api = ref.watch(serverStatsApiProvider);
  return api.getLibraryStats();
});
