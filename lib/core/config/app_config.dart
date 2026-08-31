import 'package:flutter/foundation.dart';

/// Central configuration for server URLs and env.
/// Supports --dart-define overrides and user-configurable server URL.
///
/// Priority for baseUrl:
/// 1. Value stored in SecureStorage (user entered in ServerConfig screen)
/// 2. --dart-define NEXORA_API_BASE_URL
/// 3. Environment fallback (dev/staging/prod)
class AppConfig {
  const AppConfig._();

  static const String _envBaseUrl = String.fromEnvironment(
    'NEXORA_API_BASE_URL',
    defaultValue: '',
  );

  static const String _envStreamBaseUrl = String.fromEnvironment(
    'NEXORA_STREAM_BASE_URL',
    defaultValue: '',
  );

  static const String _envArtworkBaseUrl = String.fromEnvironment(
    'NEXORA_ARTWORK_BASE_URL',
    defaultValue: '',
  );

  static String get envBaseUrl => _envBaseUrl;
  static String get envStreamBaseUrl => _envStreamBaseUrl;
  static String get envArtworkBaseUrl => _envArtworkBaseUrl;

  /// Fallback when no server configured (dev convenience).
  /// Never used as production hardcoded URL.
  static String get fallbackBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kDebugMode) return 'http://localhost:3000/api/v1';
    return '';
  }

  static bool get isDebug => kDebugMode;

  /// Normalize raw user input into a usable baseUrl.
  /// - trims
  /// - prepends http:// for bare IPs / localhost, https:// otherwise
  /// - strips trailing /
  /// - ensures /api/v1 suffix
  static String normalizeUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}');
      if (ipRegex.hasMatch(url) || url.startsWith('localhost')) {
        url = 'http://$url';
      } else {
        url = 'https://$url';
      }
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    // Ensure /api/v1 present; if user entered /api, append /v1; if nothing, append.
    if (!url.contains('/api')) {
      url = '$url/api/v1';
    } else if (url.endsWith('/api')) {
      url = '$url/v1';
    } else if (!url.contains('/api/v1')) {
      // If custom path like /api/v2, keep; else add v1
      if (!RegExp(r'/api/v\d+').hasMatch(url)) {
        url = '$url/v1';
      }
    }
    return url;
  }

  /// Resolve artwork URL: if relative, join with base.
  static String resolveArtworkUrl(String? maybeRelative, String baseUrl) {
    if (maybeRelative == null || maybeRelative.isEmpty) return '';
    if (maybeRelative.startsWith('http')) return maybeRelative;
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final path = maybeRelative.startsWith('/') ? maybeRelative : '/$maybeRelative';
    // If base already has /api/v1, artwork may be /api/v1/... so just join root
    // For simplicity, if path starts with /api, replace base's /api/v1 prefix with origin.
    if (path.startsWith('/api')) {
      final origin = base.split('/api').first;
      return '$origin$path';
    }
    return '$base$path';
  }

  static String resolveStreamUrl(String? maybeRelative, String baseUrl) {
    return resolveArtworkUrl(maybeRelative, baseUrl);
  }
}
