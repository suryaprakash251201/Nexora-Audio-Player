import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage);
});

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _secureStorage;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final serverUrl = await _secureStorage.getServerUrl();
          if (serverUrl != null && options.baseUrl.isEmpty) {
            // Normalize URL (default to http if IP address)
            options.baseUrl = _normalizeUrl(serverUrl);
          }

          final token = await _secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Handle token expiration/unauthorized
            await _secureStorage.deleteToken();
            // TODO: Trigger global logout flow
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get client => _dio;

  String _normalizeUrl(String url) {
    String normalized = url.trim();
    if (!normalized.startsWith('http://') &&
        !normalized.startsWith('https://')) {
      // If it looks like a local IP, default to http://
      final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}');
      if (ipRegex.hasMatch(normalized) || normalized.startsWith('localhost')) {
        normalized = 'http://$normalized';
      } else {
        normalized = 'https://$normalized';
      }
    }
    // ensure trailing slash is removed
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
