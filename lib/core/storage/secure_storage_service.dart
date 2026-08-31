import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../logging/app_logger.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Wraps flutter_secure_storage with resilience against iOS Keychain
/// errSecDuplicateItem (-25299): "The specified item already exists in the
/// keychain." This happens when a key is written again after the underlying
/// SecItem entry was created under a different accessibility class / data
/// protection keychain, causing lookup-vs-add mismatch.
///
/// Strategy: on duplicate error -> delete the key, retry write; if it still
/// fails, wipe all keys once (migration) and retry.
class SecureStorageService {
  SecureStorageService() {
    _storage = FlutterSecureStorage(
      aOptions: const AndroidOptions(),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );
  }

  late final FlutterSecureStorage _storage;
  bool _didWipe = false;

  /// Duplicate-safe write. Never throws for -25299.
  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      final duplicate =
          e.code == '-25299' ||
          (e.message ?? '').toLowerCase().contains('already exist');
      if (!duplicate) rethrow;

      AppLogger.auth('Keychain duplicate ($key) — deleting and retrying');
      try {
        await _storage.delete(key: key);
      } catch (_) {}

      try {
        await _storage.write(key: key, value: value);
      } on PlatformException {
        // Last resort: wipe keychain entries created by this app once, then retry.
        if (!_didWipe) {
          _didWipe = true;
          try {
            await _storage.deleteAll();
            AppLogger.auth('Keychain wiped for migration');
          } catch (_) {}
        }
        await _storage.write(key: key, value: value);
      }
    }
  }

  // Tokens
  Future<void> saveToken(String token) => _write(AppConstants.tokenKey, token);

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConstants.tokenKey);
    } on PlatformException catch (e) {
      AppLogger.auth('Token read failed: ${e.code} ${e.message}');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {}
  }

  Future<void> saveRefreshToken(String token) =>
      _write(AppConstants.refreshTokenKey, token);

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConstants.refreshTokenKey);
    } on PlatformException {
      return null;
    }
  }

  Future<void> saveUserJson(String json) => _write(AppConstants.userKey, json);

  Future<String?> getUserJson() async {
    try {
      return await _storage.read(key: AppConstants.userKey);
    } on PlatformException {
      return null;
    }
  }

  // Server URL - normalized
  Future<void> saveServerUrl(String url) async {
    final normalized = AppConfig.normalizeUrl(url);
    await _write(AppConstants.serverUrlKey, normalized);
  }

  /// Raw stored value (already normalized) or null.
  Future<String?> getServerUrl() async {
    try {
      final stored = await _storage.read(key: AppConstants.serverUrlKey);
      if (stored != null && stored.isNotEmpty) return stored;
    } on PlatformException catch (e) {
      AppLogger.auth('ServerUrl read failed: ${e.code}');
    }
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

  Future<void> deleteServerUrl() async {
    try {
      await _storage.delete(key: AppConstants.serverUrlKey);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } on PlatformException catch (e) {
      // On iOS duplicate-class wipe issues, delete known keys individually.
      AppLogger.auth(
        'clearAll failed (${e.code}) — deleting keys individually',
      );
      for (final k in [
        AppConstants.tokenKey,
        AppConstants.refreshTokenKey,
        AppConstants.userKey,
        AppConstants.serverUrlKey,
      ]) {
        try {
          await _storage.delete(key: k);
        } catch (_) {}
      }
    }
  }

  Future<bool> hasSession() async {
    final token = await getToken();
    final url = await getServerUrl();
    return token != null && token.isNotEmpty && url != null && url.isNotEmpty;
  }
}
