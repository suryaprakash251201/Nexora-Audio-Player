import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/animations/app_animations.dart';
import '../../player/providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AuroraBackground(
        child: favAsync.when(
          data: (songs) => songs.isEmpty
              ? const EmptyView(
                  title: 'No favorites yet',
                  subtitle: 'Tap the heart on any song',
                  icon: Icons.favorite_rounded,
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(_favoritesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 140),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (c, i) {
                      final s = songs[i];
                      final isCurrent =
                          ref.watch(playerProvider).currentTrack?.id == s.id;
                      return SlideInAnimation(
                        delay: Duration(milliseconds: (i % 10) * 50),
                        child: GlassSongTile(
                          artworkUrl: s.coverUrl,
                          title: s.title,
                          subtitle: s.artist ?? '',
                          isCurrent: isCurrent,
                          isPlaying: isCurrent && ref.watch(playerProvider).isPlaying,
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .playSongs(songs, initialIndex: i),
                          trailing: GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(favoritesRepositoryProvider)
                                  .toggleFavorite(s.id, true);
                              ref.invalidate(_favoritesProvider);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.error.withValues(alpha: 0.12),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
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
      ),
    );
  }
}

final _favoritesProvider = FutureProvider(
  (ref) async => ref.watch(favoritesRepositoryProvider).getFavorites(),
);
