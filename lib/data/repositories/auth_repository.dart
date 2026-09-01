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
    // Save in order: user json first (harmless), then tokens last so a
    // keychain failure during token write doesn't leave a half-session.
    final user = res.user.toEntity();
    await _storage.saveUserJson(
      jsonEncode(
        UserDto(
          id: user.id,
          username: user.username,
          email: user.email,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
        ).toJson(),
      ),
    );
    await _storage.saveToken(res.accessToken);
    if (res.refreshToken != null) {
      await _storage.saveRefreshToken(res.refreshToken!);
    }
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clearAll();
    }
  }

  Future<User?> restoreSession() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final dto = await _api.me();
      // Require a real user — {user: null} means session expired.
      if (dto.id.isEmpty) {
        await _storage.deleteToken();
        return null;
      }
      final user = dto.toEntity();
      await _storage.saveUserJson(jsonEncode(dto.toJson()));
      return user;
    } catch (_) {
      // Unauthenticated (401): token invalid — clear it so the user sees Login.
      // Only fall back to cached user for network-type failures.
      final cached = await _storage.getUserJson();
      if (cached != null) {
        try {
          final j = jsonDecode(cached) as Map<String, dynamic>;
          final user = UserDto.fromJson(j).toEntity();
          if (user.id.isNotEmpty) return user;
        } catch (_) {}
      }
      return null;
    }
  }

  Future<bool> isLoggedIn() async => _storage.hasSession();
}
