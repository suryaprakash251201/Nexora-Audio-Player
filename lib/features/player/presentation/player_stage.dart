import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/animated_cover.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/vinyl_disc.dart';
import 'cassette_player.dart';

/// #4 — artwork stage switch. Previously `mode` was watched but never
/// used, so changing style did nothing. Now every mode renders.
class ArtworkStage extends StatelessWidget {
  final PlayerVisualMode mode;
  final MediaItem track;
  final bool isPlaying;
  final double artworkSize;
  final Gradient gradient;

  const ArtworkStage({
    super.key,
    required this.mode,
    required this.track,
    required this.isPlaying,
    required this.artworkSize,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case PlayerVisualMode.vinyl:
        // Caption box removed — clean disc only.
        return VinylDisc(
          artworkUrl: track.artUri?.toString(),
          isPlaying: isPlaying,
          size: artworkSize,
        );
      case PlayerVisualMode.cassette:
        // Caption box removed — deck only.
        return SizedBox(
          width: artworkSize + 40,
          child: CassettePlayer(
            isPlaying: isPlaying,
            artworkUrl: track.artUri?.toString(),
          ),
        );
      case PlayerVisualMode.minimal:
        // Caption box removed — artwork only.
        return Container(
          width: artworkSize * 0.62,
          height: artworkSize * 0.62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ArtworkImage(
              url: track.artUri?.toString(),
              borderRadius: 0,
              fit: BoxFit.cover,
            ),
          ),
        );
      case PlayerVisualMode.modern:
        // Caption box removed — glowing cover only.
        return ModernGlowFrame(
          gradient: gradient,
          isPlaying: isPlaying,
          child: AnimatedAlbumCover(
            imageUrl: track.artUri?.toString(),
            isPlaying: isPlaying,
            size: artworkSize,
            borderRadius: 24,
          ),
        );
    }
  }
}

/// Modern signature frame — animated breathing gradient border + glow.
/// Gives the locked (non-scroll) modern stage its living feel.
class ModernGlowFrame extends StatefulWidget {
  final Gradient gradient;
  final bool isPlaying;
  final Widget child;
  const ModernGlowFrame({
    required this.gradient,
    required this.isPlaying,
    required this.child,
  });

  @override
  State<ModernGlowFrame> createState() => _ModernGlowFrameState();
}

class _ModernGlowFrameState extends State<ModernGlowFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
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
        final t = _c.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: widget.gradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.30 + t * 0.18),
                blurRadius: 36 + t * 22,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.14 + t * 0.12),
                blurRadius: 60 + t * 26,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(2.5 + t * 1.2),
          child: widget.child,
        );
      },
    );
  }
}

/// Top bar — no rounded pill. Centered NEXORA wordmark, plain text.
/// Top bar — close left, style right, NEXORA dead-center.
/// Sleep lives in the bottom dock, so it is not duplicated here. Both
/// sides are a single 48px IconButton, so the wordmark centers exactly.
