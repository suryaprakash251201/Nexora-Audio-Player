import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/widgets/enhanced_player_widgets.dart';
import '../providers/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final progress = state.duration.inMilliseconds == 0
        ? 0.0
        : (state.position.inMilliseconds / state.duration.inMilliseconds)
            .clamp(0.0, 1.0);

    return GlassMiniPlayer(
      artworkUrl: track.artUri?.toString(),
      title: track.title,
      artist: track.artist,
      isPlaying: state.isPlaying,
      progress: progress,
      onTap: onTap,
      onPlayPause: () => ref.read(playerProvider.notifier).togglePlay(),
      onNext: () => ref.read(playerProvider.notifier).next(),
      onDismiss: () => ref.read(playerProvider.notifier).clearQueue(),
    );
  }
}
