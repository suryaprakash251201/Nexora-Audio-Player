import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_service.dart';
import '../../core/errors/exceptions.dart';
import '../../core/sync/sync_manager.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../api/playlists_api.dart';

final playlistsRepositoryProvider = Provider<PlaylistsRepository>((ref) {
  final api = ref.watch(playlistsApiProvider);
  final db = ref.watch(databaseProvider);
  final sync = ref.watch(syncManagerProvider);
  return PlaylistsRepository(api, db, sync);
});

class PlaylistsRepository {
  final PlaylistsApi _api;
  final DatabaseService _dbService;
  final SyncManager _sync;
  PlaylistsRepository(this._api, this._dbService, this._sync);

  Future<List<Playlist>> getPlaylists() async {
    try {
      final remote = await _api.getPlaylists();
      // Cache
      try {
        final db = await _dbService.database;
        final batch = db.batch();
        for (final p in remote) {
          batch.insert('playlists', {
            'id': p.id,
            'name': p.name,
            'description': p.description,
            'coverUrl': p.coverUrl,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      } catch (_) {}
      return remote;
    } catch (e) {
      if (e is NoInternetException) {
        final db = await _dbService.database;
        final rows = await db.query('playlists', orderBy: 'updatedAt DESC');
        return rows.map((r) => Playlist(
              id: r['id'] as String,
              name: r['name'] as String,
              description: r['description'] as String?,
              coverUrl: r['coverUrl'] as String?,
            )).toList();
      }
      rethrow;
    }
  }

  Future<Playlist> getPlaylist(String id) async {
    try {
      final p = await _api.getPlaylist(id);
      // Also fetch tracks if not embedded
      List<Song> tracks = p.tracks ?? [];
      if (tracks.isEmpty) {
        try {
          tracks = await _api.getPlaylistTracks(id);
        } catch (_) {}
      }
      return p.copyWith(tracks: tracks);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Song>> getPlaylistTracks(String id) async {
    try {
      return await _api.getPlaylistTracks(id);
    } catch (_) {
      final db = await _dbService.database;
      final rows = await db.query('playlist_items', where: 'playlistId = ?', whereArgs: [id], orderBy: 'sortOrder ASC');
      // Join with tracks
      final songs = <Song>[];
      for (final r in rows) {
        final tid = r['trackId'] as String;
        final tr = await db.query('tracks', where: 'id = ?', whereArgs: [tid], limit: 1);
        if (tr.isNotEmpty) {
          final t = tr.first;
          songs.add(Song(id: t['id'] as String, title: t['title'] as String, artist: t['artist'] as String?, album: t['album'] as String?, duration: t['duration'] as int?, coverUrl: t['coverUrl'] as String?));
        }
      }
      return songs;
    }
  }

  Future<Playlist> createPlaylist(String name, {String? description}) async {
    // Optimistic local insert
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final db = await _dbService.database;
      await db.insert('playlists', {'id': tempId, 'name': name, 'description': description, 'updatedAt': DateTime.now().millisecondsSinceEpoch});
    } catch (_) {}

    try {
      final created = await _api.createPlaylist(name: name, description: description);
      // Replace temp with real
      try {
        final db = await _dbService.database;
        await db.delete('playlists', where: 'id = ?', whereArgs: [tempId]);
        await db.insert('playlists', {'id': created.id, 'name': created.name, 'description': created.description, 'coverUrl': created.coverUrl, 'updatedAt': DateTime.now().millisecondsSinceEpoch});
      } catch (_) {}
      return created;
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation('CREATE_PLAYLIST', {'name': name, 'description': description, 'tempId': tempId});
        return Playlist(id: tempId, name: name, description: description);
      }
      // Rollback on failure
      try {
        final db = await _dbService.database;
        await db.delete('playlists', where: 'id = ?', whereArgs: [tempId]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> deletePlaylist(String id) async {
    // Optimistic
    final db = await _dbService.database;
    final backup = await db.query('playlists', where: 'id = ?', whereArgs: [id]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
    try {
      await _api.deletePlaylist(id);
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation('DELETE_PLAYLIST', {'playlistId': id});
        return;
      }
      // Rollback
      if (backup.isNotEmpty) {
        await db.insert('playlists', backup.first, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      rethrow;
    }
  }

  Future<void> addTrack(String playlistId, String songId) async {
    // Optimistic local
    try {
      final db = await _dbService.database;
      final maxOrder = await db.rawQuery('SELECT MAX(sortOrder) as m FROM playlist_items WHERE playlistId = ?', [playlistId]);
      final next = ((maxOrder.first['m'] as int?) ?? 0) + 1;
      await db.insert('playlist_items', {'id': '${playlistId}_$songId', 'playlistId': playlistId, 'trackId': songId, 'sortOrder': next}, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}

    try {
      await _api.addTrack(playlistId, songId);
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation('ADD_TO_PLAYLIST', {'playlistId': playlistId, 'songId': songId});
        return;
      }
      // Rollback
      try {
        final db = await _dbService.database;
        await db.delete('playlist_items', where: 'playlistId = ? AND trackId = ?', whereArgs: [playlistId, songId]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> removeTrack(String playlistId, String songId) async {
    final db = await _dbService.database;
    await db.delete('playlist_items', where: 'playlistId = ? AND trackId = ?', whereArgs: [playlistId, songId]);
    try {
      await _api.removeTrack(playlistId, songId);
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation('REMOVE_FROM_PLAYLIST', {'playlistId': playlistId, 'songId': songId});
        return;
      }
      rethrow;
    }
  }

  Future<void> reorder(String playlistId, List<String> orderedIds) async {
    try {
      await _api.reorder(playlistId, orderedIds);
      // Update local order
      final db = await _dbService.database;
      final batch = db.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update('playlist_items', {'sortOrder': i}, where: 'playlistId = ? AND trackId = ?', whereArgs: [playlistId, orderedIds[i]]);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      if (e is NoInternetException) {
        await _sync.enqueueOperation('REORDER_PLAYLIST', {'playlistId': playlistId, 'orderedIds': orderedIds});
        return;
      }
      rethrow;
    }
  }
}
