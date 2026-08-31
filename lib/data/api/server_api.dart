import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/server_info.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

final serverApiProvider = Provider<ServerApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ServerApi(client);
});

class ServerApi {
  final ApiClient _client;
  ServerApi(this._client);

  Future<ServerInfo> getServerInfo() async {
    // Try Nexora file-server endpoints first
    final candidates = [
      '/version',
      '/healthz',
      ApiConstants.serverInfo,
      '/server/info',
      '/api/v1/version',
    ];
    for (final ep in candidates) {
      try {
        final res = await _client.dio.get(ep);
        final data = res.data;
        if (data is Map<String, dynamic>) {
          // Nexora file server returns {"service":"nexora","status":"ok","version":"1.8.0"}
          if (data.containsKey('service') && data.containsKey('version')) {
            return ServerInfo(
              serverVersion: (data['version'] ?? 'unknown').toString(),
              apiVersion: 'v1',
              name: (data['service'] ?? 'Nexora').toString(),
              features: const ServerFeatures(),
            );
          }
          final payload = data['data'] is Map
              ? data['data'] as Map<String, dynamic>
              : data;
          if (payload.containsKey('serverVersion') ||
              payload.containsKey('version') ||
              payload.containsKey('name')) {
            return ServerInfo.fromJson(payload);
          }
        }
        if (res.statusCode != null && res.statusCode! < 500) {
          return ServerInfo.fallback();
        }
      } catch (_) {
        continue;
      }
    }
    // Fallback to original
    try {
      final res = await _client.get(ApiConstants.serverInfo);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] is Map
            ? data['data'] as Map<String, dynamic>
            : data;
        return ServerInfo.fromJson(payload);
      }
      return ServerInfo.fallback();
    } catch (_) {
      return ServerInfo.fallback();
    }
  }

  Future<bool> checkHealth() async {
    // Use the robust testConnection which already handles Nexora endpoints
    try {
      final dio = _client.dio;
      final base = dio.options.baseUrl;
      if (base.isNotEmpty) {
        // Try healthz directly via dio base
        final r = await dio.get('/healthz');
        if (r.statusCode != null && r.statusCode! < 500) return true;
      }
    } catch (_) {}
    try {
      final res = await _client.dio.get('/healthz');
      return res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      try {
        final r2 = await _client.get(ApiConstants.serverInfo);
        return r2.statusCode != null && r2.statusCode! < 500;
      } catch (_) {
        try {
          final r3 = await _client.dio.get('/version');
          return r3.statusCode != null && r3.statusCode! < 500;
        } catch (_) {
          return false;
        }
      }
    }
  }
}
