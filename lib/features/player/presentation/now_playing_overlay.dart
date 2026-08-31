import 'package:flutter/material.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/glass_surface.dart';

class NowPlayingOverlay extends StatefulWidget {
  const NowPlayingOverlay({super.key});

  @override
  State<NowPlayingOverlay> createState() => _NowPlayingOverlayState();
}

class _NowPlayingOverlayState extends State<NowPlayingOverlay> with SingleTickerProviderStateMixin {
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
    _heightAnimation = Tween<double>(begin: 80, end: fullHeight).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
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
            margin: _isExpanded ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              boxShadow: [
                if (!_isExpanded)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
              ],
            ),
            child: ClipRRect(
              borderRadius: _isExpanded ? BorderRadius.zero : BorderRadius.circular(16),
              child: GlassSurface(
                opacity: _isExpanded ? 0.8 : 0.6,
                blur: 30,
                child: _isExpanded ? _buildFullScreenPlayer() : _buildMiniPlayer(),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return ListTile(
      onTap: _toggleExpand,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.white),
      ),
      title: const Text('Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: const Text('Pink Floyd', style: TextStyle(color: AppColors.textMuted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.play_arrow, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
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
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(child: Icon(Icons.music_note, size: 120, color: AppColors.textMuted)),
              ),
            ),
            const SizedBox(height: 48),
            // Track Info
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Time', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Pink Floyd', style: TextStyle(color: AppColors.primary, fontSize: 18)),
            ),
            const SizedBox(height: 32),
            // Continuous Slider Placeholder (Maps to Reanimated pan gesture)
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: AppColors.secondary,
                inactiveTrackColor: AppColors.surfaceRaised,
                thumbColor: Colors.white,
                overlayColor: AppColors.secondary.withOpacity(0.2),
              ),
              child: Slider(
                value: 0.3,
                onChanged: (val) {},
              ),
            ),
            const SizedBox(height: 16),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white), onPressed: () {}),
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(icon: const Icon(Icons.pause, size: 40, color: Colors.white), onPressed: () {}),
                ),
                IconButton(icon: const Icon(Icons.skip_next, size: 40, color: Colors.white), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
