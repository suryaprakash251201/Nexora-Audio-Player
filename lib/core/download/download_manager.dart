import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../database/database_service.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  final dbService = ref.watch(databaseProvider);
  return DownloadManager(dio, dbService);
});

class DownloadManager {
  final Dio _dio;
  final DatabaseService _dbService;

  DownloadManager(this._dio, this._dbService);

  Future<void> downloadTrack(String trackId, String streamUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/tracks/$trackId.mp3';

      await Directory('${dir.path}/tracks').create(recursive: true);

      await _dio.download(
        streamUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Can broadcast progress to UI via Riverpod streams here
            // final progress = (received / total * 100).toStringAsFixed(0);
          }
        },
      );

      // Update Database
      final db = await _dbService.database;
      await db.update(
        'tracks',
        {
          'isDownloaded': 1,
          'localPath': savePath,
        },
        where: 'id = ?',
        whereArgs: [trackId],
      );

    } catch (e) {
      // Handle download failure (could add to a failed queue)
      debugPrint('Download failed for track $trackId: $e');
    }
  }

  Future<void> removeTrackDownload(String trackId) async {
    final db = await _dbService.database;
    final result = await db.query('tracks', columns: ['localPath'], where: 'id = ?', whereArgs: [trackId]);
    
    if (result.isNotEmpty && result.first['localPath'] != null) {
      final file = File(result.first['localPath'] as String);
      if (await file.exists()) {
        await file.delete();
      }
      
      await db.update(
        'tracks',
        {
          'isDownloaded': 0,
          'localPath': null,
        },
        where: 'id = ?',
        whereArgs: [trackId],
      );
    }
  }
}
