import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'bright_icons.dart';

/// Playlist artwork built from the covers of the tracks it contains.
///
/// Renders a 2x2 collage when several covers are available, a single full-bleed
/// image for one, and a deterministic gradient plate for an empty playlist —
/// so every playlist gets a distinct, designed cover instead of a grey box.
class PlaylistCover extends StatelessWidget {
  final List<String?> artworkUrls;
  final double borderRadius;
  final String? title;
  final IconData emptyIcon;
  final double emptyIconSize;

  const PlaylistCover({
    super.key,
    required this.artworkUrls,
    this.borderRadius = 18,
    this.title,
    this.emptyIcon = Icons.queue_music_rounded,
    this.emptyIconSize = 34,
  });

  /// Deterministic gradient so a given playlist always looks the same.
  List<Color> get _plateColors {
    final tones = [
      BrightIconTone.violet,
      BrightIconTone.cyan,
      BrightIconTone.pink,
      BrightIconTone.emerald,
      BrightIconTone.amber,
      BrightIconTone.sky,
    ];
    final key = (title ?? 'nexora').trim().toLowerCase();
    final hash = key.isEmpty
        ? 0
        : key.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7FFFFFFF);
    final tone = tones[hash % tones.length];
    return tone.stops;
  }

  @override
  Widget build(BuildContext context) {
    // Collect up to four usable covers without needing casts or assertions.
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
            _GradientPlate(
              colors: _plateColors,
              icon: emptyIcon,
              iconSize: emptyIconSize,
            )
          else if (urls.length == 1)
            _CoverImage(url: urls.first)
          else
            _Collage(urls: urls),
          // Glass sheen + hairline border to match the design system.
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 0.7,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.18),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surfaceRaised, AppColors.surfaceHigh],
          ),
        ),
        child: const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}

/// 2x2 (or 1x2 / 2x1) mosaic of the first four track covers.
class _Collage extends StatelessWidget {
  final List<String> urls;
  const _Collage({required this.urls});

  @override
  Widget build(BuildContext context) {
    // 2 or 3 covers still fill a balanced mosaic.
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
                      : _GradientPlate(
                          colors: [
                            AppColors.surfaceRaised,
                            AppColors.surfaceHigh,
                          ],
                          icon: Icons.music_note_rounded,
                          iconSize: 18,
                          showBlur: false,
                        ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Gradient plate used for empty playlists (and as a mosaic filler).
class _GradientPlate extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final double iconSize;
  final bool showBlur;

  const _GradientPlate({
    required this.colors,
    required this.icon,
    required this.iconSize,
    this.showBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.first.withValues(alpha: 0.85),
            colors.last.withValues(alpha: 0.45),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft corner bloom for depth.
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (showBlur)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const SizedBox.expand(),
            ),
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: iconSize),
        ],
      ),
    );
  }
}
