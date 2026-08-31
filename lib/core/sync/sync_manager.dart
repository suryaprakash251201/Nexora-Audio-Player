import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../database/database_service.dart';

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

  // Enqueue a mutation for offline-first optimistic updates
  Future<void> enqueueOperation(String type, Map<String, dynamic> payload) async {
    final db = await _dbService.database;
    await db.insert('sync_ops', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(), // or UUID
      'operationType': type,
      'payload': jsonEncode(payload),
      'status': 'PENDING',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });
    
    // Trigger sync immediately if online
    processSyncQueue();
  }

  // Process the queue
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
        final payload = jsonDecode(op['payload'] as String);
        final retries = (op['retryCount'] as int?) ?? 0;

        try {
          // Map operations to API calls
          if (type == 'CREATE_PLAYLIST') {
            await _dio.post('/api/playlists', data: payload);
          } else if (type == 'ADD_TO_PLAYLIST') {
            final playlistId = payload['playlistId'];
            await _dio.post('/api/playlists/$playlistId/tracks', data: payload);
          }

          // If successful, remove from queue
          await db.delete('sync_ops', where: 'id = ?', whereArgs: [id]);
          
        } on DioException catch (e) {
          // If it's a 4xx error (except 401/429 maybe), it's a bad request, drop it.
          // Otherwise (network error, 500), increment retry and keep pending.
          if (e.response != null && e.response!.statusCode! >= 400 && e.response!.statusCode! < 500) {
            await db.update('sync_ops', {'status': 'FAILED'}, where: 'id = ?', whereArgs: [id]);
          } else {
            await db.update('sync_ops', {'retryCount': retries + 1}, where: 'id = ?', whereArgs: [id]);
          }
        } catch (e) {
           await db.update('sync_ops', {'retryCount': retries + 1}, where: 'id = ?', whereArgs: [id]);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
