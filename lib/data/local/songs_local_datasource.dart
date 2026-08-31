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
      batch.insert('tracks', {
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
        'isDownloaded': s.isDownloaded ? 1 : 0,
        'localPath': s.localPath,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
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
