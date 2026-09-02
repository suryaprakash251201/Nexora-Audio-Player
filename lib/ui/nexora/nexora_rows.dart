import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_artwork.dart';
import 'nexora_tokens.dart';
import 'nexora_primitives.dart';

/// Compact track row used in library, queue, history, favorites, search
/// results, playlist detail, and album detail.
///
/// Visually minimal: track number on the left, square artwork next to it,
/// title + artist/album under it, optional trailing slot, optional
/// context menu. Separators are hairlines, not full cards.
class NexoraTrackRow extends StatelessWidget {
  final String? artworkUrl;
  final String title;
  final String? subtitle;
  final String? duration;
  final String? indexLabel;
  final bool isCurrent;
  final bool isPlaying;
  final bool isFavorite;
  final bool isDownloaded;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final Widget? trailing;

  const NexoraTrackRow({
    super.key,
    required this.artworkUrl,
    required this.title,
    this.subtitle,
    this.duration,
    this.indexLabel,
    this.isCurrent = false,
    this.isPlaying = false,
    this.isFavorite = false,
    this.isDownloaded = false,
    this.onTap,
    this.onMore,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isCurrent ? AppColors.accent : AppColors.text;
    final row = InkWell(
      onTap: onTap,
      onLongPress: onMore,
      splashColor: AppColors.surfaceHigh.withValues(alpha: 0.35),
      highlightColor: AppColors.surfaceHigh.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.s20,
          vertical: NexoraSpacing.s8,
        ),
        child: Row(
          children: [
            // Index column (track number OR playing indicator)
            SizedBox(
              width: 28,
              child: isPlaying
                  ? Icon(
                      Icons.equalizer_rounded,
                      size: 16,
                      color: AppColors.accent,
                    )
                  : indexLabel != null
                  ? Text(
                      indexLabel!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCurrent ? AppColors.accent : AppColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: NexoraSpacing.s12),
            // Artwork
            NexoraArtwork(
              url: artworkUrl,
              size: 44,
              radius: const BorderRadius.all(Radius.circular(NexoraRadius.r4)),
            ),
            const SizedBox(width: NexoraSpacing.s12),
            // Identity
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Quality / favorite indicators
            if (isFavorite)
              Padding(
                padding: const EdgeInsets.only(left: NexoraSpacing.s8),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
              ),
            if (isDownloaded)
              Padding(
                padding: const EdgeInsets.only(left: NexoraSpacing.s8),
                child: Icon(
                  Icons.download_done_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
              ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: NexoraSpacing.s8),
                child: trailing!,
              ),
            // Duration + context menu
            if (duration != null)
              SizedBox(
                width: 42,
                child: Text(
                  duration!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            if (onMore != null && trailing == null)
              SizedBox(
                width: 36,
                child: IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: AppColors.textDim,
                  ),
                  onPressed: onMore,
                  tooltip: 'More',
                ),
              ),
          ],
        ),
      ),
    );
    return row;
  }
}

/// Album grid card. Square artwork + title + artist. Used in library,
/// search results, and artist pages.
class NexoraAlbumCard extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double size;

  const NexoraAlbumCard({
    super.key,
    required this.coverUrl,
    required this.title,
    this.subtitle,
    this.onTap,
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: onTap,
      scale: 0.98,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NexoraArtwork(url: coverUrl, size: size),
            const SizedBox(height: NexoraSpacing.s12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Artist line — square avatar + name + album count.
class NexoraArtistRow extends StatelessWidget {
  final String? artworkUrl;
  final String name;
  final String? subtitle;
  final VoidCallback? onTap;

  const NexoraArtistRow({
    super.key,
    required this.artworkUrl,
    required this.name,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.s20,
          vertical: NexoraSpacing.s12,
        ),
        child: Row(
          children: [
            ClipOval(
              child: NexoraArtwork(
                url: artworkUrl,
                size: 52,
                radius: BorderRadius.zero,
                placeholderIcon: Icons.person_rounded,
              ),
            ),
            const SizedBox(width: NexoraSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textDim,
            ),
          ],
        ),
      ),
    );
  }
}
