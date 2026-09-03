import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/player/providers/player_provider.dart';
import '../../core/network/connectivity_service.dart';
import '../theme.dart';
import '../widgets/animated_cover.dart';
import 'nexora_artwork.dart';
import 'nexora_glass.dart';
import 'nexora_primitives.dart';
import 'nexora_rows.dart';
import 'nexora_tokens.dart';

/// Premium persistent mini-player.
///
/// Square artwork on the left, title + artist center, play / next on the
/// right. Supports horizontal swipe gestures: left → next, right →
/// previous. Long-press can be wired by callers for quick actions. Tap
/// opens the full player.
class NexoraMiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onShowQueue;
  const NexoraMiniPlayer({super.key, required this.onTap, this.onShowQueue});

  @override
  ConsumerState<NexoraMiniPlayer> createState() => _NexoraMiniPlayerState();
}

class _NexoraMiniPlayerState extends ConsumerState<NexoraMiniPlayer> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final progress = state.duration.inMilliseconds == 0
        ? 0.0
        : (state.position.inMilliseconds / state.duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    return AnimatedScale(
      scale: _dragOffset.abs() > 20 ? 0.98 : 1.0,
      duration: NexoraDuration.tap,
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: () => _showQueue(context),
        onVerticalDragEnd: (details) {
          final vy = details.primaryVelocity ?? 0;
          if (vy < -360) {
            if (widget.onShowQueue != null) {
              widget.onShowQueue!.call();
            } else {
              _showQueue(context);
            }
          }
        },
        onHorizontalDragUpdate: (details) {
          setState(() => _dragOffset += details.delta.dx);
        },
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (_dragOffset < -44 || v < -520) {
            ref.read(playerProvider.notifier).next();
          } else if (_dragOffset > 44 || v > 520) {
            ref.read(playerProvider.notifier).previous();
          }
          setState(() => _dragOffset = 0);
        },
        onHorizontalDragCancel: () => setState(() => _dragOffset = 0),
        child: NexoraGlass(
          borderRadius: BorderRadius.circular(20),
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: EdgeInsets.zero,
          blur: 28,
          tintAlpha: 0.66,
          borderAlpha: 0.30,
          borderWidth: 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          NexoraArtwork(
                            url: track.artUri?.toString(),
                            size: 46,
                          ),
                          // Offline dot — queue/downloads keep playing.
                          if (ref.watch(
                            connectivityMonitorProvider.select(
                              (s) => s.isOffline,
                            ),
                          ))
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.warning,
                                  border: Border.all(
                                    color: AppColors.card,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 9,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (state.isPlaying)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: NexoraEqualizerBars(
                                  playing: true,
                                  barWidth: 2,
                                  minHeight: 2,
                                  maxHeight: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: NexoraSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (track.artist != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              track.artist!,
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
                    _MiniPlayButton(
                      isPlaying: state.isPlaying,
                      onPressed: () =>
                          ref.read(playerProvider.notifier).togglePlay(),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.skip_next_rounded,
                        color: AppColors.text,
                        size: 24,
                      ),
                      onPressed: () => ref.read(playerProvider.notifier).next(),
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ),
              // Aurora gradient progress line.
              Stack(
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh.withValues(alpha: 0.55),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: AppColors.accentGradientHorizontal,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    final state = ref.read(playerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (c) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return NexoraGlass(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              blur: 30,
              tintAlpha: 0.65,
              borderAlpha: 0.45,
              borderWidth: 0.7,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Queue',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Playing next',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.playlist_remove_rounded,
                              color: AppColors.textDim,
                              size: 20,
                            ),
                            onPressed: () {
                              ref.read(playerProvider.notifier).clearQueue();
                              Navigator.pop(context);
                            },
                            tooltip: 'Clear',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: state.queue.isEmpty
                          ? const NexoraEmptyState(
                              icon: Icons.queue_music_rounded,
                              title: 'Queue is empty',
                              subtitle: 'Add songs from library.',
                            )
                          : ReorderableListView.builder(
                              scrollController: scrollController,
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: state.queue.length,
                              onReorder: (o, n) => ref
                                  .read(playerProvider.notifier)
                                  .move(o, n > o ? n - 1 : n),
                              itemBuilder: (cx, i) {
                                final item = state.queue[i];
                                final isCurrent =
                                    state.currentTrack?.id == item.id;
                                return NexoraTrackRow(
                                  key: ValueKey('${item.id}_$i'),
                                  artworkUrl: item.artUri?.toString(),
                                  title: item.title,
                                  subtitle: item.artist,
                                  indexLabel: (i + 1).toString().padLeft(
                                    2,
                                    '0',
                                  ),
                                  isCurrent: isCurrent,
                                  isPlaying: isCurrent && state.isPlaying,
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.textDim,
                                    ),
                                    onPressed: () => ref
                                        .read(playerProvider.notifier)
                                        .removeAt(i),
                                  ),
                                  onTap: () {
                                    ref
                                        .read(playerProvider.notifier)
                                        .seekToIndex(i);
                                    Navigator.pop(context);
                                  },
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
      },
    );
  }
}

class _MiniPlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  const _MiniPlayButton({required this.isPlaying, required this.onPressed});

  @override
  State<_MiniPlayButton> createState() => _MiniPlayButtonState();
}

class _MiniPlayButtonState extends State<_MiniPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: NexoraDuration.tap,
        curve: Curves.easeOut,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
