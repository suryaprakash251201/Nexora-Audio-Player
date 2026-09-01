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
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    final mode = ThemeNotifier.resolve(pref, systemBrightness);
    // Point the global palette at the resolved mode so that every screen that
    // reads AppColors during build resolves the matching colors.
    AppColors.mode = mode;
    final isDark = mode == AppThemeMode.dark;

    return MaterialApp.router(
      key: ValueKey(mode), // remount the tree so every AppColors read refreshes
      title: 'Nexora Audio Player',
      debugShowCheckedModeBanner: false,
      // A single theme resolved for the active mode. AppColors.mode is set
      // above so the palette reads match, and the key remount refreshes every
      // screen the moment the user switches light/dark.
      theme: AppTheme.themeFor(mode),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
