import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/prefs_service.dart';
import 'theme.dart';

/// Persisted app theme preference (system / light / dark).
enum AppThemePreference { system, light, dark }

/// Current resolved theme mode, kept in sync with the persisted preference.
final themeModeProvider = NotifierProvider<ThemeNotifier, AppThemePreference>(
  ThemeNotifier.new,
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
