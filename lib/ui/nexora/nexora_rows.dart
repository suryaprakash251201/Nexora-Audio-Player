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
  final void Function(Rect anchor)? onMoreAt;
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
    this.onMoreAt,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    // Gradient-blue selection: white text on blue gradient when current.
    // Animated so selection slides / fades instead of snapping.
    final titleColor = isCurrent ? AppColors.onSelection : AppColors.text;
    final subtitleColor = isCurrent
        ? AppColors.onSelection.withValues(alpha: 0.82)
        : AppColors.textMuted;
    final indexColor = isCurrent
        ? AppColors.onSelection.withValues(alpha: 0.90)
        : AppColors.textDim;
    final durationColor = isCurrent
        ? AppColors.onSelection.withValues(alpha: 0.85)
        : AppColors.textDim;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isCurrent ? AppColors.selectionGradient : null,
          color: isCurrent ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: isCurrent ? NexoraShadow.selection(isDark) : null,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onMore,
          splashColor: isCurrent
              ? Colors.white.withValues(alpha: 0.18)
              : AppColors.accent.withValues(alpha: 0.08),
          highlightColor: isCurrent
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NexoraSpacing.s12,
              vertical: NexoraSpacing.s8,
            ),
            child: Row(
              children: [
                // Index column (track number OR playing indicator)
                SizedBox(
                  width: 28,
                  child: isPlaying
                      ? _PulsingEqBadge(isSelected: isCurrent)
                      : Text(
                          indexLabel ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: indexColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
                const SizedBox(width: NexoraSpacing.s12),
                // Artwork
                NexoraArtwork(
                  url: artworkUrl,
                  size: 48,
                  radius: const BorderRadius.all(Radius.circular(12)),
                ),
                const SizedBox(width: NexoraSpacing.s12),
                // Identity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12.5,
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
                      color: isCurrent
                          ? AppColors.onSelection
                          : AppColors.accent,
                    ),
                  ),
                if (isDownloaded)
                  Padding(
                    padding: const EdgeInsets.only(left: NexoraSpacing.s8),
                    child: Icon(
                      Icons.download_done_rounded,
                      size: 14,
                      color: isCurrent
                          ? AppColors.onSelection.withValues(alpha: 0.90)
                          : AppColors.success,
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
                        color: durationColor,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                if ((onMore != null || onMoreAt != null) && trailing == null)
                  Builder(
                    builder: (btnContext) => SizedBox(
                      width: 36,
                      child: IconButton(
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: isCurrent
                              ? AppColors.onSelection.withValues(alpha: 0.90)
                              : AppColors.textDim,
                        ),
                        onPressed: () {
                          // Prefer the anchored mini menu; fall back to the
                          // legacy callback when no anchor handler is set.
                          if (onMoreAt != null) {
                            final box =
                                btnContext.findRenderObject() as RenderBox?;
                            if (box != null && box.hasSize) {
                              final pos = box.localToGlobal(Offset.zero);
                              onMoreAt!(
                                Rect.fromLTWH(
                                  pos.dx,
                                  pos.dy,
                                  box.size.width,
                                  box.size.height,
                                ),
                              );
                              return;
                            }
                          }
                          onMore?.call();
                        },
                        tooltip: 'More',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing equalizer badge for the currently playing row.
/// Glassy white pill on blue selection, blue tint otherwise,
/// with a breathing scale animation while playing.
class _PulsingEqBadge extends StatefulWidget {
  final bool isSelected;
  const _PulsingEqBadge({required this.isSelected});

  @override
  State<_PulsingEqBadge> createState() => _PulsingEqBadgeState();
}

class _PulsingEqBadgeState extends State<_PulsingEqBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final pulse = 0.92 + (_c.value * 0.08);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? Colors.white.withValues(alpha: 0.22 + _c.value * 0.08)
                  : AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected
                    ? Colors.white.withValues(alpha: 0.35)
                    : AppColors.accent.withValues(alpha: 0.25),
                width: 0.7,
              ),
            ),
            child: Icon(
              Icons.equalizer_rounded,
              size: 14,
              color: widget.isSelected
                  ? AppColors.onSelection
                  : AppColors.accent,
            ),
          ),
        );
      },
    );
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
