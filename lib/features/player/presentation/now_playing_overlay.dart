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
          return Container(
            height: _heightAnimation.value,
            margin: _isExpanded
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              boxShadow: [
                if (!_isExpanded)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: _isExpanded
                  ? BorderRadius.zero
                  : BorderRadius.circular(16),
              child: GlassSurface(
                opacity: _isExpanded ? 0.8 : 0.6,
                blur: 30,
                child: _isExpanded
                    ? _buildFullScreenPlayer(state)
                    : _buildMiniPlayer(state),
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
          borderRadius: 8,
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            // Expanded Cover Art
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ArtworkImage(
                  url: track.artUri?.toString(),
                  borderRadius: 24,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Track Info
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                track.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                track.artist ?? 'Unknown Artist',
                style: const TextStyle(color: AppColors.primary, fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
            // Seek Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: AppColors.secondary,
                inactiveTrackColor: AppColors.surfaceRaised,
                thumbColor: Colors.white,
                overlayColor: AppColors.secondary.withValues(alpha: 0.2),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(pos),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatDuration(dur),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () => notifier.previous(),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () => notifier.togglePlay(),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    size: 40,
                    color: Colors.white,
                  ),
                  onPressed: () => notifier.next(),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
