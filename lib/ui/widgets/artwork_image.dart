import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage_service.dart';
import '../theme.dart';

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

  const ArtworkImage({
    super.key,
    this.url,
    this.size,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
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

    // Include token in key so NetworkImage cache is invalidated when token changes
    final imageKey = token != null ? '$url?_auth=${token.hashCode}' : url!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceRaised,
        child: Image.network(
          url!,
          key: ValueKey(imageKey),
          fit: fit,
          headers: headers,
          errorBuilder: (c, e, s) => _fallback(),
          loadingBuilder: (c, child, progress) {
            if (progress == null) return child;
            return _fallback(isLoading: true);
          },
        ),
      ),
    );
  }

  Widget _fallback({bool isLoading = false}) {
    return Container(
      width: size,
      height: size,
      color: AppColors.surfaceRaised,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              )
            : const Icon(
                Icons.music_note,
                color: AppColors.textMuted,
                size: 32,
              ),
      ),
    );
  }
}
