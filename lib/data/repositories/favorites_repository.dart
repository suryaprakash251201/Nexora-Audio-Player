import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_service.dart';
import '../../core/errors/exceptions.dart';
import '../../core/sync/sync_manager.dart';
import '../../domain/entities/song.dart';
import '../api/favorites_api.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final api = ref.watch(favoritesApiProvider);
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncManagerProvider);
  return FavoritesRepository(api, db, sync);
});

class FavoritesRepository {
  final FavoritesApi _api;
  final DatabaseService _db;
  final SyncManager _sync;
  FavoritesRepository(this._api, this._db, this._sync);

  Future<List<Song>> getFavorites() async {
    try {
      final remote = await _api.getFavorites();
      // Cache locally
      try {
        final db = await _db.database;
        await db.delete('favorites');
        final batch = db.batch();
        for (final s in remote) {
          batch.insert('favorites', {'songId': s.id, 'addedAt': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
          batch.insert('tracks', {'id': s.id, 'title': s.title, 'artist': s.artist, 'album': s.album, 'duration': s.duration, 'coverUrl': s.coverUrl, 'updatedAt': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      } catch (_) {}
      return remote;
    } catch (e) {
      if (e is NoInternetException) {
        final db = await _db.database;
        final rows = await db.query('favorites', orderBy: 'addedAt DESC');
        final songs = <Song>[];
        for (final r in rows) {
          final tid = r['songId'] as String;
          final tr = await db.query('tracks', where: 'id = ?', whereArgs: [tid], limit: 1);
          if (tr.isNotEmpty) {
            final t = tr.first;
            songs.add(Song(id: t['id'] as String, title: t['title'] as String, artist: t['artist'] as String?, album: t['album'] as String?, duration: t['duration'] as int?, coverUrl: t['coverUrl'] as String?, isFavorite: true));
          }
        }
        return songs;
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite(String songId, bool isFavorite) async {
    // Optimistic local
    final db = await _db.database;
    if (isFavorite) {
      await db.delete('favorites', where: 'songId = ?', whereArgs: [songId]);
    } else {
      await db.insert('favorites', {'songId': songId, 'addedAt': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    try {
      if (isFavorite) {
        await _api.removeFavorite(songId);
      } else {
        await _api.addFavorite(songId);
      }
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation(isFavorite ? 'REMOVE_FAVORITE' : 'ADD_FAVORITE', {'songId': songId});
        return;
      }
      // Rollback
      if (isFavorite) {
        await db.insert('favorites', {'songId': songId, 'addedAt': DateTime.now().millisecondsSinceEpoch}, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await db.delete('favorites', where: 'songId = ?', whereArgs: [songId]);
      }
      rethrow;
    }
  }

  Future<bool> isFavorite(String songId) async {
    final db = await _db.database;
    final rows = await db.query('favorites', where: 'songId = ?', whereArgs: [songId], limit: 1);
    if (rows.isNotEmpty) return true;
    try {
      final remote = await getFavorites();
      return remote.any((s) => s.id == songId);
    } catch (_) {
      return false;
    }
  }
}
