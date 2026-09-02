import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nexora_tokens.dart';

/// Persists the chosen [PlayerVisualMode] in shared_preferences so the
/// user's preference survives restarts.
class PlayerVisualModeNotifier extends StateNotifier<PlayerVisualMode> {
  static const _key = 'player_visual_mode';

  PlayerVisualModeNotifier() : super(PlayerVisualMode.modern) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      state = PlayerVisualMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => PlayerVisualMode.modern,
      );
    } catch (_) {
      // Ignore — defaults to modern.
    }
  }

  Future<void> set(PlayerVisualMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Persistence is best-effort; the in-memory state still flips.
    }
  }
}

final playerVisualModeProvider =
    StateNotifierProvider<PlayerVisualModeNotifier, PlayerVisualMode>(
  (ref) => PlayerVisualModeNotifier(),
);