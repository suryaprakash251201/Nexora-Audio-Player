import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nexora_flutter/core/audio/audio_handler.dart';
import 'package:nexora_flutter/main.dart';
import 'package:nexora_flutter/router.dart';
import 'package:nexora_flutter/ui/theme.dart';
import 'package:nexora_flutter/ui/theme_provider.dart';

/// Regression tests for the theme/navigation blank-page class of bugs:
///
/// - `AppTheme.themeFor` must be pure (building both palettes up front
///   must not clobber the active `AppColors.mode`).
/// - Toggling the theme must preserve the current screen and the GoRouter
///   instance (no MaterialApp remount, no dropped back stack).
/// - A persisted preference must restore without crashing.
void main() {
  tearDown(() {
    AppColors.mode = AppThemeMode.dark;
  });

  test('themeFor is pure and leaves the global palette untouched', () {
    AppColors.mode = AppThemeMode.dark;
    final light = AppTheme.themeFor(AppThemeMode.light);
    final dark = AppTheme.themeFor(AppThemeMode.dark);
    expect(AppColors.mode, AppThemeMode.dark);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
  });

  testWidgets('theme toggle preserves screen and router (no blank page)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [audioHandlerProvider.overrideWithValue(NexoraAudioHandler())],
    );
    addTearDown(container.dispose);

    Future<void> settle() async {
      // Fixed pumps, not pumpAndSettle: login keeps a frame scheduled
      // (progress/font loading), same as the existing smoke test.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NexoraApp()),
    );
    await settle();
    expect(tester.takeException(), isNull);
    expect(find.text('NEXORA'), findsWidgets);

    final routerBefore = container.read(routerProvider);

    // Light…
    await container
        .read(themeModeProvider.notifier)
        .set(AppThemePreference.light);
    await settle();
    expect(tester.takeException(), isNull);
    expect(find.text('NEXORA'), findsWidgets);
    expect(AppColors.mode, AppThemeMode.light);

    // …and back to dark. Same screen, same router, no blank frame.
    await container
        .read(themeModeProvider.notifier)
        .set(AppThemePreference.dark);
    await settle();
    expect(tester.takeException(), isNull);
    expect(find.text('NEXORA'), findsWidgets);
    expect(AppColors.mode, AppThemeMode.dark);
    expect(identical(container.read(routerProvider), routerBefore), isTrue);
  });

  testWidgets('persisted theme preference restores without crashing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
    final container = ProviderContainer(
      overrides: [audioHandlerProvider.overrideWithValue(NexoraAudioHandler())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NexoraApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(container.read(themeModeProvider), AppThemePreference.dark);
    expect(find.text('NEXORA'), findsWidgets);
  });
}
