import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode, ProcessingState;

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
import '../providers/player_provider.dart';
import '../providers/sleep_timer_provider.dart';
import 'cassette_player.dart';

// ═══════════════════════════════════════════════════════════════
// FULL PLAYER — Signature Nexora Hi-Fi screen
// ═══════════════════════════════════════════════════════════════

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});
  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (track.artUri != null)
            Positioned.fill(
              child: _AmbientLayer(artworkUrl: track.artUri!.toString()),
            ),
          SafeArea(
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
                      final artworkSize =
                          (w * 0.72).clamp(220.0, 360.0).toDouble();
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: NexoraSpacing.s20,
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: NexoraSpacing.s8),
                                  _ArtworkStage(
                                    mode: mode,
                                    isPlaying: isPlaying,
                                    artworkUrl: track.artUri?.toString(),
                                    size: artworkSize,
                                  ),
                                  const SizedBox(height: NexoraSpacing.s24),
                                  _TrackIdentity(
                                    title: track.title,
                                    artist: track.artist,
                                    album: track.album,
                                  ),
                                  const SizedBox(height: NexoraSpacing.s12),
                                  GestureDetector(
                                    onTap: () => _showAudioDetailsSheet(
                                      context,
                                      track,
                                    ),
                                    child: NexoraQualityInfo(
                                      codec: track.extras?['codec'] as String?,
                                      lossless:
                                          track.extras?['lossless'] as bool?,
                                      bitDepth:
                                          track.extras?['bitDepth'] as int?,
                                      sampleRate:
                                          track.extras?['sampleRate'] as int?,
                                      bitrate: track.extras?['bitrate'] as int?,
                                      compact: true,
                                    ),
                                  ),
                                  const SizedBox(height: NexoraSpacing.s24),
                                  NexoraSeekBar(
                                    position: pos,
                                    duration: dur,
                                    onSeek: notifier.seek,
                                  ),
                                  const SizedBox(height: NexoraSpacing.s20),
                                  NexoraPlaybackControls(
                                    isPlaying: isPlaying,
                                    isBuffering:
                                        state.processingState ==
                                        ProcessingState.buffering,
                                    shuffle: state.shuffleEnabled,
                                    repeatMode: state.repeatMode,
                                    onShuffle: notifier.toggleShuffle,
                                    onPrevious: notifier.previous,
                                    onPlayPause: notifier.togglePlay,
                                    onNext: notifier.next,
                                    onRepeat: notifier.cycleRepeat,
                                  ),
                                  const SizedBox(height: NexoraSpacing.s20),
                                  _SleepTimerInlineBar(
                                    onTap: () =>
                                        _showSleepTimerSheet(context, ref),
                                  ),
                                  const SizedBox(height: NexoraSpacing.s12),
                                  _SecondaryActions(
                                    onQueue: () => _showQueue(context),
                                    onSpeed: () => _cycleSpeed(
                                      notifier,
                                      state.playbackSpeed,
                                    ),
                                    speedLabel: _speedLabel(state.playbackSpeed),
                                    speedActive: state.playbackSpeed != 1.0,
                                  ),
                                  const SizedBox(height: NexoraSpacing.s24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _speedLadder = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  void _cycleSpeed(PlayerNotifier notifier, double current) {
    final idx = _speedLadder.indexWhere((s) => (s - current).abs() < 0.001);
    final next =
        _speedLadder[(idx < 0 ? 2 : (idx + 1) % _speedLadder.length)];
    notifier.setSpeed(next);
  }

  String _speedLabel(double s) => s == 1.0 ? '1x' : '${s}x';

  void _showQueue(BuildContext context) {
    final state = ref.read(playerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: NexoraRadius.sheetTop,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.6),
                ),
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Queue',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
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
                        NexoraIconButton(
                          icon: Icons.playlist_remove_rounded,
                          color: AppColors.error,
                          onTap: () {
                            ref.read(playerProvider.notifier).clearQueue();
                            Navigator.pop(context);
                          },
                          tooltip: 'Clear queue',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: state.queue.isEmpty
                        ? const NexoraEmptyState(
                            icon: Icons.queue_music_rounded,
                            title: 'Queue is empty',
                            subtitle: 'Songs you add will appear here.',
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
                                indexLabel:
                                    (i + 1).toString().padLeft(2, '0'),
                                isCurrent: isCurrent,
                                isPlaying: isCurrent && state.isPlaying,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textDim,
                                  ),
                                  onPressed: () => ref
                                      .read(playerProvider.notifier)
                                      .removeAt(i),
                                  tooltip: 'Remove',
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
            );
          },
        );
      },
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => _SleepTimerSheet(),
    );
  }

  void _showVisualModeSheet(BuildContext context, WidgetRef ref) {
    final current = ref.read(playerVisualModeProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return NexoraSheet(
          title: 'Player Style',
          subtitle: 'Choose how the artwork stage is presented.',
          initialHeight: 0.46,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              for (final mode in PlayerVisualMode.values)
                _VisualModeTile(
                  mode: mode,
                  selected: mode == current,
                  onTap: () {
                    ref.read(playerVisualModeProvider.notifier).set(mode);
                    Navigator.pop(c);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAudioDetailsSheet(BuildContext context, dynamic track) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) {
        return NexoraSheet(
          title: 'Audio Details',
          subtitle: 'Technical information for the current track.',
          initialHeight: 0.62,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NexoraArtwork(
                      url: track.artUri?.toString(),
                      size: 72,
                    ),
                    const SizedBox(width: NexoraSpacing.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (track.artist != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              track.artist ?? '',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.s24),
                NexoraQualityInfo(
                  codec: track.extras?['codec'] as String?,
                  lossless: track.extras?['lossless'] as bool?,
                  bitDepth: track.extras?['bitDepth'] as int?,
                  sampleRate: track.extras?['sampleRate'] as int?,
                  bitrate: track.extras?['bitrate'] as int?,
                  channels: _channelLabel(track.extras?['channels']),
                  outputLabel: null,
                ),
                const SizedBox(height: NexoraSpacing.s24),
                const Text(
                  'Playback Engine',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Nexora Audio Engine',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: NexoraSpacing.s8),
                Text(
                  'Values are read directly from the source file metadata. '
                  'When the server does not supply a field, it is hidden.',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _channelLabel(dynamic channels) {
    if (channels == null) return null;
    final n = channels is int
        ? channels
        : int.tryParse(channels.toString());
    if (n == null) return channels.toString();
    if (n == 1) return 'Mono';
    if (n == 2) return 'Stereo';
    return '$n ch';
  }
}

// ═══════════════════════════════════════════════════════════════
// AMBIENT LAYER
// ═══════════════════════════════════════════════════════════════

class _AmbientLayer extends StatelessWidget {
  final String artworkUrl;
  const _AmbientLayer({required this.artworkUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.18,
            child: Image.network(
              artworkUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox.shrink(),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0.85),
                  AppColors.background.withValues(alpha: 0.96),
                  AppColors.background,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════

class _TopBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.text,
              size: 30,
            ),
            onPressed: onClose,
            tooltip: 'Close',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onMode,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        modeLabel.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (timer.isActive)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: onSleepTimer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bedtime_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timer.label.replaceAll(' left', ''),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.bedtime_outlined,
              color: AppColors.text,
              size: 22,
            ),
            onPressed: onSleepTimer,
            tooltip: 'Sleep timer',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ARTWORK STAGE — Modern / Vinyl / Cassette / Minimal
// ═══════════════════════════════════════════════════════════════

class _ArtworkStage extends StatelessWidget {
  final PlayerVisualMode mode;
  final bool isPlaying;
  final String? artworkUrl;
  final double size;
  const _ArtworkStage({
    required this.mode,
    required this.isPlaying,
    required this.artworkUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: NexoraDuration.crossfade,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [...previous, current],
      ),
      child: KeyedSubtree(
        key: ValueKey(mode),
        child: _buildForMode(),
      ),
    );
  }

  Widget _buildForMode() {
    switch (mode) {
      case PlayerVisualMode.modern:
        return Column(
          children: [
            NexoraArtwork(url: artworkUrl, size: size),
            const SizedBox(height: NexoraSpacing.s12),
            _PulseDot(active: isPlaying),
          ],
        );
      case PlayerVisualMode.vinyl:
        return _VinylStage(
          artworkUrl: artworkUrl,
          isPlaying: isPlaying,
          size: size,
        );
      case PlayerVisualMode.cassette:
        return SizedBox(
          width: size,
          height: size * 0.62,
          child: CassettePlayer(
            isPlaying: isPlaying,
            artworkUrl: artworkUrl,
          ),
        );
      case PlayerVisualMode.minimal:
        return NexoraArtwork(url: artworkUrl, size: size * 0.85);
    }
  }
}

class _PulseDot extends StatefulWidget {
  final bool active;
  const _PulseDot({required this.active});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (c, _) {
        final t = widget.active ? _c.value : 0.0;
        return Opacity(
          opacity: 0.6 + 0.4 * t,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _VinylStage extends StatefulWidget {
  final String? artworkUrl;
  final bool isPlaying;
  final double size;
  const _VinylStage({
    required this.artworkUrl,
    required this.isPlaying,
    required this.size,
  });

  @override
  State<_VinylStage> createState() => _VinylStageState();
}

class _VinylStageState extends State<_VinylStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.isPlaying) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant _VinylStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (c, _) {
        return Transform.rotate(
          angle: _c.value * 6.28318,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border, width: 0.6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * 0.7,
                  height: widget.size * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                ),
                NexoraArtwork(
                  url: widget.artworkUrl,
                  size: widget.size * 0.66,
                  radius: BorderRadius.zero,
                ),
                Container(
                  width: widget.size * 0.12,
                  height: widget.size * 0.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                    border: Border.all(color: AppColors.border, width: 1.0),
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

// ═══════════════════════════════════════════════════════════════
// TRACK IDENTITY
// ═══════════════════════════════════════════════════════════════

class _TrackIdentity extends StatelessWidget {
  final String title;
  final String? artist;
  final String? album;
  const _TrackIdentity({
    required this.title,
    this.artist,
    this.album,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.2,
          ),
        ),
        if (artist != null) ...[
          const SizedBox(height: 6),
          Text(
            artist!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ],
        if (album != null) ...[
          const SizedBox(height: 2),
          Text(
            album!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECONDARY ACTIONS
// ═══════════════════════════════════════════════════════════════

class _SecondaryActions extends StatelessWidget {
  final VoidCallback onQueue;
  final VoidCallback onSpeed;
  final String speedLabel;
  final bool speedActive;

  const _SecondaryActions({
    required this.onQueue,
    required this.onSpeed,
    required this.speedLabel,
    required this.speedActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Pill(
          icon: Icons.queue_music_rounded,
          onTap: onQueue,
          tooltip: 'Queue',
        ),
        const SizedBox(width: 16),
        _Pill(
          icon: Icons.speed_rounded,
          label: speedLabel,
          active: speedActive,
          onTap: onSpeed,
          tooltip: 'Playback speed',
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;
  final String tooltip;

  const _Pill({
    required this.icon,
    this.label,
    required this.active,
    this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? AppColors.accent : AppColors.text);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: c,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

// ═══════════════════════════════════════════════════════════════
// VISUAL MODE TILE
// ═══════════════════════════════════════════════════════════════

class _VisualModeTile extends StatelessWidget {
  final PlayerVisualMode mode;
  final bool selected;
  final VoidCallback onTap;
  const _VisualModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case PlayerVisualMode.modern:
        return Icons.crop_square_rounded;
      case PlayerVisualMode.vinyl:
        return Icons.album_rounded;
      case PlayerVisualMode.cassette:
        return Icons.cassette_rounded;
      case PlayerVisualMode.minimal:
        return Icons.minimize_rounded;
    }
  }

  String get _desc {
    switch (mode) {
      case PlayerVisualMode.modern:
        return 'Default. Calm dark canvas with sharp square artwork.';
      case PlayerVisualMode.vinyl:
        return 'Rotating round record with the artwork at its center.';
      case PlayerVisualMode.cassette:
        return 'Tape-inspired stage with rotating reels.';
      case PlayerVisualMode.minimal:
        return 'Only the artwork and track identity.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.s12,
          vertical: NexoraSpacing.s12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                size: 18,
                color: selected ? AppColors.accent : AppColors.text,
              ),
            ),
            const SizedBox(width: NexoraSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: TextStyle(
                      color: selected ? AppColors.accent : AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _desc,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.accent,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SLEEP TIMER — inline bar + bottom sheet
// ═══════════════════════════════════════════════════════════════

class _SleepTimerInlineBar extends ConsumerWidget {
  final VoidCallback onTap;
  const _SleepTimerInlineBar({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    if (!timer.isActive) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.s16,
          vertical: NexoraSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: NexoraRadius.card,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.35),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bedtime_rounded,
                size: 14,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: NexoraSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sleep timer · ${timer.label}',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: timer.progress,
                      minHeight: 3,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NexoraSpacing.s12),
            GestureDetector(
              onTap: () => ref.read(sleepTimerProvider.notifier).cancel(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(sleepTimerProvider);
    return NexoraSheet(
      title: 'Sleep Timer',
      initialHeight: 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    timer.isActive
                        ? timer.label
                        : 'Music stops automatically',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (timer.isActive)
                  GestureDetector(
                    onTap: () =>
                        ref.read(sleepTimerProvider.notifier).cancel(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: NexoraSpacing.s20),
            const Text(
              'SET TIMER',
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: NexoraSpacing.s12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final d in SleepTimerNotifier.presets)
                  _PresetChip(
                    duration: d,
                    selected: timer.isActive && timer.total == d,
                    onTap: () {
                      ref.read(sleepTimerProvider.notifier).setTimer(d);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final Duration duration;
  final bool selected;
  final VoidCallback onTap;
  const _PresetChip({
    required this.duration,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: NexoraDuration.short,
        padding: const EdgeInsets.symmetric(
          horizontal: NexoraSpacing.s16,
          vertical: NexoraSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: NexoraRadius.button,
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.border,
            width: 0.6,
          ),
        ),
        child: Text(
          formatSleepDuration(duration),
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}