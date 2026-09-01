import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'enhanced_glass.dart';

// ═══════════════════════════════════════════════════════════════
// ENHANCED PLAY BUTTON — With rotating gradient ring
// ═══════════════════════════════════════════════════════════════

class EnhancedPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final bool showGlow;

  const EnhancedPlayButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 80,
    this.showGlow = true,
  });

  @override
  State<EnhancedPlayButton> createState() => _EnhancedPlayButtonState();
}

class _EnhancedPlayButtonState extends State<EnhancedPlayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
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
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: widget.showGlow
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(widget.isPlaying),
                          color: Colors.white,
                          size: widget.size * 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROTATING ALBUM ART — With spinning vinyl effect
// ═══════════════════════════════════════════════════════════════

class RotatingAlbumArt extends StatefulWidget {
  final String? imageUrl;
  final bool isPlaying;
  final double size;

  const RotatingAlbumArt({
    super.key,
    this.imageUrl,
    required this.isPlaying,
    this.size = 280,
  });

  @override
  State<RotatingAlbumArt> createState() => _RotatingAlbumArtState();
}

class _RotatingAlbumArtState extends State<RotatingAlbumArt>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant RotatingAlbumArt oldWidget) {
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
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 60,
            spreadRadius: 10,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 50,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                width: widget.size + 8,
                height: widget.size + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.secondary.withValues(alpha: 0.3),
                      AppColors.tertiary.withValues(alpha: 0.3),
                      AppColors.primary.withValues(alpha: 0.3),
                    ],
                    transform: GradientRotation(_controller.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),
          // Rotating album art
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: widget.imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(widget.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: widget.imageUrl == null
                        ? LinearGradient(
                            colors: [
                              AppColors.surfaceRaised,
                              AppColors.surfaceHigh,
                            ],
                          )
                        : null,
                  ),
                  child: widget.imageUrl == null
                      ? Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            size: widget.size * 0.3,
                            color: AppColors.textDim,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
          // Center hole (vinyl style)
          Container(
            width: widget.size * 0.15,
            height: widget.size * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(
                color: AppColors.glassBorderStrong,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENHANCED SEEK BAR — Glassmorphism slider
// ═══════════════════════════════════════════════════════════════

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

  String _formatDuration(Duration d) {
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
            trackHeight: 6,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
              elevation: 4,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VISUALIZER BARS — Audio reactive animation
// ═══════════════════════════════════════════════════════════════

class VisualizerBars extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final Color color;
  final double height;

  const VisualizerBars({
    super.key,
    required this.isPlaying,
    this.barCount = 20,
    this.color = AppColors.primary,
    this.height = 40,
  });

  @override
  State<VisualizerBars> createState() => _VisualizerBarsState();
}

class _VisualizerBarsState extends State<VisualizerBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _barHeights;

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
      builder: (context, _) {
        // Generate pseudo-random bar heights based on animation value
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
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      widget.color.withValues(alpha: 0.8),
                      widget.color.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS MINI PLAYER — Enhanced with animations
// ═══════════════════════════════════════════════════════════════

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
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: GlassCard(
          borderRadius: 22,
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: artworkUrl != null
                        ? DecorationImage(
                            image: NetworkImage(artworkUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: artworkUrl == null
                        ? LinearGradient(
                            colors: [
                              AppColors.surfaceRaised,
                              AppColors.surfaceHigh,
                            ],
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: artworkUrl == null
                      ? Icon(
                          Icons.music_note_rounded,
                          color: AppColors.textDim,
                          size: 24,
                        )
                      : null,
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: artist != null
                    ? Text(
                        artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GlassIconButton(
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: onPlayPause,
                      isActive: isPlaying,
                    ),
                    const SizedBox(width: 4),
                    _GlassIconButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: onNext,
                    ),
                    if (onDismiss != null) ...[
                      const SizedBox(width: 4),
                      _GlassIconButton(
                        icon: Icons.close_rounded,
                        onPressed: onDismiss!,
                        color: AppColors.textDim,
                      ),
                    ],
                  ],
                ),
              ),
              // Progress indicator
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.primary.withValues(alpha: 0.6),
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

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? color;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.text,
          size: 22,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ENHANCED NAVIGATION BAR — Glass floating dock
// ═══════════════════════════════════════════════════════════════

class EnhancedGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const EnhancedGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.search_outlined, Icons.search_rounded, 'Search'),
    (Icons.library_music_outlined, Icons.library_music_rounded, 'Library'),
    (Icons.queue_music_outlined, Icons.queue_music_rounded, 'Playlists'),
    (Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.glassBase.withValues(alpha: 0.7),
                  AppColors.glassBase.withValues(alpha: 0.5),
                ],
              ),
              border: Border.all(
                color: AppColors.glassBorderStrong,
                width: 0.5,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                selected ? selectedIcon : icon,
                color: selected ? AppColors.primary : AppColors.textDim,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textDim,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GLASS SONG LIST TILE
// ═══════════════════════════════════════════════════════════════

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCurrent
                ? [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.04),
                  ]
                : [
                    AppColors.glassBase.withValues(alpha: 0.3),
                    AppColors.glassBase.withValues(alpha: 0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrent
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.glassBorder,
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: artworkUrl != null
                          ? DecorationImage(
                              image: NetworkImage(artworkUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: artworkUrl == null
                          ? LinearGradient(
                              colors: [
                                AppColors.surfaceRaised,
                                AppColors.surfaceHigh,
                              ],
                            )
                          : null,
                    ),
                    child: artworkUrl == null
                        ? Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textDim,
                            size: 24,
                          )
                        : null,
                  ),
                  if (isPlaying)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _MiniVisualizer(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCurrent ? AppColors.primaryLight : AppColors.text,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: subtitle != null
                  ? Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: trailing ??
                  (onMore != null
                      ? IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.textDim,
                            size: 20,
                          ),
                          onPressed: onMore,
                        )
                      : null),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniVisualizer extends StatefulWidget {
  final Color color;

  const _MiniVisualizer({required this.color});

  @override
  State<_MiniVisualizer> createState() => _MiniVisualizerState();
}

class _MiniVisualizerState extends State<_MiniVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final h = 4 + 8 * ((math.sin(_controller.value * math.pi * 2 + i * 1.5) + 1) / 2);
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
