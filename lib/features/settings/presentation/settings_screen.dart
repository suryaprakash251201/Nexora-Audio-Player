import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../data/api/server_api.dart';
import '../../../ui/theme.dart';
import '../../../ui/theme_provider.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/nexora/nexora_icons.dart';
import '../../../ui/nexora/player_visual_mode_provider.dart';
import '../../../ui/nexora/nexora_dialog.dart';
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
          Padding(
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
                glyph: NexoraGlyphKind.waveform,
                title: 'Equalizer',
                subtitle: 'Audiophile 8-band EQ',
                onTap: () => context.push('/equalizer'),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final timer = ref.watch(sleepTimerProvider);
                  return _SettingTile(
                    glyph: NexoraGlyphKind.night,
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
              _SettingTile(
                glyph: NexoraGlyphKind.hiRes,
                title: 'Audio quality',
                subtitle: 'Original (server) • No transcoding',
              ),
              _SettingTile(
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
              _SettingTile(
                icon: Icons.sync_rounded,
                title: 'Sync',
                subtitle: 'Background sync is automatic',
              ),
              _SettingTile(
                glyph: NexoraGlyphKind.stats,
                title: 'Your stats',
                subtitle: 'Listening time, peak hours, top artists',
                onTap: () => context.push('/stats'),
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
                    : ref.watch(themeModeProvider) == AppThemePreference.light
                        ? Icons.light_mode_outlined
                        : Icons.brightness_auto_rounded,
                title: 'Theme',
                subtitle: _themeLabel(
                  ref.watch(themeModeProvider),
                ),
                onTap: () => _showThemePicker(context, ref),
              ),
              Consumer(
                builder: (context, ref, _) {
                  final mode = ref.watch(playerVisualModeProvider);
                  return _SettingTile(
                    icon: _playerStyleIcon(mode),
                    title: 'Player style',
                    subtitle: mode.label,
                    onTap: () => _showPlayerStylePicker(context, ref),
                  );
                },
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
                loading: () => _SettingTile(
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
              _SettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Nexora Audio Player',
                subtitle: 'v1.0.0 • Audiophile edition',
              ),
              _SettingTile(
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
          Text(
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
    await showNexoraFloatingDialog<void>(
      context: context,
      title: 'Theme',
      subtitle: 'Choose how the app appearance adapts to light & dark.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < AppThemePreference.values.length; i++)
            NexoraFloatingOption(
              index: i,
              icon: _themeIcon(AppThemePreference.values[i]),
              title: _themeLabel(AppThemePreference.values[i]),
              description: _themeDescription(AppThemePreference.values[i]),
              selected: AppThemePreference.values[i] == current,
              onTap: () {
                ref.read(themeModeProvider.notifier).set(
                      AppThemePreference.values[i],
                    );
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showPlayerStylePicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(playerVisualModeProvider);
    await showNexoraFloatingDialog<void>(
      context: context,
      title: 'Player style',
      subtitle: 'Choose how the artwork stage is presented.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < PlayerVisualMode.values.length; i++)
            NexoraFloatingOption(
              index: i,
              icon: _playerStyleIcon(PlayerVisualMode.values[i]),
              title: PlayerVisualMode.values[i].label,
              description:
                  _playerStyleDescription(PlayerVisualMode.values[i]),
              selected: PlayerVisualMode.values[i] == current,
              onTap: () {
                ref
                    .read(playerVisualModeProvider.notifier)
                    .set(PlayerVisualMode.values[i]);
                // Keep legacy provider in sync for any stale readers
                final legacy = PlayerVisualStyle.values.firstWhere(
                  (e) => e.name == PlayerVisualMode.values[i].name,
                );
                ref.read(playerVisualStyleProvider.notifier).state = legacy;
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => _SleepTimerSheet(),
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

  String _themeDescription(AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return 'Bright paper tones, best in daylight.';
      case AppThemePreference.dark:
        return 'Deep navy studio vibe — the default.';
      case AppThemePreference.system:
        return 'Follows your device light/dark setting.';
    }
  }

  IconData _playerStyleIcon(PlayerVisualMode m) {
    switch (m) {
      case PlayerVisualMode.modern:
        return Icons.album_outlined;
      case PlayerVisualMode.vinyl:
        return Icons.album_rounded;
      case PlayerVisualMode.cassette:
        return Icons.audiotrack_outlined;
      case PlayerVisualMode.minimal:
        return Icons.minimize_rounded;
    }
  }

  String _playerStyleDescription(PlayerVisualMode m) {
    switch (m) {
      case PlayerVisualMode.modern:
        return 'Calm dark canvas with sharp square artwork.';
      case PlayerVisualMode.vinyl:
        return 'Rotating round record with artwork at center.';
      case PlayerVisualMode.cassette:
        return 'Tape-inspired stage with rotating reels.';
      case PlayerVisualMode.minimal:
        return 'Only artwork and track identity — pure.';
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
  _SectionGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
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
                  Divider(
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
  final IconData? icon;

  /// Optional custom-drawn glyph. Takes precedence over [icon].
  final NexoraGlyphKind? glyph;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  _SettingTile({
    this.icon,
    this.glyph,
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: glyph != null
                  ? NexoraGlyph(kind: glyph!, size: 18, color: c)
                  : Icon(icon ?? Icons.settings_outlined, color: c, size: 18),
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
                    style: TextStyle(
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
                      style: TextStyle(
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
  _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return Container(
      decoration: BoxDecoration(
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
              Text(
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
                style: TextStyle(
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