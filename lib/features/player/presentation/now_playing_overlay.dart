import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/glass_surface.dart';
import '../../../core/utils/formatters.dart';
import '../providers/player_provider.dart';

class NowPlayingOverlay extends ConsumerStatefulWidget {
  const NowPlayingOverlay({super.key});

  @override
  ConsumerState<NowPlayingOverlay> createState() => _NowPlayingOverlayState();
}

class _NowPlayingOverlayState extends ConsumerState<NowPlayingOverlay>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Expand to full screen height minus some top padding
    final fullHeight = MediaQuery.of(context).size.height;
    _heightAnimation = Tween<double>(
      begin: 80,
      end: fullHeight,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;

    // Don't show overlay if nothing is playing
    if (track == null) return const SizedBox.shrink();

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Simple drag to dismiss logic mapping RN's Gesture.Pan()
        if (details.delta.dy > 5 && _isExpanded) {
          _toggleExpand();
        } else if (details.delta.dy < -5 && !_isExpanded) {
          _toggleExpand();
        }
      },
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          final isFullScreen = _isExpanded;

          return Container(
            height: _heightAnimation.value,
            margin: isFullScreen
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              boxShadow: [
                if (!isFullScreen)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: isFullScreen
                  ? BorderRadius.zero
                  : BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Dynamic Background for Full Screen
                  if (isFullScreen && track.artUri != null) ...[
                    ArtworkImage(
                      url: track.artUri!.toString(),
                      size: double.infinity,
                      borderRadius: 0,
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                  // Mini player glass effect or Full Screen content
                  if (!isFullScreen)
                    GlassSurface(
                      opacity: 0.6,
                      blur: 30,
                      child: _buildMiniPlayer(state),
                    )
                  else
                    _buildFullScreenPlayer(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer(PlaybackStateData state) {
    final track = state.currentTrack!;
    final notifier = ref.read(playerProvider.notifier);

    return ListTile(
      onTap: _toggleExpand,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ArtworkImage(
          url: track.artUri?.toString(),
          size: 48,
          borderRadius: 10,
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        track.artist ?? 'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textMuted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () => notifier.togglePlay(),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: () => notifier.next(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenPlayer(PlaybackStateData state) {
    final track = state.currentTrack!;
    final notifier = ref.read(playerProvider.notifier);
    final pos = state.position;
    final dur = state.duration.inMilliseconds == 0
        ? (track.duration ?? Duration.zero)
        : state.duration;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
        child: Column(
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 40),
            // Expanded Cover Art with shadow
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ArtworkImage(
                        url: track.artUri?.toString(),
                        borderRadius: 12,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            // Track Info
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist ?? 'Unknown Artist',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Seek Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: Colors.white.withValues(alpha: 0.8),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.1),
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: dur.inMilliseconds == 0
                    ? 0.0
                    : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0),
                onChanged: (val) => notifier.seek(
                  Duration(milliseconds: (val * dur.inMilliseconds).round()),
                ),
              ),
            ),
            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(pos),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '-${formatDuration(dur - pos)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.fast_rewind_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () => notifier.previous(),
                ),
                IconButton(
                  icon: Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                  onPressed: () => notifier.togglePlay(),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fast_forward_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () => notifier.next(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Bottom Actions (Volume, Queue, etc)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () {},
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.list_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
