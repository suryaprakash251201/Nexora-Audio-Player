import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/song.dart';
import '../network/api_client.dart';
import '../database/database_service.dart';
import '../logging/app_logger.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  final dbService = ref.watch(databaseProvider);
  return DownloadManager(dio, dbService);
});

/// Live set of downloaded track ids, mirrored from the `tracks` table.
/// Rows and menus read this synchronously so download affordances stay
/// consistent without per-row DB queries.
final downloadedIdsProvider =
    StateNotifierProvider<DownloadedIdsNotifier, Set<String>>(
      (ref) => DownloadedIdsNotifier(ref.watch(downloadManagerProvider)),
    );

class DownloadedIdsNotifier extends StateNotifier<Set<String>> {
  final DownloadManager _manager;
  DownloadedIdsNotifier(this._manager) : super(const {}) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      state = (await _manager.downloadedIds()).toSet();
    } catch (_) {}
  }

  void markDownloaded(String id) => state = {...state, id};
  void markRemoved(String id) => state = {...state}..remove(id);
}

class DownloadManager {
  final Dio _dio;
  final DatabaseService _dbService;
  final Map<String, double> _progress = {};

  DownloadManager(this._dio, this._dbService);

  double? progressOf(String trackId) => _progress[trackId];

  /// Flat, filesystem-safe file name for a track id. Raw ids contain
  /// `|` and `/` (root + nested path) which would otherwise resolve to
  /// non-existent subdirectories and fail every nested download.
  static String fileNameFor(String trackId) {
    var stem = trackId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (stem.length > 100) stem = stem.substring(stem.length - 100);
    final hash = trackId.hashCode.toUnsigned(32).toRadixString(16);
    return '${stem}_$hash.mp3';
  }

  Future<String?> downloadTrack(
    Song song,
    String streamUrl, {
    void Function(double)? onProgress,
  }) async {
    final trackId = song.id;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/tracks');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/${fileNameFor(trackId)}';

      AppLogger.download('Downloading $trackId from $streamUrl');

      await _dio.download(
        streamUrl,
        savePath,
        options: Options(headers: _dio.options.headers),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final p = received / total;
            _progress[trackId] = p;
            onProgress?.call(p);
          }
        },
      );

      // Upsert (never bare UPDATE): library songs usually have no local row
      // yet, and REPLACE would cascade-delete playlist_items for this id.
      final db = await _dbService.database;
      final values = {
        'id': trackId,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'duration': song.duration,
        'coverUrl': song.coverUrl ?? song.artworkUrl,
        'streamUrl': song.streamUrl ?? streamUrl,
        'codec': song.codec,
        'bitrate': song.bitrate,
        'sampleRate': song.sampleRate,
        'isDownloaded': 1,
        'localPath': savePath,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await db.insert(
        'tracks',
        values,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await db.update(
        'tracks',
        Map.of(values)..remove('id'),
        where: 'id = ?',
        whereArgs: [trackId],
      );
      _progress.remove(trackId);
      AppLogger.download('✓ Downloaded $trackId');
      return savePath;
    } catch (e) {
      AppLogger.download('✗ Download failed $trackId: $e');
      _progress.remove(trackId);
      // Clean up partially downloaded file to prevent storage leaks
      try {
        final dir = await getApplicationDocumentsDirectory();
        final partialFile = File('${dir.path}/tracks/${fileNameFor(trackId)}');
        if (await partialFile.exists()) {
          await partialFile.delete();
          AppLogger.download('Cleaned up partial file for $trackId');
        }
      } catch (_) {}
      return null;
    }
  }

  Future<void> removeTrackDownload(String trackId) async {
    final db = await _dbService.database;
    final result = await db.query(
      'tracks',
      columns: ['localPath'],
      where: 'id = ?',
      whereArgs: [trackId],
    );
    if (result.isNotEmpty && result.first['localPath'] != null) {
      final file = File(result.first['localPath'] as String);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      await db.update(
        'tracks',
        {'isDownloaded': 0, 'localPath': null},
        where: 'id = ?',
        whereArgs: [trackId],
      );
      AppLogger.download('Removed download $trackId');
      return;
    }
    // Orphaned file (row missing but bytes on disk) — still delete it.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final orphan = File('${dir.path}/tracks/${fileNameFor(trackId)}');
      if (await orphan.exists()) {
        await orphan.delete();
        AppLogger.download('Removed orphaned download $trackId');
      }
    } catch (_) {}
  }

  Future<bool> isDownloaded(String trackId) async {
    final db = await _dbService.database;
    final r = await db.query(
      'tracks',
      columns: ['isDownloaded', 'localPath'],
      where: 'id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    if (r.isEmpty) return false;
    if ((r.first['isDownloaded'] as int? ?? 0) == 0) return false;
    final path = r.first['localPath'] as String?;
    if (path == null) return false;
    return File(path).existsSync();
  }

  Future<List<String>> downloadedIds() async {
    final db = await _dbService.database;
    final rows = await db.query(
      'tracks',
      columns: ['id', 'localPath'],
      where: 'isDownloaded = ?',
      whereArgs: [1],
    );
    // Drop ghosts: flag set but bytes gone (OS cleanup / manual delete).
    final ids = <String>[];
    for (final r in rows) {
      final path = r['localPath'] as String?;
      if (path != null && File(path).existsSync()) {
        ids.add(r['id'] as String);
      }
    }
    return ids;
  }

  /// Downloaded tracks with full metadata for the Downloads screen.
  /// Rows whose file is missing are skipped (never show unplayable ghosts).
  Future<List<Song>> downloadedTracks() async {
    final db = await _dbService.database;
    final rows = await db.query(
      'tracks',
      where: 'isDownloaded = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    final out = <Song>[];
    for (final r in rows) {
      final path = r['localPath'] as String?;
      if (path == null || !File(path).existsSync()) continue;
      out.add(
        Song(
          id: r['id'] as String,
          title: (r['title'] as String?) ?? 'Unknown',
          artist: r['artist'] as String?,
          album: r['album'] as String?,
          duration: r['duration'] as int?,
          coverUrl: r['coverUrl'] as String?,
          streamUrl: r['streamUrl'] as String?,
          codec: r['codec'] as String?,
          bitrate: r['bitrate'] as int?,
          sampleRate: r['sampleRate'] as int?,
          isDownloaded: true,
          localPath: path,
        ),
      );
    }
    return out;
  }

  /// Total bytes of downloaded audio on disk.
  Future<int> downloadsSizeBytes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/tracks');
      if (!await saveDir.exists()) return 0;
      var total = 0;
      await for (final e in saveDir.list()) {
        if (e is File) {
          try {
            total += await e.length();
          } catch (_) {}
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Delete every downloaded audio file and reset all download flags.
  /// Library metadata, playlists, favorites and history are untouched.
  Future<void> deleteAllDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/tracks');
      if (await saveDir.exists()) {
        await for (final e in saveDir.list()) {
          try {
            if (e is File) await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
    try {
      final db = await _dbService.database;
      await db.update(
        'tracks',
        {'isDownloaded': 0, 'localPath': null},
        where: 'isDownloaded = ?',
        whereArgs: [1],
      );
    } catch (_) {}
    AppLogger.download('Deleted all downloads');
  }
}
