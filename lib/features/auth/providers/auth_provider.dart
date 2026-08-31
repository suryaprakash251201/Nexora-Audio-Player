import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/user.dart';

final authStateProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  late AuthRepository _repo;
  late SecureStorageService _storage;

  @override
  Future<User?> build() async {
    _repo = ref.watch(authRepositoryProvider);
    _storage = ref.watch(secureStorageProvider);
    // Try restore session on app start
    try {
      final user = await _repo.restoreSession();
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String username, String password, String serverUrl) async {
    state = const AsyncLoading();
    try {
      if (serverUrl.trim().isNotEmpty) {
        await _storage.saveServerUrl(serverUrl.trim());
      }
      final user = await _repo.login(username.trim(), password);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } finally {
      state = const AsyncData(null);
    }
  }

  Future<void> restore() async {
    state = const AsyncLoading();
    final user = await _repo.restoreSession();
    state = AsyncData(user);
  }

  bool get isAuthenticated => state.value != null;
}

final isAuthenticatedProvider = Provider<bool>((ref) {
  final s = ref.watch(authStateProvider);
  return s.value != null;
});
