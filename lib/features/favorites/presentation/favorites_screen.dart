import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../player/providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
      ),
      body: favAsync.when(
        data: (songs) => songs.isEmpty
            ? const EmptyView(
                title: 'No favorites yet',
                subtitle: 'Tap the heart on any song',
                icon: Icons.favorite_rounded,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_favoritesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (c, i) {
                    final s = songs[i];
                    final isCurrent =
                        ref.watch(playerProvider).currentTrack?.id == s.id;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      leading: isCurrent
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                ArtworkImage(
                                  url: s.coverUrl,
                                  size: 48,
                                  borderRadius: 10,
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: NowPlayingIndicator(
                                      height: 14,
                                      width: 14,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ArtworkImage(
                              url: s.coverUrl,
                              size: 48,
                              borderRadius: 10,
                            ),
                      title: Text(
                        s.title,
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.primaryLight
                              : Colors.white,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        s.artist ?? '',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          await ref
                              .read(favoritesRepositoryProvider)
                              .toggleFavorite(s.id, true);
                          ref.invalidate(_favoritesProvider);
                        },
                      ),
                      onTap: () => ref
                          .read(playerProvider.notifier)
                          .playSongs(songs, initialIndex: i),
                    );
                  },
                ),
              ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_favoritesProvider),
        ),
      ),
    );
  }
}

final _favoritesProvider = FutureProvider(
  (ref) async => ref.watch(favoritesRepositoryProvider).getFavorites(),
);
