import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../player/providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favAsync.when(
        data: (songs) => songs.isEmpty
            ? const EmptyView(title: 'No favorites yet', subtitle: 'Tap the heart on any song', icon: Icons.favorite_border)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_favoritesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (c, i) {
                    final s = songs[i];
                    return ListTile(
                      leading: ArtworkImage(url: s.coverUrl, size: 48, borderRadius: 8),
                      title: Text(s.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(s.artist ?? '', style: const TextStyle(color: AppColors.textMuted)),
                      trailing: IconButton(icon: const Icon(Icons.favorite, color: AppColors.error), onPressed: () async {
                        await ref.read(favoritesRepositoryProvider).toggleFavorite(s.id, true);
                        ref.invalidate(_favoritesProvider);
                      }),
                      onTap: () => ref.read(playerProvider.notifier).playSongs(songs, initialIndex: i),
                    );
                  },
                ),
              ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(_favoritesProvider)),
      ),
    );
  }
}

final _favoritesProvider = FutureProvider((ref) async => ref.watch(favoritesRepositoryProvider).getFavorites());
