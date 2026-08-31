import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../database/database_service.dart';
import '../logging/app_logger.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  final dbService = ref.watch(databaseProvider);
  return DownloadManager(dio, dbService);
});

class DownloadManager {
  final Dio _dio;
  final DatabaseService _dbService;
  final Map<String, double> _progress = {};

  DownloadManager(this._dio, this._dbService);

  double? progressOf(String trackId) => _progress[trackId];

  Future<String?> downloadTrack(String trackId, String streamUrl, {void Function(double)? onProgress}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/tracks');
      if (!await saveDir.exists()) await saveDir.create(recursive: true);
      final savePath = '${saveDir.path}/$trackId.mp3';

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
      return null;
    }
  }

  Future<void> removeTrackDownload(String trackId) async {
    final db = await _dbService.database;
    final result = await db.query('tracks', columns: ['localPath'], where: 'id = ?', whereArgs: [trackId]);
    if (result.isNotEmpty && result.first['localPath'] != null) {
      final file = File(result.first['localPath'] as String);
      if (await file.exists()) {
        try { await file.delete(); } catch (_) {}
      }
      await db.update('tracks', {'isDownloaded': 0, 'localPath': null}, where: 'id = ?', whereArgs: [trackId]);
      AppLogger.download('Removed download $trackId');
    }
  }

  Future<bool> isDownloaded(String trackId) async {
    final db = await _dbService.database;
    final r = await db.query('tracks', columns: ['isDownloaded', 'localPath'], where: 'id = ?', whereArgs: [trackId], limit: 1);
    if (r.isEmpty) return false;
    if ((r.first['isDownloaded'] as int? ?? 0) == 0) return false;
    final path = r.first['localPath'] as String?;
    if (path == null) return false;
    return File(path).existsSync();
  }

  Future<List<String>> downloadedIds() async {
    final db = await _dbService.database;
    final rows = await db.query('tracks', columns: ['id'], where: 'isDownloaded = ?', whereArgs: [1]);
    return rows.map((r) => r['id'] as String).toList();
  }
}
