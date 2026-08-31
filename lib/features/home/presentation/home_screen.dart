import 'package:flutter/material.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/glass_surface.dart';
import '../../player/presentation/now_playing_overlay.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good Evening', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 120), // Padding for mini player
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 32),
              _buildSectionTitle('Recently Added'),
              const SizedBox(height: 16),
              _buildHorizontalList(),
            ],
          ),
          
          // Mini Player Overlay (Gestures)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NowPlayingOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return GlassSurface(
      opacity: 0.3,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Continue Listening', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            const Text(
              'Dark Side of the Moon',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              const Text('Album Name', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Text('Artist', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}
