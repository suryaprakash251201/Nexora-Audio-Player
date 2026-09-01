import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../database/database_service.dart';
import '../logging/app_logger.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final dio = ref.watch(apiClientProvider).client;
  final dbService = ref.watch(databaseProvider);
  return SyncManager(dio, dbService);
});

class SyncManager {
  final Dio _dio;
  final DatabaseService _dbService;
  bool _isSyncing = false;

  SyncManager(this._dio, this._dbService);

  Future<void> enqueueOperation(
    String type,
    Map<String, dynamic> payload,
  ) async {
    final db = await _dbService.database;
    await db.insert('sync_ops', {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${type}',
      'operationType': type,
      'payload': jsonEncode(payload),
      'status': 'PENDING',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });
    AppLogger.sync('Enqueued $type');
    // Fire-and-forget with error handling to prevent unhandled async exceptions
    processSyncQueue().catchError((e) {
      AppLogger.sync('processSyncQueue error: $e');
    });
  }

  Future<void> processSyncQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final db = await _dbService.database;
      final ops = await db.query(
        'sync_ops',
        where: 'status = ?',
        whereArgs: ['PENDING'],
        orderBy: 'createdAt ASC',
      );

      for (final op in ops) {
        final id = op['id'] as String;
        final type = op['operationType'] as String;
        final payload =
            jsonDecode(op['payload'] as String) as Map<String, dynamic>;
        final retries = (op['retryCount'] as int?) ?? 0;

        try {
          await _execute(type, payload);
          await db.delete('sync_ops', where: 'id = ?', whereArgs: [id]);
          AppLogger.sync('✓ $type synced');
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          if (code != null &&
              code >= 400 &&
              code < 500 &&
              code != 401 &&
              code != 429) {
            await db.update(
              'sync_ops',
              {'status': 'FAILED'},
              where: 'id = ?',
              whereArgs: [id],
            );
            AppLogger.sync('✗ $type failed permanent $code');
          } else {
            await db.update(
              'sync_ops',
              {'retryCount': retries + 1},
              where: 'id = ?',
              whereArgs: [id],
            );
            AppLogger.sync('↻ $type retry $retries');
            if (code == null || code >= 500) {
              // Stop on network/server error to avoid hammering
              break;
            }
          }
        } catch (e) {
          await db.update(
            'sync_ops',
            {'retryCount': retries + 1},
            where: 'id = ?',
            whereArgs: [id],
          );
          AppLogger.sync('↻ $type error $e');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _execute(String type, Map<String, dynamic> p) async {
    switch (type) {
      case 'CREATE_PLAYLIST':
        await _dio.post(
          '/playlists',
          data: {'name': p['name'], 'description': p['description']},
        );
        break;
      case 'DELETE_PLAYLIST':
        await _dio.delete('/playlists/${p['playlistId']}');
        break;
      case 'ADD_TO_PLAYLIST':
        await _dio.post(
          '/playlists/${p['playlistId']}/tracks',
          data: {'songId': p['songId']},
        );
        break;
      case 'ADD_TRACKS_TO_PLAYLIST':
        await _dio.post(
          '/playlists/${p['playlistId']}/tracks',
          data: {'songIds': p['songIds']},
        );
        break;
      case 'REMOVE_FROM_PLAYLIST':
        await _dio.delete(
          '/playlists/${p['playlistId']}/tracks/${p['songId']}',
        );
        break;
      case 'REORDER_PLAYLIST':
        await _dio.put(
          '/playlists/${p['playlistId']}/reorder',
          data: {'orderedIds': p['orderedIds']},
        );
        break;
      case 'ADD_FAVORITE':
        // songId is "rootId|path" on the real Nexora file server
        final parts = (p['songId'] as String).split('|');
        await _dio.post(
          '/favorites',
          data: {'root': parts.first, 'path': parts.skip(1).join('|')},
        );
        break;
      case 'REMOVE_FAVORITE':
        final rparts = (p['songId'] as String).split('|');
        await _dio.delete(
          '/favorites',
          queryParameters: {
            'root': rparts.first,
            'path': rparts.skip(1).join('|'),
          },
        );
        break;
      case 'RECORD_HISTORY':
        // Recorded server-side on /files/raw access; nothing to POST.
        break;
      default:
        AppLogger.sync('Unknown op $type');
        break;
    }
  }

  Future<int> pendingCount() async {
    final db = await _dbService.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as c FROM sync_ops WHERE status = ?',
      ['PENDING'],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> clearFailed() async {
    final db = await _dbService.database;
    await db.delete('sync_ops', where: 'status = ?', whereArgs: ['FAILED']);
  }
}
