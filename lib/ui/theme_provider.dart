import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/prefs_service.dart';
import 'theme.dart';

/// Persisted app theme preference (system / light / dark).
enum AppThemePreference { system, light, dark }

/// Player visual mode. Modern is the calm Hi-Fi default; the others are
/// opt-in personalizations — Vinyl spins, Cassette is the signature
/// nostalgic mode, and Minimal removes artwork flourish entirely.
enum PlayerVisualStyle { modern, vinyl, cassette, minimal }

/// Current resolved theme mode, kept in sync with the persisted preference.
final themeModeProvider = NotifierProvider<ThemeNotifier, AppThemePreference>(
  ThemeNotifier.new,
);

/// Player visual style (persisted).
final playerVisualStyleProvider =
    NotifierProvider<PlayerVisualStyleNotifier, PlayerVisualStyle>(
  PlayerVisualStyleNotifier.new,
);

class ThemeNotifier extends Notifier<AppThemePreference> {
  static const _key = 'app_theme_mode';

  @override
  AppThemePreference build() {
    // Try to restore the saved preference.
    final prefs = ref.watch(prefsServiceProvider);
    prefs
        .getString(_key)
        .then((v) {
          for (final p in AppThemePreference.values) {
            if (p.name == v) {
              state = p;
              return;
            }
          }
        })
        .catchError((_) {});
    return AppThemePreference.system;
  }

  Future<void> set(AppThemePreference pref) async {
    state = pref;
    final prefs = ref.read(prefsServiceProvider);
    try {
      await prefs.setString(_key, pref.name);
    } catch (_) {}
  }

  /// Resolve the concrete dark/light mode given the system brightness.
  static AppThemeMode resolve(
    AppThemePreference pref,
    Brightness systemBrightness,
  ) {
    switch (pref) {
      case AppThemePreference.light:
        return AppThemeMode.light;
      case AppThemePreference.dark:
        return AppThemeMode.dark;
      case AppThemePreference.system:
        return systemBrightness == Brightness.dark
            ? AppThemeMode.dark
            : AppThemeMode.light;
    }
  }
}

class PlayerVisualStyleNotifier extends Notifier<PlayerVisualStyle> {
  static const _key = 'player_visual_style';

  @override
  PlayerVisualStyle build() {
    final prefs = ref.watch(prefsServiceProvider);
    prefs
        .getString(_key)
        .then((v) {
          for (final s in PlayerVisualStyle.values) {
            if (s.name == v) {
              state = s;
              return;
            }
          }
        })
        .catchError((_) {});
    return PlayerVisualStyle.modern;
  }

  Future<void> set(PlayerVisualStyle style) async {
    state = style;
    final prefs = ref.read(prefsServiceProvider);
    try {
      await prefs.setString(_key, style.name);
    } catch (_) {}
  }
}
