import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../api/auth_api.dart';
import '../dto/user_dto.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ref.watch(authApiProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(api, storage);
});

class AuthRepository {
  final AuthApi _api;
  final SecureStorageService _storage;
  AuthRepository(this._api, this._storage);

  Future<User> login(String username, String password) async {
    final res = await _api.login(username: username, password: password);
    await _storage.saveToken(res.accessToken);
    if (res.refreshToken != null) await _storage.saveRefreshToken(res.refreshToken!);
    final user = res.user.toEntity();
    await _storage.saveUserJson(jsonEncode(UserDto(id: user.id, username: user.username, email: user.email, displayName: user.displayName, avatarUrl: user.avatarUrl).toJson()));
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.deleteToken();
      await _storage.clearAll();
    }
  }

  Future<User?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final dto = await _api.me();
      final user = dto.toEntity();
      await _storage.saveUserJson(jsonEncode(dto.toJson()));
      return user;
    } catch (_) {
      // Fallback to cached user if server unavailable
      final cached = await _storage.getUserJson();
      if (cached != null) {
        try {
          final j = jsonDecode(cached) as Map<String, dynamic>;
          return UserDto.fromJson(j).toEntity();
        } catch (_) {}
      }
      return null;
    }
  }

  Future<bool> isLoggedIn() async => _storage.hasSession();
}
