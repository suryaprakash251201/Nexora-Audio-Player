import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/nexora/player_visual_mode_provider.dart';
import '../../../ui/widgets/animated_cover.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../data/api/lyrics_api.dart';
import '../providers/player_provider.dart';
import '../providers/sleep_timer_provider.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final queue = state.queue;
    final notifier = ref.read(playerProvider.notifier);
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Queue',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradientHorizontal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${queue.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const NexoraEmptyState(
                      icon: Icons.queue_music_outlined,
                      title: 'Queue is empty',
                      subtitle: 'Add songs from your library.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: queue.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final item = queue[i];
                        final isCurrent = state.currentTrack?.id == item.id;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: isCurrent
                                ? AppColors.selectionGradientHorizontal
                                : null,
                            color: isCurrent
                                ? null
                                : AppColors.surfaceRaised.withValues(
                                    alpha: 0.55,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : AppColors.border.withValues(alpha: 0.6),
                              width: 0.7,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: ArtworkImage(
                                  url: item.artUri?.toString(),
                                  borderRadius: 0,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              item.artist ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.textMuted,
                              ),
                            ),
                            trailing: isCurrent
                                ? NexoraEqualizerBars(
                                    playing: state.isPlaying,
                                    barWidth: 2.5,
                                    minHeight: 3,
                                    maxHeight: 12,
                                    color: Colors.white,
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: AppColors.textDim,
                                    ),
                                    onPressed: () => notifier.removeAt(i),
                                  ),
                            onTap: () => notifier.seekToIndex(i),
                          ),
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

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet();

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

class VisualModeSheet extends ConsumerWidget {
  const VisualModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(playerVisualModeProvider);
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
              const SizedBox(height: 6),
              Text(
                'Artwork stage updates instantly.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              for (final mode in PlayerVisualMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: current == mode
                          ? AppColors.selectionGradientHorizontal
                          : null,
                      color: current == mode
                          ? null
                          : AppColors.surfaceRaised.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: current == mode
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.border,
                        width: 0.7,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _modeIcon(mode),
                        color: current == mode
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                      title: Text(
                        mode.label,
                        style: TextStyle(
                          color: current == mode
                              ? Colors.white
                              : AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _modeDesc(mode),
                        style: TextStyle(
                          color: current == mode
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: current == mode
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(playerVisualModeProvider.notifier).set(mode);
                        Navigator.pop(context);
                      },
                    ),
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

  String _modeDesc(PlayerVisualMode mode) {
    switch (mode) {
      case PlayerVisualMode.modern:
        return 'Aurora frame, glowing square artwork';
      case PlayerVisualMode.vinyl:
        return 'Spinning record, artwork fills the label';
      case PlayerVisualMode.cassette:
        return 'Tape deck with rotating reels';
      case PlayerVisualMode.minimal:
        return 'Compact artwork, pure & quiet';
    }
  }
}

class SpeedSheet extends ConsumerWidget {
  const SpeedSheet();

  static const _presets = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(playerProvider).playbackSpeed;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
              const SizedBox(height: 14),
              Text(
                'Playback speed',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pitch-correct tempo for podcasts, practice, audiobooks.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _presets)
                    ChoiceChip(
                      label: Text(
                        '${p.toStringAsFixed(p.truncateToDouble() == p ? 1 : 2)}×',
                      ),
                      selected: (speed - p).abs() < 0.001,
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.surfaceRaised,
                      labelStyle: TextStyle(
                        color: (speed - p).abs() < 0.001
                            ? Colors.white
                            : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppColors.border, width: 0.7),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        ref.read(playerProvider.notifier).setSpeed(p);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// #5 Lyrics sync monitor + editor.
/// Shows backend sync state (synced/plain/missing + source) and lets the
/// user save plain or LRC text straight to the sibling `.lrc` file.
class LyricsEditorSheet extends ConsumerStatefulWidget {
  final String rootId;
  final String filePath;
  final String initial;
  final bool hasLyrics;
  final bool synced;

  const LyricsEditorSheet({
    required this.rootId,
    required this.filePath,
    required this.initial,
    required this.hasLyrics,
    required this.synced,
  });

  @override
  ConsumerState<LyricsEditorSheet> createState() => _LyricsEditorSheetState();
}

class _LyricsEditorSheetState extends ConsumerState<LyricsEditorSheet> {
  late final TextEditingController _c;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _c.text.trimRight();
    if (raw.trim().isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(lyricsApiProvider)
          .saveLyrics(widget.rootId, widget.filePath, raw);
      ref.invalidate(
        lyricsProvider((rootId: widget.rootId, path: widget.filePath)),
      );
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lyrics synced to server (.lrc)')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(lyricsApiProvider)
          .deleteLyrics(widget.rootId, widget.filePath);
      ref.invalidate(
        lyricsProvider((rootId: widget.rootId, path: widget.filePath)),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lyrics sync',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SyncPill(
                      hasLyrics: widget.hasLyrics,
                      synced: widget.synced,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Saved as sibling .lrc next to the track. Use [mm:ss.xx] tags for sync.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 0.7),
                    ),
                    child: TextField(
                      controller: _c,
                      maxLines: 10,
                      minLines: 6,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            '[00:12.00] First line\\n[00:15.50] Second line\\n\\nor plain text (unsynced)',
                        hintStyle: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (widget.hasLyrics)
                      TextButton.icon(
                        onPressed: _busy ? null : _delete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                        ),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _busy ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Sync'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class SyncPill extends StatelessWidget {
  final bool hasLyrics;
  final bool synced;
  const SyncPill({required this.hasLyrics, required this.synced});

  @override
  Widget build(BuildContext context) {
    final label = !hasLyrics
        ? 'MISSING'
        : synced
        ? 'SYNCED'
        : 'PLAIN';
    final color = !hasLyrics
        ? AppColors.textDim
        : synced
        ? AppColors.success
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
