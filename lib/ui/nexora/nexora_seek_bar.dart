import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_tokens.dart';

/// Audiophile-style seek bar with gradient progress.
///
/// - Gradient active rail (accentGradientHorizontal) + soft glow
/// - Buffered portion shown as translucent wash
/// - Live time labels while dragging, purely state-driven otherwise
class NexoraSeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final ValueChanged<Duration> onSeek;
  final Gradient? gradient;

  /// Base color for the thumb ring + glows so they match [gradient]
  /// while dragging (no blue-vs-purple mismatch).
  final Color accent;

  const NexoraSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.buffered = Duration.zero,
    this.gradient,
    this.accent = AppColors.accent,
  });

  @override
  State<NexoraSeekBar> createState() => _NexoraSeekBarState();
}

class _NexoraSeekBarState extends State<NexoraSeekBar> {
  double? _dragValue;

  String _format(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final posMs = widget.position.inMilliseconds;
    final bufMs = widget.buffered.inMilliseconds;
    final value = totalMs == 0
        ? 0.0
        : (_dragValue ?? posMs / totalMs).clamp(0.0, 1.0);
    final bufValue = totalMs == 0 ? 0.0 : (bufMs / totalMs).clamp(0.0, 1.0);
    final seekMs = (value * totalMs).round();
    final grad = widget.gradient ?? AppColors.accentGradientHorizontal;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: totalMs == 0
                  ? null
                  : (d) {
                      final v = (d.localPosition.dx / w).clamp(0.0, 1.0);
                      setState(() => _dragValue = v);
                    },
              onHorizontalDragUpdate: totalMs == 0
                  ? null
                  : (d) {
                      final v = (d.localPosition.dx / w).clamp(0.0, 1.0);
                      setState(() => _dragValue = v);
                    },
              onHorizontalDragEnd: totalMs == 0
                  ? null
                  : (_) {
                      final v = _dragValue ?? 0.0;
                      widget.onSeek(
                        Duration(milliseconds: (v * totalMs).round()),
                      );
                      setState(() => _dragValue = null);
                    },
              onTapDown: totalMs == 0
                  ? null
                  : (d) {
                      final v = (d.localPosition.dx / w).clamp(0.0, 1.0);
                      widget.onSeek(
                        Duration(milliseconds: (v * totalMs).round()),
                      );
                    },
              child: Container(
                height: 40,
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inactive rail — thicker for touch + visibility
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Buffered wash
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: w * bufValue,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    // Gradient progress — flat, no glow shadow (the old
                    // colored blur never matched the adaptive gradient).
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: (w * value).clamp(0.0, w),
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: grad,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    // Thumb — larger, easier to grab
                    if (totalMs > 0)
                      Positioned(
                        left: ((w * value) - 11).clamp(0.0, w - 22),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: widget.accent.withValues(alpha: 0.65),
                              width: 1.5,
                            ),
                            // Single neutral drop shadow — no colored glow
                            // (it clashed with the adaptive gradient).
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: grad,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Invisible slider for a11y / precise drag
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 8,
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.transparent,
                        overlayColor: AppColors.accent.withValues(alpha: 0.14),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 11,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 24,
                        ),
                      ),
                      child: Slider(
                        value: value,
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
                  ],
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NexoraSpacing.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(Duration(milliseconds: seekMs)),
                style: TextStyle(
                  color: _dragValue != null
                      ? AppColors.accentSoft
                      : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _format(widget.duration),
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
