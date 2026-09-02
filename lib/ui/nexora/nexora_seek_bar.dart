import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_tokens.dart';

/// Audiophile-style seek bar.
///
/// Thin precise rail with a subtle accent-colored active portion. While
/// dragging, the position label updates in real time. Outside of drag
/// gestures the bar is purely driven by playback state — no fake motion.
class NexoraSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const NexoraSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<NexoraSeekBar> createState() => _NexoraSeekBarState();
}

class _NexoraSeekBarState extends State<NexoraSeekBar> {
  double? _dragValue;

  String _format(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final posMs = widget.position.inMilliseconds;
    final value = totalMs == 0
        ? 0.0
        : (_dragValue ?? posMs / totalMs).clamp(0.0, 1.0);

    final seekMs = (value * totalMs).round();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceHigh,
            thumbColor: AppColors.text,
            overlayColor: AppColors.accent.withValues(alpha: 0.18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            onChangeStart: totalMs == 0
                ? null
                : (_) => setState(() => _dragValue = posMs / totalMs),
            onChanged: totalMs == 0
                ? null
                : (v) => setState(() => _dragValue = v),
            onChangeEnd: totalMs == 0
                ? null
                : (v) {
                    widget.onSeek(
                      Duration(milliseconds: (v * totalMs).round()),
                    );
                    setState(() => _dragValue = null);
                  },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(Duration(milliseconds: seekMs)),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _format(widget.duration),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
