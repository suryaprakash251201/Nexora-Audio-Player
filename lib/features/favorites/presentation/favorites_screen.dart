import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/bright_icons.dart';
import '../../../ui/animations/app_animations.dart';
import '../../player/providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Favorites',
          style: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.4,
          ),
        ),
      ),
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
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (c, i) {
                      final s = songs[i];
                      final isCurrent =
                          ref.watch(playerProvider).currentTrack?.id == s.id;
                      return SlideInAnimation(
                        delay: Duration(milliseconds: (i % 10) * 40),
                        child: GlassSongTile(
                          artworkUrl: s.coverUrl,
                          title: s.title,
                          subtitle: s.artist ?? '',
                          isCurrent: isCurrent,
                          isPlaying: isCurrent && ref.watch(playerProvider).isPlaying,
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .playSongs(songs, initialIndex: i),
                          trailing: BrightIconButton(
                            icon: Icons.favorite_rounded,
                            tone: BrightIconTone.pink,
                            size: 38,
                            iconSize: 20,
                            active: true,
                            onTap: () async {
                              await ref
                                  .read(favoritesRepositoryProvider)
                                  .toggleFavorite(s.id, true);
                              ref.invalidate(_favoritesProvider);
                            },
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
