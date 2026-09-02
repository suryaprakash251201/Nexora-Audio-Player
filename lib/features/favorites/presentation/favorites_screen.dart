import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Favorites',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ),
      body: favAsync.when(
        data: (songs) => songs.isEmpty
            ? const EmptyView(
                title: 'No favorites yet',
                subtitle: 'Tap the heart on any song to add it here',
                icon: Icons.favorite_border_rounded,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(_favoritesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 140),
                  itemCount: songs.length,
                  itemBuilder: (c, i) {
                    final s = songs[i];
                    final isCurrent =
                        ref.watch(playerProvider).currentTrack?.id == s.id;
                    return InkWell(
                      onTap: () => ref
                          .read(playerProvider.notifier)
                          .playSongs(songs, initialIndex: i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.hairline,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: AppColors.surfaceRaised,
                                image: s.coverUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(s.coverUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: s.coverUrl == null
                                  ? const Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.textDim,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? AppColors.accent
                                          : AppColors.text,
                                      fontSize: 15,
                                      fontWeight: isCurrent
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.artist ?? 'Unknown'} • ${formatDuration(s.durationDuration)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(favoritesRepositoryProvider)
                                    .toggleFavorite(s.id, true);
                                ref.invalidate(_favoritesProvider);
                              },
                            ),
                          ],
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
    );
  }
}

final _favoritesProvider = FutureProvider(
  (ref) async => ref.watch(favoritesRepositoryProvider).getFavorites(),
);