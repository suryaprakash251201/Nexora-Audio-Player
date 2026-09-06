import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/logging/app_logger.dart';
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

/// On-device system music: Android MediaStore + iOS MPMediaLibrary.
///
/// Playback needs no new engine work — [Song.localPath] / [Song.streamUrl]
/// flow through the existing queue → audio_handler file/asset playback.
class DeviceMusicService {
  final OnAudioQuery _query = OnAudioQuery();

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
