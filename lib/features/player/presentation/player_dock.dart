import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/lyrics_api.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../ui/theme.dart';
import '../providers/sleep_timer_provider.dart';

class PlayerQuickActions extends StatelessWidget {
  final VoidCallback onQueue;
  final VoidCallback onLyrics;
  final bool lyricsAvailable;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onEqualizer;

  const PlayerQuickActions({
    required this.onQueue,
    required this.onLyrics,
    this.lyricsAvailable = false,
    required this.onAddToPlaylist,
    required this.onEqualizer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          QuickActionIcon(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: onQueue,
          ),
          QuickActionIcon(
            icon: Icons.lyrics_rounded,
            label: 'Lyrics',
            highlighted: lyricsAvailable,
            onTap: onLyrics,
          ),
          QuickActionIcon(
            icon: Icons.playlist_add_rounded,
            label: 'Add',
            onTap: onAddToPlaylist,
          ),
          QuickActionIcon(
            icon: Icons.equalizer_rounded,
            label: 'EQ',
            onTap: onEqualizer,
          ),
        ],
      ),
    );
  }
}

class QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const QuickActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — bright icon + label, no box.
    final Color main = highlighted ? AppColors.accent : AppColors.text;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: main, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: highlighted ? AppColors.accent : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// #1 Bottom-space dock — volume + speed + favorite + sleep + lyrics sync.
/// Turns the dead gap below EQ into live, tactile controls.
class VolumeBar extends StatelessWidget {
  final double volume;
  final double speed;
  final ValueChanged<double> onVolume;
  final VoidCallback onSpeedTap;

  const VolumeBar({
    required this.volume,
    required this.speed,
    required this.onVolume,
    required this.onSpeedTap,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — no card. Slider + plain speed text.
    final muted = volume <= 0.01;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onVolume(muted ? 1.0 : 0.0);
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              muted
                  ? Icons.volume_off_rounded
                  : volume < 0.5
                  ? Icons.volume_down_rounded
                  : Icons.volume_up_rounded,
              color: AppColors.text,
              size: 22,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: Colors.white,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(value: volume.clamp(0.0, 1.0), onChanged: onVolume),
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSpeedTap();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 1 : 2)}×',
              style: TextStyle(
                color: speed == 1.0 ? AppColors.textMuted : AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PlayerBottomDock extends ConsumerWidget {
  final MediaItem track;
  final String? rootId;
  final String songId;
  final String filePath;
  final LyricsData? lyricsData;
  final VoidCallback onSleep;
  final VoidCallback onSpeed;
  final VoidCallback? onLyricsEdit;

  const PlayerBottomDock({
    required this.track,
    required this.rootId,
    required this.songId,
    required this.filePath,
    required this.lyricsData,
    required this.onSleep,
    required this.onSpeed,
    required this.onLyricsEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleep = ref.watch(sleepTimerProvider);
    final synced = lyricsData?.synced ?? false;
    final hasLyrics = lyricsData?.hasLyrics ?? false;
    // Direct on background — no card. Evenly spread actions.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FavoriteButton(track: track, songId: songId),
          DockButton(icon: Icons.speed_rounded, label: 'Speed', onTap: onSpeed),
          DockButton(
            icon: Icons.bedtime_outlined,
            label: sleep.isActive ? sleep.label : 'Sleep',
            highlight: sleep.isActive,
            onTap: onSleep,
          ),
          DockButton(
            icon: hasLyrics
                ? (synced ? Icons.lyrics_rounded : Icons.lyrics_outlined)
                : Icons.lyrics_outlined,
            label: hasLyrics ? (synced ? 'Synced' : 'Plain') : 'No lyr',
            highlight: hasLyrics && synced,
            dimmed: !hasLyrics,
            onTap:
                onLyricsEdit ??
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Lyrics editing needs a server track (root+path).',
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  final bool dimmed;

  const DockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Direct on background — bright white idle, accent when highlighted.
    final Color main = highlight
        ? AppColors.accent
        : dimmed
        ? AppColors.textFaint
        : AppColors.text;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: main),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: main,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: highlight ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: highlight ? AppColors.accentGradient : null,
                color: highlight ? null : Colors.transparent,
                boxShadow: highlight
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Optimistic favorite toggle wired to the real backend + offline queue.
class FavoriteButton extends ConsumerStatefulWidget {
  final MediaItem track;
  final String songId;
  const FavoriteButton({required this.track, required this.songId});

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton> {
  bool _liked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadLiked(widget.songId);
  }

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      setState(() => _liked = false);
      _loadLiked(widget.songId);
    }
  }

  /// Real initial state from the local favorites mirror (never assume).
  Future<void> _loadLiked(String songId) async {
    try {
      final v = await ref.read(favoritesRepositoryProvider).isFavorite(songId);
      if (mounted && songId == widget.songId) {
        setState(() => _liked = v);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy
          ? null
          : () async {
              HapticFeedback.lightImpact();
              final next = !_liked;
              setState(() {
                _liked = next;
                _busy = true;
              });
              try {
                await ref
                    .read(favoritesRepositoryProvider)
                    .toggleFavorite(widget.songId, !next);
              } catch (e) {
                if (mounted) {
                  setState(() => _liked = !next);
                  // Honest message: offline failures are queued silently
                  // by the repository, so anything reaching here is real.
                  final msg = e.toString().replaceFirst('Exception: ', '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Favorite failed: $msg')),
                  );
                }
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => ScaleTransition(
              scale: Tween<double>(begin: 0.6, end: 1.0).animate(a),
              child: c,
            ),
            child: Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_liked),
              size: 24,
              color: _liked ? const Color(0xFFFF5C8A) : AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _liked ? 'Loved' : 'Love',
            style: TextStyle(
              color: _liked ? const Color(0xFFFF5C8A) : AppColors.textMuted,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
