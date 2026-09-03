import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nexora/nexora_glass.dart';
import '../theme.dart';
import 'waveform_visualizer.dart';

/// Hi-Fi primary play/pause button. Single accent fill, calm press scale.
/// Enhanced with optional breathing glow effect.
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
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.isPlaying && widget.showGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EnhancedPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && widget.showGlow) {
      if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
    } else {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    Widget button = GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
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
            gradient: AppColors.accentGradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.42),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.18),
                blurRadius: 48,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) {
                return ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
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

    if (widget.showGlow && widget.isPlaying) {
      button = AnimatedBuilder(
        animation: _glowController,
        builder: (_, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(
                    alpha: 0.15 * _glowController.value,
                  ),
                  blurRadius: 30 + 20 * _glowController.value,
                  spreadRadius: 4 * _glowController.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: button,
      );
    }

    return button;
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
                      ? 1.0 + 0.012 * math.sin(_controller.value * 2 * math.pi)
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
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFeatures: [FontFeature.tabularFigures()],
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                _format(duration),
                style: TextStyle(
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
                            style: TextStyle(
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
                              style: TextStyle(
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
                      isAccent: true,
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
        icon: Icon(icon, color: isAccent ? AppColors.accent : AppColors.text),
      ),
    );
  }
}

/// Bottom navigation bar — floating aurora pill, pixel-perfect.
/// Pill tracks Expanded cells exactly (no spaceAround drift),
/// floats with 14px margins, and slides with easeOutCubic.
/// 2.0: gradient selected pill, tonal icons, 28px dock radius.
class EnhancedGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const EnhancedGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const double height = 68;
  static const double bottomMargin = 12;
  static const double totalHeight = height + bottomMargin;

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.search_outlined, Icons.search_rounded, 'Search'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'Library'),
    (Icons.queue_music_outlined, Icons.queue_music_rounded, 'Playlists'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Semantics(
      label: 'Main navigation',
      child: NexoraGlassDock(
        // Outer _IosGlassNav already pads + frosts — keep inner flush
        // so Home/Search/Library sit right on the bottom edge.
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: height - 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = _destinations.length;
              final itemWidth = constraints.maxWidth / count;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    left: selectedIndex * itemWidth + 6,
                    right: (count - 1 - selectedIndex) * itemWidth + 6,
                    top: 2,
                    bottom: 2,
                    child: const _SelectedPill(),
                  ),
                  Row(
                    children: List.generate(count, (i) {
                      final (icon, selIcon, label) = _destinations[i];
                      return Expanded(
                        child: _NavItem(
                          icon: icon,
                          selectedIcon: selIcon,
                          label: label,
                          selected: i == selectedIndex,
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onSelect(i);
                          },
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Refined pill — unified gradient-blue selection, same pattern as
/// library rows, tabs and buttons. Animated glow while selected.
class _SelectedPill extends StatelessWidget {
  const _SelectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.selectionGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.30),
            blurRadius: 18,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: AppColors.accentCyan.withValues(alpha: 0.14),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    this.isDark = true,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
    if (v) {
      _pressCtrl.forward();
    } else {
      _pressCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solid gradient-blue pill → white icon + label when selected,
    // same pattern as library rows and tabs.
    final color = widget.selected
        ? Colors.white
        : (widget.isDark ? AppColors.textDim : AppColors.textMuted);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, child) {
          final t = _pressCtrl.value;
          final scale = 1.0 - 0.07 * Curves.easeOutCubic.transform(t);
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(
                  widget.selected ? widget.selectedIcon : widget.icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: widget.selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional convenience for code that wants to drive a spring
/// directly. Exposed so other places (e.g. mini-player expand) can
/// reuse the same motion language.
class SpringSimulationConfig {
  static const SpringDescription standard = SpringDescription(
    mass: 1.0,
    stiffness: 240.0,
    damping: 22.0,
  );
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
    final isDark = AppColors.mode == AppThemeMode.dark;
    final textColor = isCurrent ? AppColors.onSelection : AppColors.text;
    final subColor = isCurrent
        ? AppColors.onSelection.withValues(alpha: 0.82)
        : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isCurrent ? AppColors.selectionGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(
                      alpha: isDark ? 0.35 : 0.24,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                        borderRadius: BorderRadius.circular(12),
                        image: artworkUrl != null
                            ? DecorationImage(
                                image: NetworkImage(artworkUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: isCurrent
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.surfaceRaised,
                      ),
                      child: artworkUrl == null
                          ? Icon(
                              Icons.music_note_rounded,
                              color: isCurrent
                                  ? AppColors.onSelection
                                  : AppColors.textDim,
                              size: 20,
                            )
                          : null,
                    ),
                    if (isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _MiniBars(
                            color: isCurrent
                                ? AppColors.onSelection
                                : AppColors.accent,
                          ),
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
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
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
                          color: subColor,
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
                    color: isCurrent
                        ? AppColors.onSelection.withValues(alpha: 0.90)
                        : AppColors.textDim,
                    size: 20,
                  ),
                  onPressed: onMore,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium animated icon button with scale and glow effects.
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final bool isActive;
  final bool showGlow;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.color,
    this.isActive = false,
    this.showGlow = false,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppColors.durFast, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? (widget.isActive ? AppColors.accent : AppColors.text);

    Widget button = GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Icon(widget.icon, color: color, size: widget.size),
      ),
    );

    if (widget.showGlow && widget.isActive) {
      button = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: button,
      );
    }

    return button;
  }
}

/// A premium volume slider with custom thumb and track styling.
class PremiumVolumeSlider extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const PremiumVolumeSlider({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          volume == 0
              ? Icons.volume_off_rounded
              : volume < 0.5
              ? Icons.volume_down_rounded
              : Icons.volume_up_rounded,
          color: AppColors.textMuted,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHigh,
              thumbColor: AppColors.text,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(value: volume.clamp(0.0, 1.0), onChanged: onChanged),
          ),
        ),
      ],
    );
  }
}

/// A premium audio quality badge showing bitrate/format info.
class AudioQualityBadge extends StatelessWidget {
  final String format;
  final int? bitrate;
  final bool isHiRes;

  const AudioQualityBadge({
    super.key,
    required this.format,
    this.bitrate,
    this.isHiRes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHiRes
            ? AppColors.accent.withValues(alpha: 0.15)
            : AppColors.surfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHiRes
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHiRes) ...[
            Icon(Icons.high_quality_rounded, color: AppColors.accent, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            bitrate != null ? '$format ${bitrate! ~/ 1000}kbps' : format,
            style: TextStyle(
              color: isHiRes ? AppColors.accent : AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium feature card for the home screen with hover effects.
class PremiumFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const PremiumFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor,
    this.onTap,
  });

  @override
  State<PremiumFeatureCard> createState() => _PremiumFeatureCardState();
}

class _PremiumFeatureCardState extends State<PremiumFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppColors.durFast, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.accentColor ?? AppColors.accent;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.3),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: accentColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact animated equalizer bars used as a compact "now playing" indicator.
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
                    ((math.sin(_controller.value * math.pi * 2 + i * 1.5) + 1) /
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
