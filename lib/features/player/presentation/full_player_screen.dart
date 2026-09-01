import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../../../ui/theme.dart';
import '../../../ui/widgets/premium_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../providers/player_provider.dart';
import 'cassette_player.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});
  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen>
    with SingleTickerProviderStateMixin {
  bool _showCassette = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final track = state.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text(
            'Nothing playing',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final isPlaying = state.isPlaying;
    final pos = state.position;
    final dur = state.duration.inMilliseconds == 0
        ? (track.duration ?? Duration.zero)
        : state.duration;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Dynamic blurred artwork background
          if (track.artUri != null)
            Positioned.fill(
              child: Image.network(
                track.artUri.toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.2),
                    AppColors.background.withValues(alpha: 0.85),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                color: AppColors.background.withValues(alpha: 0.6),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlowDot(size: 6, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.15),
                              AppColors.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _showCassette
                              ? Icons.album_rounded
                              : Icons.audiotrack_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _showCassette = !_showCassette),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _showCassette
                            ? CassettePlayer(
                                isPlaying: isPlaying,
                                artworkUrl: track.artUri?.toString(),
                              )
                            : Expanded(
                                child: Hero(
                                  tag: 'artwork_${track.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 50,
                                          spreadRadius: 5,
                                          offset: const Offset(0, 20),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 40,
                                          offset: const Offset(0, 24),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(28),
                                      child: track.artUri != null
                                          ? Image.network(
                                              track.artUri.toString(),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (_, __, ___) =>
                                                  _artPlaceholder(),
                                            )
                                          : _artPlaceholder(),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 28),
                        // Track info
                        Text(
                          track.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.artist ?? 'Unknown Artist',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (track.album != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            track.album!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Quality badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (track.extras?['codec'] != null)
                              GradientBadge(
                                text: (track.extras!['codec'] as String)
                                    .toUpperCase(),
                              ),
                            if (track.extras?['lossless'] == true)
                              const GradientBadge(
                                text: 'LOSSLESS',
                                color: AppColors.secondary,
                              ),
                            if (track.extras?['sampleRate'] != null &&
                                (track.extras!['sampleRate'] as int) >= 48000)
                              const GradientBadge(
                                text: 'HI-RES',
                                color: AppColors.tertiary,
                              ),
                            if (track.extras?['bitrate'] != null)
                              GradientBadge(
                                text: '${track.extras!['bitrate']} kbps',
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Seek slider with gradient
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 5,
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            thumbColor: Colors.white,
                            overlayColor: AppColors.primary.withValues(
                              alpha: 0.2,
                            ),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                          ),
                          child: Slider(
                            value: dur.inMilliseconds == 0
                                ? 0
                                : (pos.inMilliseconds / dur.inMilliseconds)
                                      .clamp(0.0, 1.0),
                            onChanged: (v) => notifier.seek(
                              Duration(
                                milliseconds: (v * dur.inMilliseconds).round(),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDuration(pos),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                formatDuration(dur),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Transport controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: state.shuffleEnabled
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                              onPressed: () => notifier.toggleShuffle(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                              onPressed: () => notifier.previous(),
                            ),
                            PlayButton(
                              isPlaying: isPlaying,
                              size: 76,
                              onPressed: () => notifier.togglePlay(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                              onPressed: () => notifier.next(),
                            ),
                            IconButton(
                              icon: Icon(
                                _repeatIcon(state.repeatMode),
                                color: state.repeatMode != LoopMode.off
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                              onPressed: () => notifier.cycleRepeat(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Bottom actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _IconGlow(
                              icon: Icons.queue_music_rounded,
                              onTap: () => _showQueue(context),
                            ),
                            const SizedBox(width: 14),
                            _IconGlow(
                              icon: Icons.favorite_rounded,
                              color: AppColors.tertiary,
                              onTap: () {},
                            ),
                            const SizedBox(width: 14),
                            _IconGlow(
                              icon: Icons.more_horiz_rounded,
                              color: AppColors.textMuted,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artPlaceholder() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.surfaceRaised, AppColors.surfaceHigh],
      ),
    ),
    child: const Center(
      child: Icon(
        Icons.music_note_rounded,
        size: 100,
        color: AppColors.textDim,
      ),
    ),
  );

  IconData _repeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.one:
        return Icons.repeat_one_rounded;
      case LoopMode.all:
        return Icons.repeat_rounded;
      case LoopMode.off:
      default:
        return Icons.repeat_rounded;
    }
  }

  void _showQueue(BuildContext context) {
    final state = ref.read(playerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.surfaceHigh, AppColors.surface],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorderStrong, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Up Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            ref.read(playerProvider.notifier).clearQueue(),
                        icon: const Icon(
                          Icons.playlist_remove_rounded,
                          color: AppColors.error,
                          size: 22,
                        ),
                        tooltip: 'Clear queue',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: state.queue.length,
                    onReorder: (o, n) => ref
                        .read(playerProvider.notifier)
                        .move(o, n > o ? n - 1 : n),
                    itemBuilder: (cx, i) {
                      final item = state.queue[i];
                      final isCurrent = state.currentTrack?.id == item.id;
                      return Container(
                        key: ValueKey(item.id + '_$i'),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCurrent
                                ? [
                                    AppColors.primary.withValues(alpha: 0.15),
                                    AppColors.primary.withValues(alpha: 0.05),
                                  ]
                                : [
                                    AppColors.surfaceHigh.withValues(
                                      alpha: 0.5,
                                    ),
                                    AppColors.surface.withValues(alpha: 0.3),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.border,
                            width: 0.5,
                          ),
                        ),
                        child: ListTile(
                          leading: isCurrent
                              ? const NowPlayingIndicator(height: 16, width: 16)
                              : Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceRaised,
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 0.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: AppColors.textDim,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.primaryLight
                                  : Colors.white,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            item.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textDim,
                            ),
                            onPressed: () =>
                                ref.read(playerProvider.notifier).removeAt(i),
                          ),
                          onTap: () =>
                              ref.read(playerProvider.notifier).seekToIndex(i),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small glowing icon action button for the player bottom bar.
class _IconGlow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconGlow({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
