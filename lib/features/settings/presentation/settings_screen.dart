import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../../data/api/server_api.dart';
import '../../../ui/theme.dart';
import '../../../ui/theme_provider.dart';
import '../../../ui/widgets/glass_surface.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverInfo = ref.watch(_serverInfoProvider);
    final storage = ref.watch(secureStorageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
        children: [
          _settingsGroup('SERVER', [
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
          const SizedBox(height: 20),
          serverInfo.when(
            data: (info) => _settingsGroup('CONNECTION', [
              _SettingTile(
                icon: Icons.check_circle_rounded,
                iconBg: AppColors.success,
                title: '${info.name} Connected',
                subtitle: 'v${info.serverVersion} • API ${info.apiVersion}',
                trailing: _StatusPill(text: 'Online'),
              ),
            ]),
            loading: () => _settingsGroup('CONNECTION', [
              const _SettingTile(
                icon: Icons.sync_rounded,
                iconBg: AppColors.warning,
                title: 'Checking server...',
                subtitle: 'Verifying connection',
                showSpinner: true,
              ),
            ]),
            error: (e, _) => _settingsGroup('CONNECTION', [
              _SettingTile(
                icon: Icons.error_outline_rounded,
                iconBg: AppColors.error,
                title: 'Server unreachable',
                subtitle: e.toString(),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          _settingsGroup('PLAYBACK', [
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
            const _SettingTile(
              icon: Icons.timer_outlined,
              iconBg: AppColors.tertiary,
              title: 'Sleep timer',
              subtitle: 'Off',
              trailing: Switch(
                value: false,
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary,
                onChanged: null,
              ),
            ),
            const _SettingTile(
              icon: Icons.high_quality_rounded,
              iconBg: AppColors.primary,
              title: 'Audio quality',
              subtitle: 'Original (server) • No transcoding',
              trailing: _StatusPill(text: 'Hi-Res'),
            ),
          ]),
          const SizedBox(height: 20),
          _settingsGroup('APPEARANCE', [
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
          const SizedBox(height: 20),
          _settingsGroup('ABOUT', [
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
              subtitle: 'github.com/suryaprakash251201/Nexora-Audio-Player',
            ),
          ]),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text(
                    'Log out?',
                    style: TextStyle(color: AppColors.text),
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
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.15),
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Log out',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Nexora Audio Player v1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
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
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adaptive device support included',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                for (final pref in AppThemePreference.values)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _themeIcon(pref),
                      color: pref == current
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    title: Text(
                      _themeLabel(pref),
                      style: TextStyle(
                        color: pref == current
                            ? AppColors.primary
                            : AppColors.text,
                        fontWeight: pref == current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: pref == current
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).set(pref);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
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
        GlassSurface(
          opacity: 0.4,
          blur: 30,
          borderRadius: BorderRadius.circular(18),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              iconBg.withValues(alpha: 0.2),
              iconBg.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconBg.withValues(alpha: 0.15), width: 0.5),
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

final _serverInfoProvider = FutureProvider(
  (ref) async => ref.watch(serverApiProvider).getServerInfo(),
);
