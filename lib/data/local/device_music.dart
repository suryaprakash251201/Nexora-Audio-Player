import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/logging/app_logger.dart';
import '../../core/storage/local_artwork_cache.dart';
import '../../domain/entities/song.dart';

final deviceMusicProvider = Provider<DeviceMusicService>((ref) {
  return DeviceMusicService();
});

/// Whether the OS granted media-library access (no prompt here — the
/// songs provider returns [] when denied so the UI can show the grant
/// card instead of a spinner).
final deviceMusicPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.watch(deviceMusicProvider).hasPermission();
});

/// On-device songs (system music library). Empty when permission is
/// denied, the platform has no music, or the query fails.
final deviceSongsProvider = FutureProvider<List<Song>>((ref) async {
  return ref.watch(deviceMusicProvider).loadSongs();
});

/// Cached file:// artwork URI for one on-device song (by platform media
/// id), or null while loading / when the track has no embedded art.
/// Disk cache survives restarts; memory map dedupes in-flight rows.
final deviceArtworkProvider = FutureProvider.family<String?, int>((
  ref,
  mediaId,
) async {
  return ref.watch(deviceMusicProvider).artworkUri(mediaId);
});

/// Platform media id behind a device song id (`device_<id>`), or null
/// for anything else. Pure + unit-tested.
int? deviceMediaIdOf(Song song) {
  const prefix = 'device_';
  if (!song.id.startsWith(prefix)) return null;
  return int.tryParse(song.id.substring(prefix.length));
}

/// On-device system music: Android MediaStore + iOS MPMediaLibrary.
///
/// Playback needs no new engine work — [Song.localPath] / [Song.streamUrl]
/// flow through the existing queue → audio_handler file/asset playback.
class DeviceMusicService {
  final OnAudioQuery _query;
  final Map<int, String?> _artworkMem = {};

  DeviceMusicService({OnAudioQuery? query}) : _query = query ?? OnAudioQuery();

  Future<bool> hasPermission() async {
    try {
      return await _query.permissionsStatus();
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      return await _query.permissionsRequest(retryRequest: true);
    } catch (_) {
      return false;
    }
  }

  Future<List<Song>> loadSongs() async {
    try {
      if (!await hasPermission()) return const [];
      final models = await _query.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      final android = defaultTargetPlatform == TargetPlatform.android;
      return deviceSongsFromModels(models, android: android);
    } catch (e) {
      AppLogger.cache('Device music query failed: $e');
      return const [];
    }
  }

  /// Embedded artwork for one platform song, cached to a temp file.
  /// Small JPEG keeps rows light; failures degrade to null (placeholder).
  Future<String?> artworkUri(int mediaId) async {
    if (_artworkMem.containsKey(mediaId)) return _artworkMem[mediaId];
    try {
      final fileName = '$mediaId.jpg';
      final hit = await readCachedArtworkUri(fileName);
      if (hit != null) {
        _artworkMem[mediaId] = hit;
        return hit;
      }
      final bytes = await _query.queryArtwork(
        mediaId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 200,
      );
      if (bytes == null || bytes.isEmpty) {
        _artworkMem[mediaId] = null;
        return null;
      }
      final uri = await writeCachedArtwork(fileName, bytes);
      _artworkMem[mediaId] = uri;
      return uri;
    } catch (e) {
      AppLogger.cache('Device artwork failed for $mediaId: $e');
      _artworkMem[mediaId] = null;
      return null;
    }
  }
}

/// Filters non-music clutter (ringtones, podcasts, alarms) and maps the
/// rest. Pure + unit-tested.
List<Song> deviceSongsFromModels(
  List<SongModel> models, {
  required bool android,
}) {
  return [
    for (final m in models)
      if (m.isMusic ?? true) deviceSongFromModel(m, android: android),
  ];
}

/// Maps one platform song to the domain entity. Pure + unit-tested.
///
/// Android `data` is a file path → played via [Song.localPath] (Uri.file).
/// iOS `data` is an `ipod-library://` asset URL → played via
/// [Song.streamUrl] (AVPlayer resolves it; raw file access is sandboxed
/// away on iOS). [Song.rootId] stays empty so server-only features
/// (lyrics, audio-info) are skipped for device tracks.
@visibleForTesting
Song deviceSongFromModel(SongModel m, {required bool android}) {
  final data = m.data;
  final durationSec = m.duration != null ? (m.duration! / 1000).round() : null;
  final title = _nonEmpty(m.title) ?? m.displayNameWOExt;
  final artist = _nonEmpty(m.artist);
  final album = _nonEmpty(m.album);
  if (android) {
    return Song(
      id: 'device_${m.id}',
      title: title,
      artist: artist,
      album: album,
      duration: durationSec,
      trackNumber: m.track,
      genre: _nonEmpty(m.genre),
      fileSize: m.size,
      localPath: data,
      streamUrl: Uri.file(data).toString(),
      rootId: '',
    );
  }
  return Song(
    id: 'device_${m.id}',
    title: title,
    artist: artist,
    album: album,
    duration: durationSec,
    trackNumber: m.track,
    genre: _nonEmpty(m.genre),
    fileSize: m.size,
    streamUrl: data,
    rootId: '',
  );
}

/// MediaStore uses "<unknown>" for missing metadata — normalize to null
/// so rows fall back to "Unknown Artist" styling instead of printing it.
String? _nonEmpty(String? v) {
  if (v == null) return null;
  final t = v.trim();
  if (t.isEmpty || t == '<unknown>') return null;
  return t;
}
