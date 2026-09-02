import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_tokens.dart';

/// Square album artwork with no glow, no gradient — just the artwork at the
/// size you ask for. Falls back to a quiet charcoal tile if the URL is
/// missing or fails to load. Used everywhere in the redesign in place of
/// the rounded/glowing artwork of the previous design.
class NexoraArtwork extends StatelessWidget {
  final String? url;
  final double size;
  final BorderRadius radius;
  final IconData placeholderIcon;
  final BoxFit fit;

  const NexoraArtwork({
    super.key,
    required this.url,
    required this.size,
    this.radius = NexoraRadius.artwork,
    this.placeholderIcon = Icons.music_note_rounded,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: radius,
        child: url != null && url!.isNotEmpty
            ? Image.network(
                url!,
                width: size,
                height: size,
                fit: fit,
                errorBuilder: (_, __, ___) => _Placeholder(
                  size: size,
                  icon: placeholderIcon,
                ),
                loadingBuilder: (c, child, progress) {
                  if (progress == null) return child;
                  return _Placeholder(
                    size: size,
                    icon: placeholderIcon,
                    loading: true,
                  );
                },
              )
            : _Placeholder(size: size, icon: placeholderIcon),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
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
        color: AppColorTokens.surfaceRaised,
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: size * 0.18,
              height: size * 0.18,
              child: const CircularProgressIndicator(strokeWidth: 1.4),
            )
          : Icon(
              icon,
              size: size * 0.32,
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