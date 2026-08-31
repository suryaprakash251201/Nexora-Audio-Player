import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Tokens
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async => _storage.read(key: AppConstants.tokenKey);

  Future<void> deleteToken() async => _storage.delete(key: AppConstants.tokenKey);

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async => _storage.read(key: AppConstants.refreshTokenKey);

  Future<void> saveUserJson(String json) async {
    await _storage.write(key: AppConstants.userKey, value: json);
  }

  Future<String?> getUserJson() async => _storage.read(key: AppConstants.userKey);

  // Server URL - normalized
  Future<void> saveServerUrl(String url) async {
    final normalized = AppConfig.normalizeUrl(url);
    await _storage.write(key: AppConstants.serverUrlKey, value: normalized);
  }

  /// Raw stored value (already normalized) or null.
  Future<String?> getServerUrl() async {
    final stored = await _storage.read(key: AppConstants.serverUrlKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final env = AppConfig.envBaseUrl;
    if (env.isNotEmpty) return AppConfig.normalizeUrl(env);
    final fallback = AppConfig.fallbackBaseUrl;
    if (fallback.isNotEmpty) return fallback;
    return null;
  }

  /// Returns origin without /api suffix for health checks etc.
  Future<String?> getServerOrigin() async {
    final url = await getServerUrl();
    if (url == null) return null;
    return url.split('/api').first;
  }

  Future<void> deleteServerUrl() async => _storage.delete(key: AppConstants.serverUrlKey);

  Future<void> clearAll() async => _storage.deleteAll();

  Future<bool> hasSession() async {
    final token = await getToken();
    final url = await getServerUrl();
    return token != null && token.isNotEmpty && url != null && url.isNotEmpty;
  }
}
