import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/song.dart';

int _asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  final s = v.toString().trim();
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

double _asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

String _asString(dynamic v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

List<String> _asStringList(dynamic v) {
  if (v == null) return const [];
  if (v is List) {
    return [
      for (final e in v)
        if (e != null && e.toString().trim().isNotEmpty) e.toString().trim(),
    ];
  }
  final s = v.toString().trim();
  return s.isEmpty ? const [] : [s];
}

/// Audio metadata returned by GET /api/v1/audio/info.
///
/// Null-safe: every new server field is optional so old servers / partial
/// probes keep working. Legacy codec fields stay for compat.
class AudioInfo {
  // Legacy codec/probe fields.
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

  // Normalized container + tag fields (server c8eaa6a+).
  final String? container;
  final String? extension;
  final String? title;
  final String? artist;
  final List<String> artists;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final List<String> genres;
  final int? year;
  final String? date;
  final int? trackNo;
  final int? trackTotal;
  final int? discNo;
  final int? discTotal;
  final String? composer;
  final String? performer;
  final String? publisher;
  final int? bpm;
  final String? musicalKey;
  final String? comment;
  final bool hasCover;
  final Map<String, dynamic> tags;

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
    this.container,
    this.extension,
    this.title,
    this.artist,
    this.artists = const [],
    this.album,
    this.albumArtist,
    this.genre,
    this.genres = const [],
    this.year,
    this.date,
    this.trackNo,
    this.trackTotal,
    this.discNo,
    this.discTotal,
    this.composer,
    this.performer,
    this.publisher,
    this.bpm,
    this.musicalKey,
    this.comment,
    this.hasCover = false,
    this.tags = const {},
  });

  factory AudioInfo.fromJson(Map<String, dynamic> json) => AudioInfo(
    codec: _asString(json['codec'], 'Unknown'),
    codecLong: _asString(json['codec_long']),
    sampleRate: _asInt(json['sample_rate']),
    bitDepth: _asInt(json['bit_depth']),
    channels: _asInt(json['channels']),
    channelLayout: _asString(json['channel_layout']),
    bitRate: _asInt(json['bit_rate']),
    duration: _asDouble(json['duration']),
    format: _asString(json['format']),
    lossless: json['lossless'] as bool? ?? false,
    container: _asStringOrNull(json['container']),
    extension: _asStringOrNull(json['extension']),
    title: _asStringOrNull(json['title']),
    artist: _asStringOrNull(json['artist']),
    artists: _asStringList(json['artists']),
    album: _asStringOrNull(json['album']),
    albumArtist: _asStringOrNull(json['album_artist']),
    genre: _asStringOrNull(json['genre']),
    genres: _asStringList(json['genres']),
    year: _asIntOrNull(json['year']),
    date: _asStringOrNull(json['date']),
    trackNo: _asIntOrNull(json['track_no']),
    trackTotal: _asIntOrNull(json['track_total']),
    discNo: _asIntOrNull(json['disc_no']),
    discTotal: _asIntOrNull(json['disc_total']),
    composer: _asStringOrNull(json['composer']),
    performer: _asStringOrNull(json['performer']),
    publisher: _asStringOrNull(json['publisher']),
    bpm: _asIntOrNull(json['bpm']),
    musicalKey: _asStringOrNull(json['musical_key']),
    comment: _asStringOrNull(json['comment']),
    hasCover: json['has_cover'] as bool? ?? false,
    tags: json['tags'] is Map
        ? Map<String, dynamic>.from(json['tags'] as Map)
        : const {},
  );

  /// First usable artist: `artist`, else first entry of `artists[]`.
  String? get effectiveArtist {
    if (artist != null && artist!.trim().isNotEmpty) return artist!.trim();
    for (final a in artists) {
      if (a.trim().isNotEmpty) return a.trim();
    }
    return null;
  }

  /// First usable genre: `genre`, else first entry of `genres[]`.
  String? get effectiveGenre {
    if (genre != null && genre!.trim().isNotEmpty) return genre!.trim();
    for (final g in genres) {
      if (g.trim().isNotEmpty) return g.trim();
    }
    return null;
  }

  /// Year, falling back to the leading 4 digits of `date` (e.g. 2021-06-01).
  int? get effectiveYear {
    if (year != null && year! > 0) return year;
    final d = date?.trim() ?? '';
    if (d.length >= 4) {
      final y = int.tryParse(d.substring(0, 4));
      if (y != null && y > 0) return y;
    }
    return null;
  }

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

