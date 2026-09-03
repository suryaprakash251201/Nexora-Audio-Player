import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_service.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../api/playlists_api.dart';

final playlistsRepositoryProvider = Provider<PlaylistsRepository>((ref) {
  final api = ref.watch(playlistsApiProvider);
  final db = ref.watch(databaseProvider);
  return PlaylistsRepository(api, db);
});

class PlaylistsRepository {
  final PlaylistsApi _api;
  final DatabaseService _dbService;
  PlaylistsRepository(this._api, this._dbService);

  Future<List<Playlist>> getPlaylists() async {
    try {
      final remote = await _api.getPlaylists();
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
        return rows
            .map(
              (r) => Playlist(
                id: r['id'] as String,
                name: r['name'] as String,
                description: r['description'] as String?,
                coverUrl: r['coverUrl'] as String?,
              ),
            )
            .toList();
      }
      rethrow;
    }
  }

  Future<Playlist> getPlaylist(String id) => _api.getPlaylist(id);

  Future<List<Song>> getPlaylistTracks(String id) => _api.getPlaylistTracks(id);

  Future<Playlist> createPlaylist(String name, {String? description}) =>
      _api.createPlaylist(name: name, description: description);

  Future<void> renamePlaylist(String id, String name) =>
      _api.renamePlaylist(id, name);

  Future<void> deletePlaylist(String id) => _api.deletePlaylist(id);

  Future<void> addTrack(String playlistId, String songId) =>
      _api.addTrack(playlistId, songId);

  /// [itemId] is the server's playlist-item id (Song.itemRef).
  Future<void> removeTrack(String playlistId, String itemId) =>
      _api.removeTrack(playlistId, itemId);

  /// [orderedItemIds] are server playlist-item ids (Song.itemRef order).
  Future<void> reorder(String playlistId, List<String> orderedItemIds) =>
      _api.reorder(playlistId, orderedItemIds);
}
