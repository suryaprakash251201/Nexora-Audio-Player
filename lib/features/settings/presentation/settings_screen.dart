import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../data/api/server_api.dart';
import '../../../ui/theme.dart';
import '../../../ui/theme_provider.dart';
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Settings',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 28,
                letterSpacing: -0.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionGroup(
            title: 'PLAYBACK',
            children: [
              _SettingTile(
                icon: Icons.tune_rounded,
                title: 'Equalizer',
                subtitle: 'Audiophile 8-band EQ',
                onTap: () => context.push('/equalizer'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final timer = ref.watch(sleepTimerProvider);
                  return _SettingTile(
                    icon: Icons.bedtime_outlined,
                    title: 'Sleep timer',
                    subtitle: timer.isActive ? timer.label : 'Off',
                    trailing: Switch.adaptive(
                      value: timer.isActive,
                      onChanged: (v) {
                        if (v) {
                          _showSleepTimerSheet(context, ref);
                        } else {
                          ref.read(sleepTimerProvider.notifier).cancel();
                        }
                      },
                    ),
                    onTap: () => _showSleepTimerSheet(context, ref),
                  );
                },
              ),
              const _SettingTile(
                icon: Icons.high_quality_outlined,
                title: 'Audio quality',
                subtitle: 'Original (server) • No transcoding',
              ),
              const _SettingTile(
                icon: Icons.speed_rounded,
                title: 'Playback speed',
                subtitle: '1.0× default',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionGroup(
            title: 'LIBRARY',
            children: [
              _SettingTile(
                icon: Icons.download_outlined,
                title: 'Downloads',
                subtitle: 'Manage offline tracks',
                onTap: () => context.push('/downloads'),
              ),
              const _SettingTile(
                icon: Icons.sync_rounded,
                title: 'Sync',
                subtitle: 'Background sync is automatic',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionGroup(
            title: 'APPEARANCE',
            children: [
              _SettingTile(
                icon: ref.watch(themeModeProvider) == AppThemePreference.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Theme',
                subtitle: _themeLabel(
                  ref.watch(themeModeProvider),
                ),
                onTap: () => _showThemePicker(context, ref),
              ),
              _SettingTile(
                icon: Icons.tune_rounded,
                title: 'Player style',
                subtitle: 'Modern',
                onTap: () => _showPlayerStylePicker(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionGroup(
            title: 'SERVER',
            children: [
              FutureBuilder<String?>(
                future: storage.getServerUrl(),
                builder: (c, snap) => _SettingTile(
                  icon: Icons.dns_outlined,
                  title: snap.data ?? 'Not configured',
                  subtitle: 'Tap to configure server URL',
                  onTap: () => context.push('/server-setup'),
                ),
              ),
              serverInfo.when(
                data: (info) => _SettingTile(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  title: '${info.name} Connected',
                  subtitle: 'v${info.serverVersion} • API ${info.apiVersion}',
                ),
                loading: () => const _SettingTile(
                  icon: Icons.sync_rounded,
                  iconColor: AppColors.warning,
                  title: 'Checking server…',
                  subtitle: 'Verifying connection',
                ),
                error: (e, _) => _SettingTile(
                  icon: Icons.error_outline_rounded,
                  iconColor: AppColors.error,
                  title: 'Server unreachable',
                  subtitle: e.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionGroup(
            title: 'ABOUT',
            children: [
              const _SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Nexora Audio Player',
                subtitle: 'v1.0.0 • Audiophile edition',
              ),
              const _SettingTile(
                icon: Icons.code_rounded,
                title: 'Open source',
                subtitle:
                    'github.com/suryaprakash251201/Nexora-Audio-Player',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _DangerButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Log out?'),
                  content: const Text(
                    'This will clear your session and require re-login.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text(
                        'Log out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Nexora Audio Player v1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THEME',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                for (final pref in AppThemePreference.values)
                  _ThemeOption(
                    pref: pref,
                    selected: pref == current,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).set(pref);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPlayerStylePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PLAYER STYLE',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                for (final style in PlayerVisualStyle.values)
                  _PlayerStyleOption(
                    style: style,
                    selected: ref.read(playerVisualStyleProvider) == style,
                    onTap: () {
                      ref.read(playerVisualStyleProvider.notifier).state =
                          style;
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _SleepTimerSheet(),
    );
  }

  IconData _themeIcon(AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return Icons.light_mode_outlined;
      case AppThemePreference.dark:
        return Icons.dark_mode_outlined;
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

class _SectionGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.6),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(
                    color: AppColors.hairline,
                    height: 0.5,
                    indent: 56,
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
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 0.6),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DangerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Log out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final AppThemePreference pref;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.pref,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.border,
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(pref),
              color: selected ? AppColors.accent : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _themeLabel(pref),
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.text,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return Icons.light_mode_outlined;
      case AppThemePreference.dark:
        return Icons.dark_mode_outlined;
      case AppThemePreference.system:
        return Icons.brightness_auto_rounded;
    }
  }
}

class _PlayerStyleOption extends StatelessWidget {
  final PlayerVisualStyle style;
  final bool selected;
  final VoidCallback onTap;
  const _PlayerStyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.border,
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(style),
              color: selected ? AppColors.accent : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _labelFor(style),
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.text,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(PlayerVisualStyle s) {
    switch (s) {
      case PlayerVisualStyle.modern:
        return Icons.album_outlined;
      case PlayerVisualStyle.vinyl:
        return Icons.album_rounded;
      case PlayerVisualStyle.cassette:
        return Icons.audiotrack_outlined;
      case PlayerVisualStyle.minimal:
        return Icons.minimize_outlined;
    }
  }

  String _labelFor(PlayerVisualStyle s) {
    switch (s) {
      case PlayerVisualStyle.modern:
        return 'Modern';
      case PlayerVisualStyle.vinyl:
        return 'Vinyl';
      case PlayerVisualStyle.cassette:
        return 'Cassette';
      case PlayerVisualStyle.minimal:
        return 'Minimal';
    }
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SLEEP TIMER',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                timer.isActive ? timer.label : 'Stop playback automatically',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in SleepTimerNotifier.presets)
                    _PresetChip(
                      duration: d,
                      selected: timer.isActive && timer.total == d,
                      onTap: () {
                        ref.read(sleepTimerProvider.notifier).setTimer(d);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (timer.isActive)
                OutlinedButton(
                  onPressed: () {
                    ref.read(sleepTimerProvider.notifier).cancel();
                    Navigator.pop(context);
                  },
                  child: const Text('Turn off'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final Duration duration;
  final bool selected;
  final VoidCallback onTap;
  const _PresetChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.18)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.border,
            width: 0.6,
          ),
        ),
        child: Text(
          formatSleepDuration(duration),
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.text,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

final _serverInfoProvider = FutureProvider(
  (ref) async => ref.watch(serverApiProvider).getServerInfo(),
);