import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_service.dart';
import '../../core/errors/exceptions.dart';
import '../../core/sync/sync_manager.dart';
import '../../domain/entities/playback_history.dart';
import '../../domain/entities/song.dart';
import '../api/history_api.dart';
import '../local/songs_local_datasource.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final api = ref.watch(historyApiProvider);
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncManagerProvider);
  final songsLocal = ref.watch(songsLocalDsProvider);
  return HistoryRepository(api, db, sync, songsLocal);
});

class HistoryRepository {
  final HistoryApi _api;
  final DatabaseService _db;
  final SyncManager _sync;
  final SongsLocalDataSource _songsLocal;
  // Debounce last play per song
  final Map<String, DateTime> _lastRecord = {};

  HistoryRepository(this._api, this._db, this._sync, this._songsLocal);

  /// History = server /recents merged with tracks this app actually played
  /// (recorded locally). Merging is what makes "Recently Played" reflect real
  /// in-app playback immediately instead of waiting for the server index.
  Future<List<PlaybackHistoryItem>> getHistory({
    int page = 1,
    int limit = 20,
  }) async {
    Object? remoteError;
    final remote = <PlaybackHistoryItem>[];

    try {
      final items = await _api.getHistory(page: page, limit: limit);
      remote.addAll(items);
      try {
        await _songsLocal.cacheSongs(
          remote.map((item) => item.song).whereType<Song>().toList(),
        );
      } catch (_) {}
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
    } catch (e) {
      remoteError = e;
    }

    final local = await _localHistory(limit: limit * 3);

    // Merge newest-first, keeping only the most recent entry per song.
    final merged = <String, PlaybackHistoryItem>{};
    void add(PlaybackHistoryItem item) {
      final existing = merged[item.songId];
      if (existing == null || item.playedAt.isAfter(existing.playedAt)) {
        merged[item.songId] = item;
      }
    }

    for (final item in remote) {
      add(item);
    }
    for (final item in local) {
      add(item);
    }

    final list = merged.values.toList()
      ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

    if (list.isEmpty && remoteError != null) {
      // Only surface the error when we truly have nothing to show.
      // ignore: use_rethrow_when_possible
      throw remoteError;
    }

    // Drop entries we cannot render or play at all.
    return list
        .where(
          (h) => h.song != null && (h.song!.streamUrl?.isNotEmpty ?? false),
        )
        .take(limit)
        .toList();
  }

  /// Rows written by [recordPlay] (in-app plays), resolved to real songs.
  Future<List<PlaybackHistoryItem>> _localHistory({int limit = 60}) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'history',
        orderBy: 'playedAt DESC',
        limit: limit,
      );
      final out = <PlaybackHistoryItem>[];
      for (final r in rows) {
        final songId = (r['songId'] ?? '').toString();
        if (songId.isEmpty) continue;
        final playedAt = DateTime.fromMillisecondsSinceEpoch(
          (r['playedAt'] as int?) ?? 0,
        );
        // Resolve full song metadata (artwork + stream URL) from local cache.
        final song = await _songsLocal.getSong(songId);
        if (song == null) continue;
        out.add(
          PlaybackHistoryItem(
            songId: songId,
            song: song,
            playedAt: playedAt,
            playDuration: r['duration'] as int?,
            completion: (r['completion'] as num?)?.toDouble(),
          ),
        );
      }
      return out;
    } catch (_) {
      return [];
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
