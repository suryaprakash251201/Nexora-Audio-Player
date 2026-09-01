import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../dto/auth_dto.dart';
import '../dto/user_dto.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client);
});

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<AuthResponseDto> login({
    required String username,
    required String password,
  }) async {
    final login = username.trim();
    // Nexora real server expects {login, password}. Provide compat for other backends.
    final payloadVariants = [
      {'login': login, 'password': password},
      {'username': login, 'password': password},
      {'email': login, 'password': password},
      {'login': login, 'password': password, 'username': login},
    ];

    // Try primary login endpoint with primary payload first, then fallback endpoints.
    final endpoints = [
      ApiConstants.login, // /auth/login -> /api/v1/auth/login
      '/auth/login',
      '/api/auth/login',
      '/api/v1/auth/login',
    ];

    Exception? lastError;
    for (final endpoint in endpoints) {
      for (final payload in payloadVariants.take(1)) {
        // Only try login payload for efficiency; other variants only if validation_error suggests
        try {
          final res = await _client.post(endpoint, data: payload);
          final data = res.data is Map<String, dynamic>
              ? res.data as Map<String, dynamic>
              : <String, dynamic>{'data': res.data};
          final dto = AuthResponseDto.fromJson(data);
          if (dto.accessToken.isEmpty) {
            throw Exception('Empty token in response');
          }
          return dto;
        } catch (e) {
          final msg = e.toString().toLowerCase();
          // If validation says login required, try next payload variant
          if (msg.contains('login and password are required') ||
              msg.contains('validation_error')) {
            // Try next variant for same endpoint
            for (final alt in payloadVariants.skip(1)) {
              try {
                final res2 = await _client.post(endpoint, data: alt);
                final data2 = res2.data is Map<String, dynamic>
                    ? res2.data as Map<String, dynamic>
                    : <String, dynamic>{'data': res2.data};
                final dto2 = AuthResponseDto.fromJson(data2);
                if (dto2.accessToken.isNotEmpty) return dto2;
              } catch (_) {}
            }
          }
          lastError = e is Exception ? e : Exception(e.toString());
          // Try next endpoint if not_found / 404
          if (msg.contains('not_found') ||
              msg.contains('404') ||
              msg.contains('endpoint not found')) {
            break;
          }
          // For 401 invalid_credentials, don't try other endpoints - surface immediately
          if (msg.contains('invalid_credentials') ||
              msg.contains('invalid username')) {
            rethrow;
          }
        }
      }
    }
    // Final attempt with the exact Nexora format via direct Dio to bypass baseUrl quirks
    try {
      final res = await _client.post(
        ApiConstants.login,
        data: {'login': login, 'password': password},
      );
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{'data': res.data};
      return AuthResponseDto.fromJson(data);
    } catch (_) {}
    throw lastError ??
        Exception('Login failed - check server URL and credentials');
  }

  Future<AuthResponseDto> refresh(String refreshToken) async {
    final res = await _client.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{'data': res.data};
    return AuthResponseDto.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {
      // Logout is best-effort; token will be cleared locally regardless
    }
  }

  Future<UserDto> me() async {
    // Real Nexora endpoint is /auth/session, not /auth/me
    final candidates = [
      '/auth/session',
      ApiConstants.me,
      '/auth/me',
      '/api/auth/session',
    ];
    Exception? last;
    for (final ep in candidates) {
      try {
        final res = await _client.get(ep);
        final raw = res.data;
        Map<String, dynamic> json;
        if (raw is Map<String, dynamic>) {
          if (raw['user'] is Map<String, dynamic>) {
            json = raw['user'] as Map<String, dynamic>;
          } else if (raw['data'] is Map<String, dynamic> &&
              raw['data']['user'] is Map) {
            json = raw['data']['user'] as Map<String, dynamic>;
          } else if (raw['data'] is Map<String, dynamic>) {
            json = raw['data'] as Map<String, dynamic>;
            if (json['user'] is Map)
              json = json['user'] as Map<String, dynamic>;
          } else {
            json = raw;
          }
          // {user: null} means unauthenticated — treat as 401
          if (raw['user'] == null && !json.containsKey('username')) {
            final unauth = UnauthorizedException('Session expired');
            throw unauth;
          }
          final dto = UserDto.fromJson(json);
          // A valid user must have an id; otherwise treat as unauthenticated.
          if (dto.id.isEmpty) {
            throw UnauthorizedException('Session expired');
          }
          return dto;
        }
      } on UnauthorizedException {
        rethrow;
      } catch (e) {
        last = e is Exception ? e : Exception(e.toString());
        final msg = e.toString().toLowerCase();
        if (msg.contains('unauthenticated') || msg.contains('not_found'))
          continue;
        if (msg.contains('401')) throw e;
      }
    }
    throw last ?? Exception('Failed to fetch user');
  }
}
