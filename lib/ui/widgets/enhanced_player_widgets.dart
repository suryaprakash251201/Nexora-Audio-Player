import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Hi-Fi primary play/pause button. Single accent fill, calm press scale.
class EnhancedPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final bool showGlow;

  const EnhancedPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 72,
    this.showGlow = false,
  });

  @override
  State<EnhancedPlayButton> createState() => _EnhancedPlayButtonState();
}

class _EnhancedPlayButtonState extends State<EnhancedPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                widget.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                key: ValueKey(widget.isPlaying),
                color: AppColors.onAccent,
                size: widget.size * 0.46,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Album artwork that rotates gently when playing. Square by default — the
/// Hi-Fi redesign keeps album artwork crisp and square rather than the
/// circular treatment used in the previous design.
class RotatingAlbumArt extends StatefulWidget {
  final String? imageUrl;
  final bool isPlaying;
  final double size;
  final double borderRadius;

  const RotatingAlbumArt({
    super.key,
    this.imageUrl,
    required this.isPlaying,
    this.size = 280,
    this.borderRadius = 8,
  });

  @override
  State<RotatingAlbumArt> createState() => _RotatingAlbumArtState();
}

class _RotatingAlbumArtState extends State<RotatingAlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RotatingAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: AppColors.surfaceRaised,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: radius,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                return Transform.scale(
                  scale: widget.isPlaying
                      ? 1.0 +
                          0.012 *
                              math.sin(_controller.value * 2 * math.pi)
                      : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      image: widget.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: widget.imageUrl == null
                        ? Icon(
                            Icons.music_note_rounded,
                            size: widget.size * 0.3,
                            color: AppColors.textDim,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Audiophile seek bar: thin track, hairline thumb, tabular numerals.
class EnhancedSeekBar extends StatelessWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  const EnhancedSeekBar({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: AppColors.text,
            inactiveTrackColor: AppColors.surfaceHigh,
            thumbColor: AppColors.text,
            overlayColor: AppColors.accent.withValues(alpha: 0.10),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: onChanged,
            onChangeStart: onChangeStart,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(position),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                _format(duration),
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Equalizer-style animated bars — replaced with a calm still indicator.
/// (Preserved as a public class for compatibility; pulses gently only when
/// the user has it as the active visualizer.)
class VisualizerBars extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final Color color;
  final double height;

  const VisualizerBars({
    super.key,
    required this.isPlaying,
    this.barCount = 20,
    this.color = AppColors.accent,
    this.height = 40,
  });

  @override
  State<VisualizerBars> createState() => _VisualizerBarsState();
}

class _VisualizerBarsState extends State<VisualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _barHeights;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _barHeights = List.filled(widget.barCount, 0.3);
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant VisualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        for (var i = 0; i < widget.barCount; i++) {
          final phase = _controller.value * math.pi * 4 + i * 0.5;
          _barHeights[i] = widget.isPlaying
              ? 0.2 + 0.8 * ((math.sin(phase) + 1) / 2)
              : 0.1;
        }
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (i) {
              return Container(
                width: 3,
                height: widget.height * _barHeights[i],
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: AppColors.accent.withValues(alpha: 0.7),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Hi-Fi mini player: calm, album-first, tactile controls.
class GlassMiniPlayer extends StatelessWidget {
  final String? artworkUrl;
  final String title;
  final String? artist;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback? onDismiss;

  const GlassMiniPlayer({
    super.key,
    this.artworkUrl,
    required this.title,
    this.artist,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                child: Row(
                  children: [
                    // Square artwork with hairline rim.
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        image: artworkUrl != null
                            ? DecorationImage(
                                image: NetworkImage(artworkUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: AppColors.surfaceRaised,
                      ),
                      child: artworkUrl == null
                          ? Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textDim,
                            size: 20,
                          )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (artist != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              artist!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _MiniIconButton(
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: onPlayPause,
                      accent: true,
                    ),
                    const SizedBox(width: 2),
                    _MiniIconButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: onNext,
                    ),
                    if (onDismiss != null) ...[
                      const SizedBox(width: 2),
                      _MiniIconButton(
                        icon: Icons.close_rounded,
                        onPressed: onDismiss!,
                      ),
                    ],
                  ],
                ),
              ),
              // Thin progress line
              Container(
                height: 2,
                color: AppColors.surfaceHigh,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(color: AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isAccent;

  const _MiniIconButton({
    required this.icon,
    required this.onPressed,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isAccent ? AppColors.accent : AppColors.text,
        ),
      ),
    );
  }
}

/// Hi-Fi navigation bar — flat dock, hairline borders, accent for selection.
class EnhancedGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const EnhancedGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const double height = 60;
  static const double bottomMargin = 6;
  static const double totalHeight = height + bottomMargin;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.search_outlined, Icons.search_rounded, 'Search'),
    (
      Icons.library_music_outlined,
      Icons.library_music_rounded,
      'Library',
    ),
    (
      Icons.queue_music_outlined,
      Icons.queue_music_rounded,
      'Playlists',
    ),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, bottomMargin),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_destinations.length, (i) {
            final (icon, selIcon, label) = _destinations[i];
            final selected = i == selectedIndex;
            return _NavItem(
              icon: icon,
              selectedIcon: selIcon,
              label: label,
              selected: selected,
              onTap: () => onSelect(i),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textDim;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Editorial track row used across lists. Subtle separators, no glass.
class GlassSongTile extends StatelessWidget {
  final String? artworkUrl;
  final String title;
  final String? subtitle;
  final bool isPlaying;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final Widget? trailing;

  const GlassSongTile({
    super.key,
    this.artworkUrl,
    required this.title,
    this.subtitle,
    this.isPlaying = false,
    this.isCurrent = false,
    required this.onTap,
    this.onMore,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrent ? AppColors.accent : AppColors.text;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.hairline, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: artworkUrl != null
                          ? DecorationImage(
                              image: NetworkImage(artworkUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: AppColors.surfaceRaised,
                    ),
                    child: artworkUrl == null
                        ? Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textDim,
                            size: 20,
                          )
                        : null,
                  ),
                  if (isPlaying)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: _MiniBars(color: AppColors.accent),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                      color: textColor,
                      fontSize: 15,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onMore != null)
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textDim,
                  size: 20,
                ),
                onPressed: onMore,
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniBars extends StatefulWidget {
  final Color color;
  const _MiniBars({required this.color});

  @override
  State<_MiniBars> createState() => _MiniBarsState();
}

class _MiniBarsState extends State<_MiniBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final h =
                4 +
                    8 *
                        ((math.sin(_controller.value * math.pi * 2 +
                                i * 1.5) +
                            1) /
                        2);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}