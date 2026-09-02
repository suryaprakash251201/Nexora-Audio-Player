import 'package:flutter/material.dart';

import '../theme.dart';

/// Playlist artwork built from the covers of the tracks it contains.
///
/// Renders a 2x2 collage when several covers are available, a single full
/// image for one, and a calm flat plate for an empty playlist.
class PlaylistCover extends StatelessWidget {
  final List<String?> artworkUrls;
  final double borderRadius;
  final String? title;
  final IconData emptyIcon;
  final double emptyIconSize;

  const PlaylistCover({
    super.key,
    required this.artworkUrls,
    this.borderRadius = 8,
    this.title,
    this.emptyIcon = Icons.queue_music_rounded,
    this.emptyIconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final urls = <String>[];
    for (final u in artworkUrls) {
      if (u != null && u.isNotEmpty) urls.add(u);
      if (urls.length >= 4) break;
    }

    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (urls.isEmpty)
            _FlatPlate(
              icon: emptyIcon,
              iconSize: emptyIconSize,
            )
          else if (urls.length == 1)
            _CoverImage(url: urls.first)
          else
            _Collage(urls: urls),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceRaised,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

/// 2x2 (or partial) mosaic of the first four track covers.
class _Collage extends StatelessWidget {
  final List<String> urls;
  const _Collage({required this.urls});

  @override
  Widget build(BuildContext context) {
    final tiles = urls.length == 3 ? urls.take(4).toList() : urls;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _CoverImage(url: tiles[0])),
              if (tiles.length > 1) ...[
                const SizedBox(width: 1.5),
                Expanded(child: _CoverImage(url: tiles[1])),
              ],
            ],
          ),
        ),
        if (tiles.length > 2) ...[
          const SizedBox(height: 1.5),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _CoverImage(url: tiles[2])),
                Expanded(
                  child: tiles.length > 3
                      ? _CoverImage(url: tiles[3])
                      : Container(color: AppColors.surfaceRaised),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Calm flat plate used for empty playlists.
class _FlatPlate extends StatelessWidget {
  final IconData icon;
  final double iconSize;

  const _FlatPlate({
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceRaised,
      child: Center(
        child: Icon(icon, color: AppColors.textDim, size: iconSize),
      ),
    );
  }
}