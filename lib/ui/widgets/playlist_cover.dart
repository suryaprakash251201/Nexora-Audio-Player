import 'package:flutter/material.dart';

import '../theme.dart';

/// Playlist artwork — the FIRST available cover rendered as the actual
/// full-bleed cover photo (callers put the server cover first, then track
/// art), or a calm flat plate when the playlist has no art at all.
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
    String? first;
    for (final u in artworkUrls) {
      if (u != null && u.isNotEmpty) {
        first = u;
        break;
      }
    }

    final radius = BorderRadius.circular(borderRadius);

    return ClipRRect(
      borderRadius: radius,
      child: first == null
          ? _FlatPlate(icon: emptyIcon, iconSize: emptyIconSize)
          : _CoverImage(url: first),
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
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: AppColors.textDim),
        ),
      ),
    );
  }
}

/// Calm flat plate used for empty playlists.
class _FlatPlate extends StatelessWidget {
  final IconData icon;
  final double iconSize;

  const _FlatPlate({required this.icon, required this.iconSize});

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
