import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, ProcessingState;
import 'package:audio_service/audio_service.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/nexora/nexora_artwork.dart';
import '../../../ui/nexora/nexora_controls.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_quality_info.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_seek_bar.dart';
import '../../../ui/nexora/nexora_sheet.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/nexora/player_visual_mode_provider.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/animated_cover.dart';
import '../../../ui/widgets/lyrics_display.dart';
import '../providers/player_provider.dart';
import '../providers/sleep_timer_provider.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';
import '../../../domain/entities/song.dart';
import '../../../data/api/audio_api.dart';
import '../../../data/api/lyrics_api.dart';
import 'cassette_player.dart';

/// Full Player — audiophile redesign.
///
/// Features:
/// - Animated album cover with breathing glow
/// - Rich audio quality badge (codec, sample rate, bit depth)
/// - Synced lyrics integration
/// - Sleep timer & visual mode controls
/// - Swipe gestures for dismiss / queue
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});
  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  bool _showLyrics = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final track = state.currentTrack;
    final mode = ref.watch(playerVisualModeProvider);

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
        body: Center(
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

    // Fetch audio info & lyrics (MediaItem doesn't have rootId directly,
    // so we read it from extras which the player provider populates).
    final rootId = track.extras?['rootId'] as String?;
    final songId = (track.extras?['songId'] as String?) ?? track.id;
    final audioInfo = rootId != null
        ? ref.watch(
            audioInfoProvider(
              Song(
                id: songId,
                title: track.title,
                artist: track.artist,
                rootId: rootId,
              ),
            ),
          )
        : null;
    final lyrics = rootId != null
        ? ref.watch(lyricsProvider((rootId: rootId, path: songId)))
        : null;

    if (_showLyrics) {
      final lyricsData = lyrics?.value;
      final hasLyrics = lyricsData?.hasLyrics ?? false;
      final lyricLines = hasLyrics
          ? lyricsData!.cues
                .map(
                  (c) => LyricLine(
                    text: c.text,
                    timestamp: c.isSynced
                        ? Duration(milliseconds: (c.time * 1000).round())
                        : null,
                  ),
                )
                .toList()
          : <LyricLine>[];

      return LyricsDisplay(
        lyrics: lyricLines,
        currentPosition: pos,
        onClose: () => setState(() => _showLyrics = false),
        title: track.title,
        artist: track.artist,
        artworkUrl: track.artUri?.toString(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient blurred artwork background
          if (track.artUri != null)
            Positioned.fill(
              child: _AmbientLayer(artworkUrl: track.artUri!.toString()),
            ),
          SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onVerticalDragEnd: (details) {
                final vy = details.primaryVelocity ?? 0;
                if (vy > 380 && Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else if (vy < -420) {
                  _showQueue(context);
                }
              },
              child: Column(
                children: [
                  _TopBar(
                    onClose: () => Navigator.pop(context),
                    onSleepTimer: () => _showSleepTimerSheet(context, ref),
                    onMode: () => _showVisualModeSheet(context, ref),
                    modeLabel: mode.label,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = MediaQuery.of(context).size.width;
                        final artworkSize = (w * 0.72).clamp(220.0, 360.0);
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              // Animated cover — larger, softer, glowing.
                              AnimatedAlbumCover(
                                imageUrl: track.artUri?.toString(),
                                isPlaying: isPlaying,
                                size: artworkSize,
                                borderRadius: 24,
                              ),
                              const SizedBox(height: 28),
                              // Title + artist
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      track.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      track.artist ?? 'Unknown Artist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Audio quality badge
                                    if (audioInfo != null)
                                      audioInfo.when(
                                        data: (info) => info != null
                                            ? NexoraTag(
                                                label: info.shortLabel,
                                                icon:
                                                    Icons.high_quality_rounded,
                                                color: info.lossless
                                                    ? const Color(0xFFFFB020)
                                                    : AppColors.accent,
                                              )
                                            : const SizedBox.shrink(),
                                        loading: () => const SizedBox(
                                          width: 60,
                                          height: 16,
                                          child: Center(
                                            child: SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        error: (_, __) =>
                                            const SizedBox.shrink(),
                                      ),
                                    const SizedBox(height: 6),
                                    // Lyrics button
                                    if (lyrics != null)
                                      lyrics.when(
                                        data: (data) => data.hasLyrics
                                            ? LyricsButton(
                                                hasLyrics: true,
                                                onTap: () => setState(
                                                  () => _showLyrics = true,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) =>
                                            const SizedBox.shrink(),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Seek bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                ),
                                child: Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 3,
                                        activeTrackColor: AppColors.text,
                                        inactiveTrackColor:
                                            AppColors.surfaceHigh,
                                        thumbColor: AppColors.text,
                                        overlayColor: AppColors.accent
                                            .withValues(alpha: 0.10),
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 16,
                                            ),
                                        trackShape:
                                            const RoundedRectSliderTrackShape(),
                                      ),
                                      child: Slider(
                                        value: pos.inMilliseconds
                                            .toDouble()
                                            .clamp(
                                              0.0,
                                              dur.inMilliseconds.toDouble(),
                                            ),
                                        max: dur.inMilliseconds.toDouble(),
                                        onChanged: (v) => notifier.seek(
                                          Duration(milliseconds: v.round()),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(pos),
                                            style: TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(dur),
                                            style: TextStyle(
                                              color: AppColors.textDim,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Controls
                              _Controls(
                                isPlaying: isPlaying,
                                loopMode: state.repeatMode,
                                isShuffled: state.shuffleEnabled,
                                onPlayPause: notifier.togglePlay,
                                onPrevious: notifier.previous,
                                onNext: notifier.next,
                                onLoop: notifier.cycleRepeat,
                                onShuffle: notifier.toggleShuffle,
                              ),
                              const SizedBox(height: 20),
                              // Bottom actions
                              _BottomActions(
                                onQueue: () => _showQueue(context),
                                onAddToPlaylist: () =>
                                    _showAddToPlaylist(context, track),
                                onEqualizer: () => context.push('/equalizer'),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => const _QueueSheet(),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _SleepTimerSheet(),
    );
  }

  void _showVisualModeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => const _VisualModeSheet(),
    );
  }

  void _showAddToPlaylist(BuildContext context, MediaItem track) {
    // Convert MediaItem to Song for the playlist sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (c) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: NexoraRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Add "${track.title}" to playlist',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSleepTimer;
  final VoidCallback onMode;
  final String modeLabel;

  const _TopBar({
    required this.onClose,
    required this.onSleepTimer,
    required this.onMode,
    required this.modeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.text,
              size: 28,
            ),
            onPressed: onClose,
          ),
          const Spacer(),
          Text(
            modeLabel.toUpperCase(),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.bedtime_outlined, color: AppColors.text, size: 20),
            onPressed: onSleepTimer,
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: AppColors.text, size: 20),
            onPressed: onMode,
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final bool isPlaying;
  final LoopMode loopMode;
  final bool isShuffled;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLoop;
  final VoidCallback onShuffle;

  const _Controls({
    required this.isPlaying,
    required this.loopMode,
    required this.isShuffled,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onLoop,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shuffle
          IconButton(
            icon: Icon(
              Icons.shuffle_rounded,
              color: isShuffled
                  ? AppColors.accent
                  : AppColors.text.withValues(alpha: 0.6),
              size: 22,
            ),
            onPressed: onShuffle,
          ),
          // Previous
          IconButton(
            icon: Icon(
              Icons.skip_previous_rounded,
              color: AppColors.text,
              size: 32,
            ),
            onPressed: onPrevious,
          ),
          // Play / Pause — aurora gradient hero button.
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.20),
                    blurRadius: 52,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
          // Next
          IconButton(
            icon: Icon(
              Icons.skip_next_rounded,
              color: AppColors.text,
              size: 32,
            ),
            onPressed: onNext,
          ),
          // Loop
          IconButton(
            icon: Icon(
              loopMode == LoopMode.one
                  ? Icons.repeat_one_rounded
                  : Icons.repeat_rounded,
              color: loopMode != LoopMode.off
                  ? AppColors.accent
                  : AppColors.text.withValues(alpha: 0.6),
              size: 22,
            ),
            onPressed: onLoop,
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onQueue;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onEqualizer;

  const _BottomActions({
    required this.onQueue,
    required this.onAddToPlaylist,
    required this.onEqualizer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionIcon(
            icon: Icons.queue_music_rounded,
            label: 'Queue',
            onTap: onQueue,
          ),
          _ActionIcon(
            icon: Icons.playlist_add_rounded,
            label: 'Add',
            onTap: onAddToPlaylist,
          ),
          _ActionIcon(
            icon: Icons.equalizer_rounded,
            label: 'EQ',
            onTap: onEqualizer,
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textFaint,
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

class _AmbientLayer extends StatelessWidget {
  final String artworkUrl;
  const _AmbientLayer({required this.artworkUrl});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          AppColors.background.withValues(alpha: 0.85),
          BlendMode.srcOver,
        ),
        child: Image.network(
          artworkUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => Container(color: AppColors.background),
        ),
      ),
    );
  }
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final queue = state.queue;
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textFaint.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Queue',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const NexoraEmptyState(
                      icon: Icons.queue_music_outlined,
                      title: 'Queue is empty',
                      subtitle: 'Add songs from your library.',
                    )
                  : ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (c, i) {
                        final item = queue[i];
                        final isCurrent = state.currentTrack?.id == item.id;
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.artUri != null
                                ? Image.network(
                                    item.artUri!.toString(),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 44,
                                      height: 44,
                                      color: AppColors.surfaceRaised,
                                      child: Icon(
                                        Icons.music_note_rounded,
                                        color: AppColors.textDim,
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    color: AppColors.surfaceRaised,
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      color: AppColors.textDim,
                                      size: 20,
                                    ),
                                  ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            item.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          trailing: isCurrent
                              ? NexoraEqualizerBars(
                                  playing: state.isPlaying,
                                  barWidth: 2.5,
                                  minHeight: 3,
                                  maxHeight: 12,
                                )
                              : null,
                          onTap: () =>
                              ref.read(playerProvider.notifier).seekToIndex(i),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sleep Timer',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in SleepTimerNotifier.presets)
                    ActionChip(
                      label: Text(formatSleepDuration(d)),
                      onPressed: () {
                        ref.read(sleepTimerProvider.notifier).setTimer(d);
                        Navigator.pop(context);
                      },
                      backgroundColor: timer.isActive && timer.total == d
                          ? AppColors.accent
                          : AppColors.surfaceRaised,
                      labelStyle: TextStyle(
                        color: timer.isActive && timer.total == d
                            ? Colors.white
                            : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: timer.isActive && timer.total == d
                              ? AppColors.accent
                              : AppColors.border,
                          width: 0.7,
                        ),
                      ),
                    ),
                ],
              ),
              if (timer.isActive) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier).cancel();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel timer'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VisualModeSheet extends ConsumerWidget {
  const _VisualModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.read(playerVisualModeProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textFaint.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Player Style',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final mode in PlayerVisualMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _modeIcon(mode),
                      color: current == mode
                          ? AppColors.accent
                          : AppColors.textMuted,
                    ),
                    title: Text(
                      mode.label,
                      style: TextStyle(
                        color: current == mode
                            ? AppColors.accent
                            : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: current == mode
                        ? Icon(Icons.check_rounded, color: AppColors.accent)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      ref.read(playerVisualModeProvider.notifier).set(mode);
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _modeIcon(PlayerVisualMode mode) {
    switch (mode) {
      case PlayerVisualMode.modern:
        return Icons.album_outlined;
      case PlayerVisualMode.vinyl:
        return Icons.album_rounded;
      case PlayerVisualMode.cassette:
        return Icons.audiotrack_rounded;
      case PlayerVisualMode.minimal:
        return Icons.crop_square_rounded;
    }
  }
}
