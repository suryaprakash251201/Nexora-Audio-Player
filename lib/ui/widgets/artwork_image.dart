import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage_service.dart';
import '../theme.dart';

/// Shared 7-day disk cache for every artwork surface (rows, covers,
/// heroes, player). This is what makes cached art survive offline —
/// plain `Image.network` never guaranteed that.
final nexoraArtworkCache = CacheManager(
  Config(
    'nexoraArtwork',
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 1500,
  ),
);

/// Provides the current bearer token for authenticated image requests.
final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  return storage.getToken();
});

class ArtworkImage extends ConsumerWidget {
  final String? url;
  final double? size;
  final double borderRadius;
  final BoxFit fit;
  final bool showShadow;
  final Color? shadowColor;

  const ArtworkImage({
    super.key,
    this.url,
    this.size,
    this.borderRadius = 6,
    this.fit = BoxFit.cover,
    this.showShadow = false,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUrl = url != null && url!.isNotEmpty && url != 'null';
    if (!hasUrl) return _fallback();

    final tokenAsync = ref.watch(authTokenProvider);

    return tokenAsync.when(
      loading: () => _fallback(isLoading: true),
      error: (_, __) => _buildImage(null),
      data: (token) => _buildImage(token),
    );
  }

  Widget _buildImage(String? token) {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final imageKey = token != null ? '$url?_auth=${token.hashCode}' : url!;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.surfaceRaised),
        child: CachedNetworkImage(
          imageUrl: url!,
          key: ValueKey(imageKey),
          fit: fit,
          httpHeaders: headers,
          cacheManager: nexoraArtworkCache,
          errorWidget: (c, e, s) => _fallback(),
          progressIndicatorBuilder: (c, u, p) => _fallback(isLoading: true),
        ),
      ),
    );

    if (!showShadow) return image;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? Colors.black).withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: image,
    );
  }

  Widget _fallback({bool isLoading = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: size != null && size! < 40 ? 14 : 20,
                height: size != null && size! < 40 ? 14 : 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textDim,
                ),
              )
            : Icon(
                Icons.music_note_rounded,
                color: AppColors.textDim,
                size: size != null && size! < 40 ? 18 : 28,
              ),
      ),
    );
  }
}
