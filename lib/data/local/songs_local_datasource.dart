import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_service.dart';
import '../../domain/entities/song.dart';

final songsLocalDsProvider = Provider<SongsLocalDataSource>((ref) {
  final db = ref.watch(databaseProvider);
  return SongsLocalDataSource(db);
});

class SongsLocalDataSource {
  final DatabaseService _dbService;
  SongsLocalDataSource(this._dbService);

  Future<void> cacheSongs(List<Song> songs) async {
    final db = await _dbService.database;
    final batch = db.batch();
    for (final s in songs) {
      final metadata = {
        'id': s.id,
        'title': s.title,
        'artist': s.artist,
        'album': s.album,
        'duration': s.duration,
        'coverUrl': s.coverUrl ?? s.artworkUrl,
        'streamUrl': s.streamUrl,
        'codec': s.codec,
        'bitrate': s.bitrate,
        'sampleRate': s.sampleRate,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      // Use INSERT OR IGNORE + UPDATE instead of REPLACE to avoid
      // triggering ON DELETE CASCADE which would silently remove
      // playlist_items referencing this track.
      batch.insert('tracks', {
        ...metadata,
        'isDownloaded': s.isDownloaded ? 1 : 0,
        'localPath': s.localPath,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      // Metadata refresh must never wipe an existing download: only carry
      // the flags when the incoming song actually carries download state.
      final update = Map.of(metadata)..remove('id');
      if (s.isDownloaded || s.localPath != null) {
        update['isDownloaded'] = s.isDownloaded ? 1 : 0;
        update['localPath'] = s.localPath;
      }
      batch.update('tracks', update, where: 'id = ?', whereArgs: [s.id]);
    }
    await batch.commit(noResult: true);
  }

  /// Download state for [ids]: true only when the flag is set AND the file
  /// still exists on disk. Used to attach offline playback info to fresh
  /// network songs so the player streams local files when available.
  Future<Map<String, ({bool isDownloaded, String? localPath})>>
  getDownloadStates(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final db = await _dbService.database;
    final out = <String, ({bool isDownloaded, String? localPath})>{};
    // Chunk the IN clause (SQLite variable limit).
    for (var i = 0; i < ids.length; i += 200) {
      final chunk = ids.sublist(
        i,
        (i + 200) > ids.length ? ids.length : i + 200,
      );
      final placeholders = List.filled(chunk.length, '?').join(',');
      final rows = await db.query(
        'tracks',
        columns: ['id', 'isDownloaded', 'localPath'],
        where: 'id IN ($placeholders)',
        whereArgs: chunk,
      );
      for (final r in rows) {
        final path = r['localPath'] as String?;
        final ok =
            (r['isDownloaded'] as int? ?? 0) == 1 &&
            path != null &&
            File(path).existsSync();
        if (ok) {
          out[r['id'] as String] = (isDownloaded: true, localPath: path);
        }
      }
    }
    return out;
  }

  /// Attach verified offline state to network songs (player + row badges).
  List<Song> withOfflineState(
    List<Song> songs,
    Map<String, ({bool isDownloaded, String? localPath})> states,
  ) {
    if (states.isEmpty) return songs;
    return [
      for (final s in songs)
        states.containsKey(s.id)
            ? s.copyWith(isDownloaded: true, localPath: states[s.id]!.localPath)
            : s,
    ];
  }

  Future<List<Song>> getCachedSongs({int limit = 100, int offset = 0}) async {
    final db = await _dbService.database;
    final rows = await db.query(
      'tracks',
      limit: limit,
      offset: offset,
      orderBy: 'updatedAt DESC',
    );
    return rows
        .map(
          (r) => Song(
            id: r['id'] as String,
            title: r['title'] as String,
            artist: r['artist'] as String?,
            album: r['album'] as String?,
            duration: r['duration'] as int?,
            coverUrl: r['coverUrl'] as String?,
            streamUrl: r['streamUrl'] as String?,
            codec: r['codec'] as String?,
            bitrate: r['bitrate'] as int?,
            sampleRate: r['sampleRate'] as int?,
            isDownloaded: (r['isDownloaded'] as int? ?? 0) == 1,
            localPath: r['localPath'] as String?,
          ),
        )
        .toList();
  }

  Future<Song?> getSong(String id) async {
    final db = await _dbService.database;
    final rows = await db.query(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Song(
      id: r['id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String?,
      album: r['album'] as String?,
      duration: r['duration'] as int?,
      coverUrl: r['coverUrl'] as String?,
      streamUrl: r['streamUrl'] as String?,
      codec: r['codec'] as String?,
      bitrate: r['bitrate'] as int?,
      sampleRate: r['sampleRate'] as int?,
      isDownloaded: (r['isDownloaded'] as int? ?? 0) == 1,
      localPath: r['localPath'] as String?,
    );
  }

  Future<List<Song>> searchLocal(String query) async {
    final db = await _dbService.database;
    final rows = await db.query(
      'tracks',
      where: 'title LIKE ? OR artist LIKE ? OR album LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      limit: 50,
    );
    return rows
        .map(
          (r) => Song(
            id: r['id'] as String,
            title: r['title'] as String,
            artist: r['artist'] as String?,
            album: r['album'] as String?,
            duration: r['duration'] as int?,
            coverUrl: r['coverUrl'] as String?,
            streamUrl: r['streamUrl'] as String?,
            isDownloaded: (r['isDownloaded'] as int? ?? 0) == 1,
            localPath: r['localPath'] as String?,
          ),
        )
        .toList();
  }
}
