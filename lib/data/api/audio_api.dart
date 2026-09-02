import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/song.dart';

/// Audio metadata returned by /audio/info
class AudioInfo {
  final String codec;
  final String codecLong;
  final int sampleRate;
  final int bitDepth;
  final int channels;
  final String channelLayout;
  final int bitRate;
  final double duration;
  final String format;
  final bool lossless;

  AudioInfo({
    required this.codec,
    required this.codecLong,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.channelLayout,
    required this.bitRate,
    required this.duration,
    required this.format,
    required this.lossless,
  });

  factory AudioInfo.fromJson(Map<String, dynamic> json) => AudioInfo(
    codec: json['codec'] as String? ?? 'Unknown',
    codecLong: json['codec_long'] as String? ?? '',
    sampleRate: json['sample_rate'] as int? ?? 0,
    bitDepth: json['bit_depth'] as int? ?? 0,
    channels: json['channels'] as int? ?? 0,
    channelLayout: json['channel_layout'] as String? ?? '',
    bitRate: (json['bit_rate'] as num?)?.toInt() ?? 0,
    duration: (json['duration'] as num?)?.toDouble() ?? 0,
    format: json['format'] as String? ?? '',
    lossless: json['lossless'] as bool? ?? false,
  );

  String get qualityLabel {
    final parts = <String>[];
    if (codec.isNotEmpty) parts.add(codec.toUpperCase());
    if (sampleRate > 0) {
      final k = sampleRate / 1000;
      parts.add(k >= 48 ? '${k.toInt()}kHz Hi-Res' : '${k.toInt()}kHz');
    }
    if (bitDepth > 0) parts.add('${bitDepth}bit');
    if (lossless) parts.add('Lossless');
    if (bitRate > 0) parts.add('${(bitRate / 1000).round()}kbps');
    return parts.join(' · ');
  }

  String get shortLabel {
    if (codec.isEmpty) return 'Unknown';
    final parts = <String>[codec.toUpperCase()];
    if (sampleRate > 0) {
      final k = sampleRate / 1000;
      parts.add(k >= 48 ? '${k.toInt()}kHz' : '${k.toInt()}kHz');
    }
    if (bitDepth > 0) parts.add('${bitDepth}bit');
    return parts.join(' ');
  }
}

class AudioApi {
  final ApiClient _client;
  final SecureStorageService _storage;

  AudioApi(this._client, this._storage);

  Future<String> _base() async {
    final url = await _storage.getServerUrl();
    if (url == null || url.isEmpty) {
      throw Exception('Server URL not configured');
    }
    return url;
  }

  /// Fetch rich audio metadata via ffprobe.
  Future<AudioInfo> getInfo(String rootId, String path) async {
    final base = await _base();
    final res = await _client.get(
      '${base}${ApiConstants.audioInfo}',
      query: {'root': rootId, 'path': path},
    );
    return AudioInfo.fromJson(res.data as Map<String, dynamic>);
  }
}

final audioApiProvider = Provider<AudioApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return AudioApi(c, s);
});

/// Fetches audio metadata for a song (or null if unavailable).
final audioInfoProvider = FutureProvider.family<AudioInfo?, Song>((
  ref,
  song,
) async {
  if (song.rootId == null || song.rootId!.isEmpty) return null;
  try {
    final api = ref.watch(audioApiProvider);
    final path = song.id; // or song.streamUrl ?? song.id
    return await api.getInfo(song.rootId!, path);
  } catch (_) {
    return null;
  }
});
