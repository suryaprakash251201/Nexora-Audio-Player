import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<AuthResponseDto> login({required String username, required String password}) async {
    final res = await _client.post(ApiConstants.login, data: {
      'username': username,
      'password': password,
      // Some backends expect email field; send both
      'email': username.contains('@') ? username : null,
    }..removeWhere((k, v) => v == null));
    final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{'data': res.data};
    return AuthResponseDto.fromJson(data);
  }

  Future<AuthResponseDto> refresh(String refreshToken) async {
    final res = await _client.post(ApiConstants.refresh, data: {'refreshToken': refreshToken});
    final data = res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : <String, dynamic>{'data': res.data};
    return AuthResponseDto.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {
      // Ignore; client clears anyway
    }
  }

  Future<UserDto> me() async {
    final res = await _client.get(ApiConstants.me);
    final raw = res.data;
    Map<String, dynamic> json;
    if (raw is Map<String, dynamic>) {
      json = raw['data'] is Map<String, dynamic> ? raw['data'] as Map<String, dynamic> : raw;
      if (json['user'] is Map) json = json['user'] as Map<String, dynamic>;
    } else {
      json = {};
    }
    return UserDto.fromJson(json);
  }
}
