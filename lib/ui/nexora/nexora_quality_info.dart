import 'package:flutter/material.dart';

import '../theme.dart';
import 'nexora_artwork.dart';
import 'nexora_tokens.dart';

/// Calm, editorial Hi-Fi quality info block.
///
/// Renders only the metadata fields actually supplied by the backend.
/// No fake bitrates or sample rates. The section reads as if it were
/// stamped on a piece of Hi-Fi gear.
class NexoraQualityInfo extends StatelessWidget {
  final String? codec;
  final bool? lossless;
  final int? bitDepth;
  final int? sampleRate;
  final int? bitrate; // kbps
  final String? channels;
  final String? outputLabel;
  final String? engineLabel;
  final bool compact;

  const NexoraQualityInfo({
    super.key,
    this.codec,
    this.lossless,
    this.bitDepth,
    this.sampleRate,
    this.bitrate,
    this.channels,
    this.outputLabel,
    this.engineLabel,
    this.compact = false,
  });

  String? _formatBitrate(int? kbps) {
    if (kbps == null || kbps <= 0) return null;
    if (kbps >= 1000) {
      final mbps = kbps / 1000;
      return '${mbps.toStringAsFixed(mbps >= 10 ? 1 : 2)} Mbps';
    }
    return '$kbps kbps';
  }

  String? _formatSampleRate(int? sr) {
    if (sr == null || sr <= 0) return null;
    if (sr >= 1000) {
      return '${(sr / 1000).toStringAsFixed(sr % 1000 == 0 ? 0 : 1)} kHz';
    }
    return '$sr Hz';
  }

  String? _formatBitDepth(int? bd) {
    if (bd == null || bd <= 0) return null;
    return '$bd-bit';
  }

  String? _formatLossless(bool? l) {
    if (l == null) return null;
    return l ? 'Lossless' : 'Lossy';
  }

  String? _formatCodec(String? c) {
    if (c == null || c.trim().isEmpty) return null;
    return c.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final headline = <String>[
      if (_formatCodec(codec) != null) _formatCodec(codec)!,
      if (_formatLossless(lossless) != null) _formatLossless(lossless)!,
    ].join(' • ');

    final subline = <String>[
      if (_formatBitDepth(bitDepth) != null) _formatBitDepth(bitDepth)!,
      if (_formatSampleRate(sampleRate) != null) _formatSampleRate(sampleRate)!,
      if (_formatBitrate(bitrate) != null) _formatBitrate(bitrate)!,
      if (channels != null && channels!.isNotEmpty) channels!,
    ].join(' • ');

    if (headline.isEmpty && subline.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headline.isNotEmpty)
            Text(
              headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          if (subline.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.4,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headline.isNotEmpty)
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: NexoraSpacing.s12),
              Expanded(
                child: Text(
                  headline,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        if (subline.isNotEmpty) ...[
          const SizedBox(height: NexoraSpacing.s8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              subline,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 0.2,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
        if (engineLabel != null || outputLabel != null) ...[
          const SizedBox(height: NexoraSpacing.s16),
          const _Field(label: 'Playback Engine', value: 'Nexora Audio Engine'),
          if (engineLabel != null)
            _Field(label: 'Output', value: engineLabel!),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Artwork displayed inside the Audio Details sheet. Pulls a single
/// image from the URL on the [MediaItem]. Falls back to a quiet tile.
class NexoraQualityHero extends StatelessWidget {
  final String? artworkUrl;
  final double size;
  const NexoraQualityHero({super.key, required this.artworkUrl, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return NexoraArtwork(url: artworkUrl, size: size);
  }
}