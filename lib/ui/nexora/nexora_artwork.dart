import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/artwork_image.dart' show nexoraArtworkCache;
import 'file_artwork_image.dart';
import 'nexora_tokens.dart';

/// Modern album artwork — soft 14px radius, hairline rim, layered shadow.
/// Falls back to an aurora-tinted tile if the URL is missing or fails.
/// Used everywhere in the 2.0 redesign.
class NexoraArtwork extends StatelessWidget {
  final String? url;
  final double? size;
  final BorderRadius radius;
  final IconData placeholderIcon;
  final BoxFit fit;
  final bool showShadow;

  const NexoraArtwork({
    super.key,
    required this.url,
    this.size,
    this.radius = NexoraRadius.artwork,
    this.placeholderIcon = Icons.music_note_rounded,
    this.fit = BoxFit.cover,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(borderRadius: radius, child: _image()),
    );
  }

  Widget _image() {
    if (url == null || url!.isEmpty) {
      return _Placeholder(size: size, icon: placeholderIcon);
    }
    // On-disk artwork (e.g. cached on-device song covers): render via
    // Image.file so file:// URIs work on every native platform.
    // Everything else keeps the shared HTTP disk cache.
    if (isFileArtworkUri(url)) {
      return buildFileArtworkImage(
        url: url!,
        width: size,
        height: size,
        fit: fit,
        errorWidget: _Placeholder(size: size, icon: placeholderIcon),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      width: size,
      height: size,
      fit: fit,
      cacheManager: nexoraArtworkCache,
      errorWidget: (_, __, ___) =>
          _Placeholder(size: size, icon: placeholderIcon),
      progressIndicatorBuilder: (c, u, p) =>
          _Placeholder(size: size, icon: placeholderIcon, loading: true),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double? size;
  final IconData icon;
  final bool loading;
  const _Placeholder({
    required this.size,
    required this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.22),
            AppColors.accentCyan.withValues(alpha: 0.10),
            AppColorTokens.surfaceRaised,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: (size ?? 48) * 0.18,
              height: (size ?? 48) * 0.18,
              child: const CircularProgressIndicator(strokeWidth: 1.6),
            )
          : Icon(
              icon,
              size: (size ?? 48) * 0.32,
              color: AppColorTokens.textDim,
            ),
    );
  }
}

/// Internal color aliases used by the new widgets. These forward to the
/// existing [AppColors] getters — they're not const because the getters
/// themselves are not const (they switch on [AppColors.mode]).
class AppColorTokens {
  AppColorTokens._();
  static Color get surfaceRaised => AppColors.surfaceRaised;
  static Color get textDim => AppColors.textDim;
}