/// One item of POST /audio/info/batch response.
class AudioInfoBatchEntry {
  final String root;
  final String path;
  final bool ok;
  final AudioInfo? info;
  final String? error;

  const AudioInfoBatchEntry({
    required this.root,
    required this.path,
    required this.ok,
    this.info,
    this.error,
  });

  /// Canonical song id ("root|path") matching [NexoraFiles.songId].
  String get songId => '$root|$path';
}

/// Formats advertised by GET /api/v1/audio/formats.
class AudioFormats {
  final bool ffmpeg;
  final bool transcode;
  final Map<String, dynamic> formats;
  final List<String> containers;
  final List<String> lossless;

  const AudioFormats({
    this.ffmpeg = false,
    this.transcode = false,
    this.formats = const {},
    this.containers = const [],
    this.lossless = const [],
  });

  factory AudioFormats.fromJson(Map<String, dynamic> json) => AudioFormats(
    ffmpeg: json['ffmpeg'] as bool? ?? false,
    transcode: json['transcode'] as bool? ?? false,
    formats: json['formats'] is Map
        ? Map<String, dynamic>.from(json['formats'] as Map)
        : const {},
    containers: _asStringList(json['containers']),
    lossless: _asStringList(json['lossless']),
  );
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
      '$base${ApiConstants.audioInfo}',
      query: {'root': rootId, 'path': path},
    );
    return AudioInfo.fromJson(res.data as Map<String, dynamic>);
  }

  /// Batch metadata for up to 50 tracks per call (server limit).
  ///
  /// Returns entries in server order; failures inside [items] surface as
  /// `ok: false` entries rather than throwing, so callers can merge
  /// whatever succeeded. Larger inputs are chunked automatically.
  Future<List<AudioInfoBatchEntry>> getInfoBatch(
    List<({String root, String path})> items,
  ) async {
    if (items.isEmpty) return const [];
    final base = await _base();
    final out = <AudioInfoBatchEntry>[];
    for (var i = 0; i < items.length; i += 50) {
      final chunk = items.sublist(
        i,
        (i + 50) > items.length ? items.length : i + 50,
      );
      final res = await _client.post(
        '$base${ApiConstants.audioInfoBatch}',
        data: {
          'items': [
            for (final c in chunk) {'root': c.root, 'path': c.path},
          ],
        },
      );
      final data = res.data;
      final list =
          (data is Map<String, dynamic> ? data['items'] as List? : null) ??
          (data is List ? data : const []);
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final root = (raw['root'] ?? '').toString();
        final path = (raw['path'] ?? '').toString();
        final ok = raw['ok'] == true;
        AudioInfo? info;
        final rawInfo = raw['info'];
        if (ok && rawInfo is Map<String, dynamic>) {
          try {
            info = AudioInfo.fromJson(rawInfo);
          } catch (_) {
            info = null;
          }
        }
        out.add(
          AudioInfoBatchEntry(
            root: root,
            path: path,
            ok: ok && info != null,
            info: info,
            error: (raw['error'] ?? '').toString().isEmpty
                ? null
                : (raw['error'] ?? '').toString(),
          ),
        );
      }
    }
    return out;
  }

  /// Server transcode/format capabilities (best-effort, null when unknown).
  Future<AudioFormats?> getFormats() async {
    try {
      final base = await _base();
      final res = await _client.get('$base${ApiConstants.audioFormats}');
      final data = res.data;
      if (data is Map<String, dynamic>) return AudioFormats.fromJson(data);
      return null;
    } catch (_) {
      return null;
    }
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
