import 'package:flutter/material.dart';
import '../theme.dart';

class ArtworkImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty && url != 'null';
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceRaised,
        child: hasUrl
            ? Image.network(
                url!,
                fit: fit,
                errorBuilder: (c, e, s) => _fallback(),
                loadingBuilder: (c, child, progress) {
                  if (progress == null) return child;
                  return _fallback(isLoading: true);
                },
                headers:
                    const {}, // Dio auth not needed for cached_network_image? Stream with token if needed externally
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback({bool isLoading = false}) {
    return Container(
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
