import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/api/server_api.dart';
import '../../../ui/theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverInfo = ref.watch(_serverInfoProvider);
    final storage = ref.watch(secureStorageProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _section('Server'),
          FutureBuilder<String?>(
            future: storage.getServerUrl(),
            builder: (c, snap) => ListTile(
              leading: const Icon(Icons.dns, color: AppColors.primary),
              title: Text(snap.data ?? 'Not configured', style: const TextStyle(color: Colors.white)),
              subtitle: const Text('Tap to configure server URL', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
              onTap: () => context.push('/server-setup'),
            ),
          ),
          serverInfo.when(
            data: (info) => ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.textMuted),
              title: Text('${info.name} v${info.serverVersion} (${info.apiVersion})', style: const TextStyle(color: Colors.white, fontSize: 13)),
              subtitle: Text('Features: PL:${info.features.supportsPlaylists} Fav:${info.features.supportsFavorites} DL:${info.features.supportsDownloads}', style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            ),
            loading: () => const ListTile(title: Text('Checking server...', style: TextStyle(color: AppColors.textMuted))),
            error: (e, _) => ListTile(title: Text('Server info unavailable: $e', style: const TextStyle(color: AppColors.error, fontSize: 12))),
          ),
          const Divider(color: AppColors.border),
          _section('Playback'),
          ListTile(leading: const Icon(Icons.graphic_eq, color: AppColors.textMuted), title: const Text('Equalizer', style: TextStyle(color: Colors.white)), trailing: const Icon(Icons.chevron_right, color: AppColors.textDim), onTap: () => context.push('/equalizer')),
          ListTile(leading: const Icon(Icons.timer_outlined, color: AppColors.textMuted), title: const Text('Sleep timer', style: TextStyle(color: Colors.white)), subtitle: const Text('Off', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          ListTile(leading: const Icon(Icons.high_quality, color: AppColors.textMuted), title: const Text('Audio quality', style: TextStyle(color: Colors.white)), subtitle: const Text('Original (server) • No transcoding', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          const Divider(color: AppColors.border),
          _section('Appearance'),
          ListTile(leading: const Icon(Icons.dark_mode, color: AppColors.textMuted), title: const Text('Theme', style: TextStyle(color: Colors.white)), subtitle: const Text('Dark (Audiophile)', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          const Divider(color: AppColors.border),
          _section('About'),
          ListTile(leading: const Icon(Icons.shield_outlined, color: AppColors.primary), title: const Text('Nexora Audio Player', style: TextStyle(color: Colors.white)), subtitle: const Text('v1.0.0 • Flutter • Audiophile edition', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          ListTile(leading: const Icon(Icons.code, color: AppColors.textMuted), title: const Text('Open source', style: TextStyle(color: Colors.white)), subtitle: const Text('github.com/suryaprakash251201/Nexora-Audio-Player', style: TextStyle(color: AppColors.textDim, fontSize: 11))),
          const Divider(color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(backgroundColor: AppColors.surface, title: const Text('Log out?', style: TextStyle(color: Colors.white)), content: const Text('This will clear your session and require re-login.', style: TextStyle(color: AppColors.textMuted)), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out'))]));
                if (ok == true) {
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)));
}

final _serverInfoProvider = FutureProvider((ref) async => ref.watch(serverApiProvider).getServerInfo());
