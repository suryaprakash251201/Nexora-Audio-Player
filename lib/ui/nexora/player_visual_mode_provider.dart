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

  static const _legacyKey = 'player_visual_style';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(_key);
      // Migrate legacy key if canonical missing.
      raw ??= prefs.getString(_legacyKey);
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
      // Keep legacy key in sync so the old provider stays consistent.
      await prefs.setString(_legacyKey, mode.name);
    } catch (_) {
      // Persistence is best-effort; the in-memory state still flips.
    }
  }
}

final playerVisualModeProvider =
    StateNotifierProvider<PlayerVisualModeNotifier, PlayerVisualMode>(
      (ref) => PlayerVisualModeNotifier(),
    );
