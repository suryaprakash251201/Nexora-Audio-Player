import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../../data/api/audio_api.dart';
import '../../../ui/theme.dart';

/// Lossless-only codecs (metadata level — container-ambiguous formats
/// like m4a/mka are resolved via the server's lossless flag, never by
/// extension alone).
const _losslessCodecs = {
  'flac',
  'alac',
  'wav',
  'wave',
  'aiff',
  'aif',
  'ape',
  'dsf',
  'dff',
  'wv',
  'tta',
  'tak',
};

/// Unambiguous lossless file extensions (fallback when no metadata).
/// m4a/mka deliberately excluded — they can hold lossy AAC.
const _losslessExtensions = {
  'flac',
  'wav',
  'wave',
  'aiff',
  'aif',
  'ape',
  'dsf',
  'dff',
  'wv',
  'tta',
  'tak',
};

/// File path behind a queue item ("root|path" id or explicit extra).
String _trackFilePath(MediaItem track) {
  final ex = track.extras;
  final explicit = ex?['path'] as String?;
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final songId = (ex?['songId'] as String?) ?? track.id;
  final clean = songId.split('?').first;
  return clean.contains('|') ? clean.split('|').skip(1).join('|') : clean;
}

/// True only for genuinely lossless tracks: server flag → codec →
/// queued metadata → unambiguous extension. Lossy-looking unknowns
/// stay hidden rather than faked.
bool _isLosslessTrack(MediaItem track, AudioInfo? info) {
  if (info != null) {
    if (info.lossless) return true;
    if (_losslessCodecs.contains(info.codec.toLowerCase())) return true;
    if (_losslessCodecs.contains(info.format.toLowerCase())) return true;
  }
  final ex = track.extras;
  if (ex?['lossless'] == true) return true;
  final metaCodec = (ex?['codec'] as String?)?.toLowerCase() ?? '';
  if (_losslessCodecs.contains(metaCodec)) return true;
  final path = _trackFilePath(track);
  final dot = path.lastIndexOf('.');
  if (dot > 0 && dot < path.length - 1) {
    final ext = path.substring(dot + 1).toLowerCase();
    if (_losslessExtensions.contains(ext)) return true;
  }
  return false;
}

/// Caption under the wordmark, e.g. "FLAC · 24BIT · 48kHz".
String _losslessCaption(MediaItem track, AudioInfo? info) {
  final parts = <String>[];
  final codec =
      (info?.codec.isNotEmpty == true
              ? info!.codec
              : (track.extras?['codec'] as String? ?? ''))
          .toUpperCase();
  if (codec.isNotEmpty && codec != 'UNKNOWN') parts.add(codec);
  final bitDepth = info?.bitDepth ?? 0;
  if (bitDepth > 0) parts.add('${bitDepth}BIT');
  final sampleRate =
      info?.sampleRate ?? (track.extras?['sampleRate'] as int? ?? 0);
  if (sampleRate > 0) {
    final k = sampleRate / 1000;
    parts.add('${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}kHz');
  }
  if (parts.isEmpty) return 'LOSSLESS';
  return parts.join(' · ');
}

/// Lossless wordmark under the title (display only — no popup).
/// Renders nothing unless the track is genuinely lossless.
class LosslessBadge extends StatelessWidget {
  final MediaItem track;
  final AudioInfo? info;

  const LosslessBadge({required this.track, required this.info});

  @override
  Widget build(BuildContext context) {
    if (!_isLosslessTrack(track, info)) return const SizedBox.shrink();
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            isDark
                ? 'assets/lossless-wave-light.png'
                : 'assets/lossless-wave.png',
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.high_quality_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _losslessCaption(track, info),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
