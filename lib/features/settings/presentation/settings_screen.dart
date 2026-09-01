import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../data/api/server_api.dart';
import '../../../ui/theme.dart';
import '../../../ui/theme_provider.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../../ui/animations/app_animations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../player/providers/sleep_timer_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverInfo = ref.watch(_serverInfoProvider);
    final storage = ref.watch(secureStorageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            const SizedBox(height: 8),
            SlideInAnimation(
              child: _settingsGroup('SERVER', [
                FutureBuilder<String?>(
                  future: storage.getServerUrl(),
                  builder: (c, snap) => _SettingTile(
                    icon: Icons.dns_rounded,
                    iconBg: AppColors.primary,
                    title: snap.data ?? 'Not configured',
                    subtitle: 'Tap to configure server URL',
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textDim,
                    ),
                    onTap: () => context.push('/server-setup'),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            serverInfo.when(
              data: (info) => SlideInAnimation(
                child: _settingsGroup('CONNECTION', [
                  _SettingTile(
                    icon: Icons.check_circle_rounded,
                    iconBg: AppColors.success,
                    title: '${info.name} Connected',
                    subtitle: 'v${info.serverVersion} • API ${info.apiVersion}',
                    trailing: _StatusPill(text: 'Online'),
                  ),
                ]),
              ),
              loading: () => SlideInAnimation(
                child: _settingsGroup('CONNECTION', [
                  const _SettingTile(
                    icon: Icons.sync_rounded,
                    iconBg: AppColors.warning,
                    title: 'Checking server...',
                    subtitle: 'Verifying connection',
                    showSpinner: true,
                  ),
                ]),
              ),
              error: (e, _) => SlideInAnimation(
                child: _settingsGroup('CONNECTION', [
                  _SettingTile(
                    icon: Icons.error_outline_rounded,
                    iconBg: AppColors.error,
                    title: 'Server unreachable',
                    subtitle: e.toString(),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SlideInAnimation(
              delay: const Duration(milliseconds: 100),
              child: Consumer(
                builder: (context, ref, _) {
                  final timer = ref.watch(sleepTimerProvider);
                  return _settingsGroup('PLAYBACK', [
                    _SettingTile(
                      icon: Icons.graphic_eq_rounded,
                      iconBg: AppColors.secondary,
                      title: 'Equalizer',
                      subtitle: 'Audiophile 8-band EQ',
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textDim,
                      ),
                      onTap: () => context.push('/equalizer'),
                    ),
                    _SettingTile(
                      icon: Icons.timer_outlined,
                      iconBg: AppColors.tertiary,
                      title: 'Sleep timer',
                      subtitle: timer.isActive ? timer.label : 'Off',
                      trailing: Switch(
                        value: timer.isActive,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.35,
                        ),
                        inactiveThumbColor: AppColors.textDim,
                        inactiveTrackColor: AppColors.surfaceHigh,
                        onChanged: (v) {
                          if (v) {
                            _showSleepTimerSheet(context, ref);
                          } else {
                            ref.read(sleepTimerProvider.notifier).cancel();
                          }
                        },
                      ),
                      onTap: () => _showSleepTimerSheet(context, ref),
                    ),
                    const _SettingTile(
                      icon: Icons.high_quality_rounded,
                      iconBg: AppColors.primary,
                      title: 'Audio quality',
                      subtitle: 'Original (server) • No transcoding',
                      trailing: _StatusPill(text: 'Hi-Res'),
                    ),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 20),
            SlideInAnimation(
              delay: const Duration(milliseconds: 200),
              child: _settingsGroup('APPEARANCE', [
                ref.watch(themeModeProvider) == AppThemePreference.dark
                    ? _SettingTile(
                        icon: Icons.dark_mode_rounded,
                        iconBg: AppColors.primary,
                        title: 'Theme',
                        subtitle: 'Dark • Midnight Glassmorphism',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textDim,
                        ),
                        onTap: () => _showThemePicker(context, ref),
                      )
                    : _SettingTile(
                        icon: Icons.light_mode_rounded,
                        iconBg: AppColors.secondary,
                        title: 'Theme',
                        subtitle: 'Light • Adaptive device support',
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textDim,
                        ),
                        onTap: () => _showThemePicker(context, ref),
                      ),
              ]),
            ),
            const SizedBox(height: 20),
            SlideInAnimation(
              delay: const Duration(milliseconds: 300),
              child: _settingsGroup('ABOUT', [
                const _SettingTile(
                  icon: Icons.shield_rounded,
                  iconBg: AppColors.success,
                  title: 'Nexora Audio Player',
                  subtitle: 'v1.0.0 • Audiophile edition',
                  trailing: GlowDot(size: 8, color: AppColors.success),
                ),
                const _SettingTile(
                  icon: Icons.code_rounded,
                  iconBg: AppColors.secondary,
                  title: 'Open source',
                  subtitle:
                      'github.com/suryaprakash251201/Nexora-Audio-Player',
                ),
              ]),
            ),
            const SizedBox(height: 28),
            SlideInAnimation(
              delay: const Duration(milliseconds: 400),
              child: NeonGlowButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                color: AppColors.error,
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => GlassDialog(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.logout_rounded,
                                color: AppColors.error,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Log out?',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This will clear your session and require re-login.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(c, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.text,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(c, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.error.withValues(alpha: 0.8),
                                            AppColors.error.withValues(alpha: 0.6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        'Log out',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  if (ok == true) {
                    await ref.read(authStateProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nexora Audio Player v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textDim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GlassBottomSheet(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Adaptive device support included',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  for (final pref in AppThemePreference.values)
                    GlassCard(
                      borderRadius: 16,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).set(pref);
                        Navigator.pop(sheetContext);
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.15),
                                  AppColors.secondary.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _themeIcon(pref),
                              color: pref == current
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _themeLabel(pref),
                              style: TextStyle(
                                color: pref == current
                                    ? AppColors.primary
                                    : AppColors.text,
                                fontWeight: pref == current
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (pref == current)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _SettingsSleepTimerSheet(),
    );
  }

  IconData _themeIcon(AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return Icons.light_mode_rounded;
      case AppThemePreference.dark:
        return Icons.dark_mode_rounded;
      case AppThemePreference.system:
        return Icons.brightness_auto_rounded;
    }
  }

  String _themeLabel(AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
      case AppThemePreference.system:
        return 'System default';
    }
  }

  Widget _settingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        EnhancedGlassSurface(
          opacity: 0.45,
          blur: 25,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    color: AppColors.border,
                    height: 0.5,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showSpinner;

  const _SettingTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              iconBg.withValues(alpha: 0.22),
              iconBg.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconBg.withValues(alpha: 0.18), width: 0.5),
        ),
        child: showSpinner
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(strokeWidth: 2, color: iconBg),
              )
            : Icon(icon, color: iconBg, size: 22),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          : null,
      trailing: trailing,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final isOnline = text.toLowerCase().contains('online');
    final color = isOnline ? AppColors.success : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlowDot(size: 6, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSleepTimerSheet extends ConsumerWidget {
  const _SettingsSleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return GlassBottomSheet(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.tertiary.withValues(alpha: 0.22),
                          AppColors.primary.withValues(alpha: 0.14),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      color: AppColors.tertiary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sleep timer',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          timer.isActive
                              ? timer.label
                              : 'Automatically pause playback',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timer.isActive)
                    GestureDetector(
                      onTap: () =>
                          ref.read(sleepTimerProvider.notifier).cancel(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (timer.isActive) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: timer.progress,
                    minHeight: 4,
                    backgroundColor: AppColors.textDim.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(AppColors.tertiary),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                'DURATION',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final d in SleepTimerNotifier.presets)
                    GestureDetector(
                      onTap: () {
                        ref.read(sleepTimerProvider.notifier).setTimer(d);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: timer.isActive && timer.total == d
                              ? LinearGradient(
                                  colors: [
                                    AppColors.tertiary.withValues(alpha: 0.22),
                                    AppColors.primary.withValues(alpha: 0.14),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    AppColors.surfaceRaised.withValues(
                                      alpha: 0.9,
                                    ),
                                    AppColors.surfaceHigh.withValues(
                                      alpha: 0.6,
                                    ),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: timer.isActive && timer.total == d
                                ? AppColors.tertiary.withValues(alpha: 0.35)
                                : AppColors.border,
                            width: 0.6,
                          ),
                        ),
                        child: Text(
                          formatSleepDuration(d),
                          style: TextStyle(
                            color: timer.isActive && timer.total == d
                                ? AppColors.tertiary
                                : AppColors.text,
                            fontWeight: timer.isActive && timer.total == d
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    if (timer.isActive) {
                      ref.read(sleepTimerProvider.notifier).cancel();
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: Text(
                      timer.isActive ? 'Turn off' : 'Off',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _serverInfoProvider = FutureProvider(
  (ref) async => ref.watch(serverApiProvider).getServerInfo(),
);
