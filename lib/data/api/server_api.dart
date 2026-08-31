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
    try {
      final res = await _client.get(ApiConstants.serverInfo);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'] is Map ? data['data'] as Map<String, dynamic> : data;
        return ServerInfo.fromJson(payload);
      }
      return ServerInfo.fallback();
    } catch (_) {
      return ServerInfo.fallback();
    }
  }

  Future<bool> checkHealth() async {
    try {
      final res = await _client.dio.get('/health');
      return res.statusCode != null && res.statusCode! < 500;
    } catch (_) {
      try {
        final r2 = await _client.get(ApiConstants.serverInfo);
        return r2.statusCode != null && r2.statusCode! < 500;
      } catch (_) {
        return false;
      }
    }
  }
}
