import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    String trackId,
    String streamUrl, {
    void Function(double)? onProgress,
  }) async {
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

      final db = await _dbService.database;
      await db.update(
        'tracks',
        {'isDownloaded': 1, 'localPath': savePath},
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
    }
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
      columns: ['id'],
      where: 'isDownloaded = ?',
      whereArgs: [1],
    );
    return rows.map((r) => r['id'] as String).toList();
  }

  /// Downloaded tracks with full metadata for the Downloads screen.
  Future<List<Song>> downloadedTracks() async {
    final db = await _dbService.database;
    final rows = await db.query(
      'tracks',
      where: 'isDownloaded = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );
    return rows
        .map(
          (r) => Song(
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
            localPath: r['localPath'] as String?,
          ),
        )
        .toList();
  }
}
