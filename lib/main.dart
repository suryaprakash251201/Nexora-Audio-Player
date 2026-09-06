import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'ui/theme.dart';
import 'ui/theme_provider.dart';
import 'core/audio/audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service before app starts
  late NexoraAudioHandler handler;
  try {
    handler = await initAudioService();
  } catch (e) {
    // Fallback handler if audio_service fails (e.g., on web)
    handler = NexoraAudioHandler();
  }

  runApp(
    ProviderScope(
      overrides: [audioHandlerProvider.overrideWithValue(handler)],
      child: const NexoraApp(),
    ),
  );
}

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final pref = ref.watch(themeModeProvider);
    // Seed the global palette synchronously for the first frame. The
    // MaterialApp builder below reconciles it against the real MediaQuery
    // (system brightness) before any route builds, so there is no flash.
    AppColors.mode = ThemeNotifier.resolve(
      pref,
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );

    return MaterialApp.router(
      // NOTE: no ValueKey(mode) here — remounting MaterialApp on theme
      // change disposes the Navigator and drops the back stack, landing
      // back-navigation on a blank page. Both palettes are provided up
      // front instead; only shell *contents* refresh (see AppShell's
      // KeyedSubtree), leaving navigation state intact.
      title: 'Nexora Audio Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(AppThemeMode.light),
      darkTheme: AppTheme.themeFor(AppThemeMode.dark),
      themeMode: switch (pref) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      },
      builder: (context, child) {
        // Runs below MaterialApp, so MediaQuery is available. Resolves
        // `system` via real brightness and syncs the AppColors global
        // before routes build (covers login/player outside the shell too).
        AppColors.mode = ThemeNotifier.resolve(
          pref,
          MediaQuery.platformBrightnessOf(context),
        );
        return child ?? const SizedBox.shrink();
      },
      routerConfig: router,
    );
  }
}
