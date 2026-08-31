import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});
  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(_playlistsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      floatingActionButton: FloatingActionButton(onPressed: _createPlaylist, backgroundColor: AppColors.primary, child: const Icon(Icons.add, color: Colors.white)),
      body: playlistsAsync.when(
        data: (list) => list.isEmpty
            ? const EmptyView(title: 'No playlists', subtitle: 'Create your first playlist', icon: Icons.queue_music)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_playlistsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (c, i) {
                    final p = list[i];
                    return ListTile(
                      leading: Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(8)), child: p.coverUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.queue_music, color: AppColors.textMuted))) : const Icon(Icons.queue_music, color: AppColors.textMuted)),
                      title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text('${p.trackCount ?? 0} tracks • ${p.description ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
                      onTap: () => context.push('/playlists/${p.id}', extra: p),
                    );
                  },
                ),
              ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(_playlistsProvider)),
      ),
    );
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (c) => AlertDialog(backgroundColor: AppColors.surface, title: const Text('New Playlist', style: TextStyle(color: Colors.white)), content: TextField(controller: controller, autofocus: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: 'Playlist name', hintStyle: const TextStyle(color: AppColors.textDim), filled: true, fillColor: AppColors.surfaceRaised, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: const Text('Create'))]));
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(playlistsRepositoryProvider).createPlaylist(name);
      ref.invalidate(_playlistsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created "$name"')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error));
    }
  }
}

final _playlistsProvider = FutureProvider((ref) async => ref.watch(playlistsRepositoryProvider).getPlaylists());
