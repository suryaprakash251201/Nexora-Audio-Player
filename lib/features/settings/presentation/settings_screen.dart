import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../data/api/server_api.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/nexora/nexora_icons.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/player_visual_mode_provider.dart';
import '../../../ui/nexora/nexora_dialog.dart';
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
    final isDark = AppColors.mode == AppThemeMode.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: 68,
            flexibleSpace: const NexoraSliverAppBarBackground(blur: 20),
            title: Text(
              'Settings',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: -0.7,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            sliver: SliverList.list(
              children: [
                _SectionGroup(
                  title: 'PLAYBACK',
                  accent: AppColors.accent,
                  children: [
                    _SettingTile(
                      icon: Icons.equalizer_rounded,
                      iconBg: AppColors.accent.withValues(alpha: 0.12),
                      iconColor: AppColors.accent,
                      title: 'Equalizer',
                      subtitle: '8-band audiophile EQ',
                      showChevron: true,
                      onTap: () => context.push('/equalizer'),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final timer = ref.watch(sleepTimerProvider);
                        return _SettingTile(
                          icon: Icons.bedtime_rounded,
                          iconBg: const Color(
                            0xFF6B5BFF,
                          ).withValues(alpha: isDark ? 0.14 : 0.10),
                          iconColor: const Color(0xFF6B5BFF),
                          title: 'Sleep timer',
                          subtitle: timer.isActive ? timer.label : 'Off',
                          trailing: Switch.adaptive(
                            value: timer.isActive,
                            activeTrackColor: AppColors.accent,
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
                      iconBg: AppColors.success.withValues(alpha: 0.11),
                      iconColor: AppColors.success,
                      title: 'Audio quality',
                      subtitle: 'Original • No transcoding',
                    ),
                    _SettingTile(
                      icon: Icons.speed_rounded,
                      iconBg: const Color(
                        0xFFFF8A3D,
                      ).withValues(alpha: isDark ? 0.13 : 0.09),
                      iconColor: const Color(0xFFFF8A3D),
                      title: 'Playback speed',
                      subtitle: '1.0× • Standard',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionGroup(
                  title: 'LIBRARY',
                  accent: const Color(0xFFB24CFF),
                  children: [
                    _SettingTile(
                      icon: Icons.download_rounded,
                      iconBg: const Color(
                        0xFF2EC4B6,
                      ).withValues(alpha: isDark ? 0.13 : 0.10),
                      iconColor: const Color(0xFF2EC4B6),
                      title: 'Downloads',
                      subtitle: 'Manage offline tracks',
                      showChevron: true,
                      onTap: () => context.push('/downloads'),
                    ),
                    _SettingTile(
                      icon: Icons.sync_rounded,
                      iconBg: AppColors.accent.withValues(alpha: 0.11),
                      iconColor: AppColors.accent,
                      title: 'Sync',
                      subtitle: 'Automatic background sync',
                    ),
                    _SettingTile(
                      glyph: NexoraGlyphKind.stats,
                      iconBg: const Color(
                        0xFFFFB020,
                      ).withValues(alpha: isDark ? 0.13 : 0.10),
                      iconColor: const Color(0xFFFFB020),
                      title: 'Your stats',
                      subtitle: 'Listening time & top artists',
                      showChevron: true,
                      onTap: () => context.push('/stats'),
                    ),
                    _SettingTile(
                      icon: Icons.link_rounded,
                      iconBg: AppColors.accent.withValues(
                        alpha: isDark ? 0.13 : 0.10,
                      ),
                      iconColor: AppColors.accent,
                      title: 'Shared links',
                      subtitle: 'Public links & revoke access',
                      showChevron: true,
                      onTap: () => context.push('/shares'),
                    ),
                    _SettingTile(
                      icon: Icons.label_outline_rounded,
                      iconBg: const Color(
                        0xFFB24CFF,
                      ).withValues(alpha: isDark ? 0.13 : 0.10),
                      iconColor: const Color(0xFFB24CFF),
                      title: 'Tags',
                      subtitle: 'Organize files beyond playlists',
                      showChevron: true,
                      onTap: () => context.push('/tags'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionGroup(
                  title: 'APPEARANCE',
                  accent: const Color(0xFF4ECDC4),
                  children: [
                    _SettingTile(
                      icon:
                          ref.watch(themeModeProvider) ==
                              AppThemePreference.dark
                          ? Icons.dark_mode_rounded
                          : ref.watch(themeModeProvider) ==
                                AppThemePreference.light
                          ? Icons.light_mode_rounded
                          : Icons.brightness_auto_rounded,
                      iconBg: const Color(
                        0xFF6B7AFF,
                      ).withValues(alpha: isDark ? 0.14 : 0.10),
                      iconColor: const Color(0xFF6B7AFF),
                      title: 'Theme',
                      subtitle: _themeLabel(ref.watch(themeModeProvider)),
                      showChevron: true,
                      onTap: () => _showThemePicker(context, ref),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final mode = ref.watch(playerVisualModeProvider);
                        return _SettingTile(
                          icon: _playerStyleIcon(mode),
                          iconBg: const Color(
                            0xFFFF6B9D,
                          ).withValues(alpha: isDark ? 0.13 : 0.09),
                          iconColor: const Color(0xFFFF6B9D),
                          title: 'Player style',
                          subtitle: mode.label,
                          showChevron: true,
                          onTap: () => _showPlayerStylePicker(context, ref),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionGroup(
                  title: 'SERVER',
                  accent: AppColors.success,
                  children: [
                    FutureBuilder<String?>(
                      future: storage.getServerUrl(),
                      builder: (c, snap) => _SettingTile(
                        icon: Icons.dns_rounded,
                        iconBg: AppColors.textMuted.withValues(
                          alpha: isDark ? 0.14 : 0.08,
                        ),
                        iconColor: AppColors.textMuted,
                        title: snap.data ?? 'Not configured',
                        subtitle: 'Tap to configure server URL',
                        showChevron: true,
                        onTap: () => context.push('/server-setup'),
                      ),
                    ),
                    serverInfo.when(
                      data: (info) => _SettingTile(
                        icon: Icons.check_circle_rounded,
                        iconBg: AppColors.success.withValues(alpha: 0.12),
                        iconColor: AppColors.success,
                        title: '${info.name} • Connected',
                        subtitle:
                            'v${info.serverVersion} • API ${info.apiVersion}',
                      ),
                      loading: () => _SettingTile(
                        icon: Icons.sync_rounded,
                        iconBg: AppColors.warning.withValues(alpha: 0.12),
                        iconColor: AppColors.warning,
                        title: 'Checking server…',
                        subtitle: 'Verifying connection',
                      ),
                      error: (e, _) => _SettingTile(
                        icon: Icons.error_rounded,
                        iconBg: AppColors.error.withValues(alpha: 0.11),
                        iconColor: AppColors.error,
                        title: 'Server unreachable',
                        subtitle: e.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionGroup(
                  title: 'ABOUT',
                  accent: AppColors.textDim,
                  children: [
                    _SettingTile(
                      icon: Icons.hub_outlined,
                      iconBg: AppColors.accent.withValues(alpha: 0.11),
                      iconColor: AppColors.accent,
                      title: 'Nexora Audio Player',
                      subtitle: 'v1.0.0 • Audiophile edition',
                    ),
                    _SettingTile(
                      icon: Icons.code_rounded,
                      iconBg: AppColors.textMuted.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                      iconColor: AppColors.textMuted,
                      title: 'Open source',
                      subtitle:
                          'github.com/suryaprakash251201/Nexora-Audio-Player',
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: _DangerCard(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          backgroundColor: AppColors.card,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: NexoraRadius.dialog,
                            side: BorderSide(
                              color: AppColors.border,
                              width: 0.7,
                            ),
                          ),
                          title: Text(
                            'Log out?',
                            style: TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: Text(
                            'This will clear your session and require re-login.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Log out'),
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
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nexora Audio Player  •  v1.0.0',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crafted for listeners who care',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                ref
                    .read(themeModeProvider.notifier)
                    .set(AppThemePreference.values[i]);
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
              description: _playerStyleDescription(PlayerVisualMode.values[i]),
              selected: PlayerVisualMode.values[i] == current,
              onTap: () {
                ref
                    .read(playerVisualModeProvider.notifier)
                    .set(PlayerVisualMode.values[i]);
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

  String _themeDescription(AppThemePreference pref) {
    switch (pref) {
      case AppThemePreference.light:
        return 'Bright airy tones — best in daylight.';
      case AppThemePreference.dark:
        return 'Deep navy studio — the default.';
      case AppThemePreference.system:
        return 'Follows your device setting.';
    }
  }

  IconData _playerStyleIcon(PlayerVisualMode m) {
    switch (m) {
      case PlayerVisualMode.modern:
        return Icons.album_outlined;
      case PlayerVisualMode.vinyl:
        return Icons.album_rounded;
      case PlayerVisualMode.cassette:
        return Icons.audiotrack_rounded;
      case PlayerVisualMode.minimal:
        return Icons.crop_square_rounded;
    }
  }

  String _playerStyleDescription(PlayerVisualMode m) {
    switch (m) {
      case PlayerVisualMode.modern:
        return 'Calm dark canvas with sharp square artwork.';
      case PlayerVisualMode.vinyl:
        return 'Rotating record with artwork at center.';
      case PlayerVisualMode.cassette:
        return 'Tape-inspired stage with rotating reels.';
      case PlayerVisualMode.minimal:
        return 'Only artwork and identity — pure & quiet.';
    }
  }
}

class _SectionGroup extends StatelessWidget {
  final String title;
  final Color accent;
  final List<Widget> children;

  const _SectionGroup({
    required this.title,
    required this.accent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: NexoraRadius.card,
            border: Border.all(
              color: isDark ? AppColors.border : AppColors.border,
              width: 0.7,
            ),
            boxShadow: isDark ? null : NexoraShadow.card(false),
          ),
          child: ClipRRect(
            borderRadius: NexoraRadius.card,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      color: AppColors.hairline,
                      height: 0.6,
                      thickness: 0.6,
                      indent: 56,
                      endIndent: 0,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData? icon;
  final NexoraGlyphKind? glyph;
  final Color? iconBg;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  const _SettingTile({
    this.icon,
    this.glyph,
    this.iconBg,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = iconColor ?? AppColors.textMuted;
    final bg =
        iconBg ??
        (AppColors.mode == AppThemeMode.dark
            ? AppColors.surfaceRaised
            : AppColors.surfaceRaised.withValues(alpha: 0.8));
    final isTappable = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.accent.withValues(alpha: 0.06),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (iconColor ?? AppColors.border).withValues(
                      alpha: 0.12,
                    ),
                    width: 0.7,
                  ),
                ),
                child: glyph != null
                    ? NexoraGlyph(kind: glyph!, size: 18, color: c)
                    : Icon(icon ?? Icons.settings_outlined, color: c, size: 19),
              ),
              const SizedBox(width: 13),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
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
                          fontSize: 12.5,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ] else if (showChevron && isTappable)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textFaint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final VoidCallback onPressed;
  const _DangerCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withValues(alpha: 0.08)
            : AppColors.error.withValues(alpha: 0.06),
        borderRadius: NexoraRadius.card,
        border: Border.all(
          color: AppColors.error.withValues(alpha: isDark ? 0.18 : 0.14),
          width: 0.7,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: NexoraRadius.card,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Clear session and sign out',
                        style: TextStyle(
                          color: AppColors.error.withValues(alpha: 0.70),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        boxShadow: isDark ? null : NexoraShadow.card(false),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B5BFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bedtime_rounded,
                      size: 18,
                      color: const Color(0xFF6B5BFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sleep timer',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        timer.isActive
                            ? timer.label
                            : 'Stop playback automatically',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 18),
              if (timer.isActive)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier).cancel();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancel timer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.22),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent
                : AppColors.surfaceRaised.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : AppColors.border.withValues(alpha: 0.7),
              width: selected ? 0 : 0.7,
            ),
          ),
          child: Text(
            formatSleepDuration(duration),
            style: TextStyle(
              color: selected ? Colors.white : AppColors.text,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

final _serverInfoProvider = FutureProvider(
  (ref) async => ref.watch(serverApiProvider).getServerInfo(),
);
