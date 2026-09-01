import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_service.dart';
import '../../core/errors/exceptions.dart';
import '../../core/sync/sync_manager.dart';
import '../../domain/entities/playback_history.dart';
import '../api/history_api.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final api = ref.watch(historyApiProvider);
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncManagerProvider);
  return HistoryRepository(api, db, sync);
});

class HistoryRepository {
  final HistoryApi _api;
  final DatabaseService _db;
  final SyncManager _sync;
  // Debounce last play per song
  final Map<String, DateTime> _lastRecord = {};

  HistoryRepository(this._api, this._db, this._sync);

  Future<List<PlaybackHistoryItem>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final remote = await _api.getHistory(page: page, limit: limit);
      try {
        final db = await _db.database;
        final batch = db.batch();
        for (final h in remote) {
          batch.insert('history', {
            'id': '${h.songId}_${h.playedAt.millisecondsSinceEpoch}',
            'songId': h.songId,
            'playedAt': h.playedAt.millisecondsSinceEpoch,
            'duration': h.playDuration,
            'completion': h.completion,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      } catch (_) {}
      return remote;
    } catch (e) {
      if (e is NoInternetException) {
        final db = await _db.database;
        final rows = await db.query(
          'history',
          orderBy: 'playedAt DESC',
          limit: limit,
          offset: (page - 1) * limit,
        );
        return rows
            .map(
              (r) => PlaybackHistoryItem(
                songId: r['songId'] as String,
                playedAt: DateTime.fromMillisecondsSinceEpoch(
                  r['playedAt'] as int,
                ),
                playDuration: r['duration'] as int?,
                completion: (r['completion'] as num?)?.toDouble(),
              ),
            )
            .toList();
      }
      rethrow;
    }
  }

  Future<void> recordPlay(
    String songId, {
    int? duration,
    bool completed = false,
  }) async {
    final now = DateTime.now();
    final last = _lastRecord[songId];
    if (last != null && now.difference(last).inSeconds < 10 && !completed) {
      // Debounce: don't spam every second. Only allow if completed or 10s passed.
      return;
    }
    _lastRecord[songId] = now;
    try {
      // Real Nexora records recents automatically when a track is streamed
      // via /files/raw; this is a best-effort no-op + local mirror.
      await _api.recordPlay(songId, duration: duration, completed: completed);
      final db = await _db.database;
      await db.insert('history', {
        'id': '${songId}_${now.millisecondsSinceEpoch}',
        'songId': songId,
        'playedAt': now.millisecondsSinceEpoch,
        'duration': duration,
        'completion': completed ? 1.0 : 0.5,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation('RECORD_HISTORY', {
          'songId': songId,
          'playedAt': now.toIso8601String(),
          'duration': duration,
          'completed': completed,
        });
        final db = await _db.database;
        await db.insert('history', {
          'id': '${songId}_${now.millisecondsSinceEpoch}',
          'songId': songId,
          'playedAt': now.millisecondsSinceEpoch,
          'duration': duration,
          'completion': completed ? 1.0 : 0.5,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      }
      rethrow;
    }
  }
}
