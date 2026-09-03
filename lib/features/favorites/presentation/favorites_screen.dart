import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/enhanced_glass.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

/// Favorites — audiophile redesign.
///
/// Large header with count, tracks inside a contained card with hairlines,
/// each row shows artwork + title + artist + duration + favorite button.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(_favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        toolbarHeight: 64,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Favorites',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
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
            : Column(
                children: [
                  // Count header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Text(
                          'TRACKS',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            songs.length.toString(),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${formatDuration(_totalDuration(songs))} total',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 11.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.accent,
                      backgroundColor: AppColors.card,
                      onRefresh: () async => ref.invalidate(_favoritesProvider),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: NexoraRadius.card,
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.7,
                          ),
                          boxShadow: AppColors.mode == AppThemeMode.dark
                              ? null
                              : NexoraShadow.card(false),
                        ),
                        child: ClipRRect(
                          borderRadius: NexoraRadius.card,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: songs.length,
                            separatorBuilder: (_, __) =>
                                const NexoraDivider(indent: 64, endIndent: 0),
                            itemBuilder: (c, i) {
                              final s = songs[i];
                              final isCurrent =
                                  ref.watch(playerProvider).currentTrack?.id ==
                                  s.id;
                              return InkWell(
                                onTap: () => ref
                                    .read(playerProvider.notifier)
                                    .playSongs(songs, initialIndex: i),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      // Artwork
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          color: AppColors.surfaceRaised,
                                          image: s.coverUrl != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    s.coverUrl!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: s.coverUrl == null
                                            ? Icon(
                                                Icons.music_note_rounded,
                                                color: AppColors.textDim,
                                                size: 20,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      // Title + artist
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${s.artist ?? 'Unknown'} • ${formatDuration(s.durationDuration)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Favorite button
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(_favoritesProvider),
        ),
      ),
    );
  }

  Duration _totalDuration(List songs) {
    return songs.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.durationDuration,
    );
  }
}

final _favoritesProvider = FutureProvider(
  (ref) async => ref.watch(favoritesRepositoryProvider).getFavorites(),
);
