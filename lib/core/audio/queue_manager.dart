import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../database/database_service.dart';
import '../logging/app_logger.dart';

final queueManagerProvider = Provider<QueueManager>((ref) {
  final db = ref.watch(databaseProvider);
  return QueueManager(db);
});

class QueueManager {
  final DatabaseService _db;
  QueueManager(this._db);

  static const _queueKey = 'queue';

  Future<void> persistQueue(List<MediaItem> queue, int currentIndex) async {
    try {
      final db = await _db.database;
      final data = jsonEncode({
        'queue': queue
            .map(
              (e) => {
                'id': e.id,
                'title': e.title,
                'artist': e.artist,
                'album': e.album,
                'duration': e.duration?.inMilliseconds,
                'artUri': e.artUri?.toString(),
                'extras': e.extras,
              },
            )
            .toList(),
        'index': currentIndex,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await db.insert('queue_state', {
        'id': _queueKey,
        'data': data,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      AppLogger.queue('Persisted ${queue.length} items @ $currentIndex');
    } catch (e) {
      AppLogger.queue('persistQueue failed: $e');
    }
  }

  Future<(List<MediaItem>, int)> restoreQueue() async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'queue_state',
        where: 'id = ?',
        whereArgs: [_queueKey],
        limit: 1,
      );
      if (rows.isEmpty) return (<MediaItem>[], 0);
      final data =
          jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
      final list = (data['queue'] as List)
          .whereType<Map<String, dynamic>>()
          .map((j) {
            return MediaItem(
              id: j['id'] as String,
              title: j['title'] as String? ?? 'Unknown',
              artist: j['artist'] as String?,
              album: j['album'] as String?,
              duration: j['duration'] is int
                  ? Duration(milliseconds: j['duration'] as int)
                  : null,
              artUri: j['artUri'] != null
                  ? Uri.tryParse(j['artUri'] as String)
                  : null,
              extras: (j['extras'] as Map?)?.map(
                (k, v) => MapEntry(k.toString(), v),
              ),
            );
          })
          .toList();
      final idx = (data['index'] as int?) ?? 0;
      AppLogger.queue('Restored ${list.length} items @ $idx');
      return (list, idx);
    } catch (e) {
      AppLogger.queue('restoreQueue failed: $e');
      return (<MediaItem>[], 0);
    }
  }

  MediaItem songToMediaItem(Song song, {String? baseUrl, String? token}) {
    // Song id is "rootId|path" on the real Nexora file server; streamUrl
    // usually already carries the fully resolved /files/raw?root=&path=&token=
    // URL (built by SongsApi/PlaylistsApi). Fall back to rebuilding the URL
    // from the canonical song.id (rootId|path) for cached/legacy songs whose
    // streamUrl is missing or relative.
    String fullStream = song.streamUrl ?? song.id;
    if (!fullStream.startsWith('http')) {
      // Rebuild from the canonical id rather than the (possibly mangled)
      // relative streamUrl string.
      final rawId = song.id.isNotEmpty ? song.id : fullStream;
      final root = rawId.contains('|') ? rawId.split('|').first : '';
      final path = rawId.contains('|')
          ? rawId.split('|').skip(1).join('|')
          : rawId;
      final t = token ?? '';
      if (baseUrl != null && baseUrl.isNotEmpty) {
        final base = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
        fullStream =
            '$base/files/raw?root=$root&path=${Uri.encodeComponent(path)}&token=$t';
      }
    }
    final artwork = song.coverUrl ?? song.artworkUrl;
    String? fullArt = artwork;
    if (artwork != null && !artwork.startsWith('http') && baseUrl != null) {
      final base = baseUrl.split('/api').first;
      fullArt = artwork.startsWith('/') ? '$base$artwork' : '$base/$artwork';
    }

    final headers = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null;

    // #3 FIX: lyrics + audio-info need rootId + file path. Song.id is
    // canonical "rootId|path" — expose both explicitly so the player can
    // call /audio/lyrics?root=&path= (sibling .lrc) without re-parsing.
    final canonicalRoot = song.rootId != null && song.rootId!.isNotEmpty
        ? song.rootId!
        : (song.id.contains('|') ? song.id.split('|').first : '');
    final canonicalPath = song.id.contains('|')
        ? song.id.split('|').skip(1).join('|')
        : song.id;
    return MediaItem(
      id: fullStream,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration != null
          ? Duration(seconds: song.duration!)
          : null,
      artUri: fullArt != null ? Uri.tryParse(fullArt) : null,
      extras: {
        'songId': song.id,
        'rootId': canonicalRoot,
        'path': canonicalPath,
        'localPath': song.localPath,
        'headers': headers,
        'codec': song.codec,
        'bitrate': song.bitrate,
        'sampleRate': song.sampleRate,
        'lossless': song.lossless,
      },
    );
  }

  Future<void> clearPersistedQueue() async {
    try {
      final db = await _db.database;
      await db.delete('queue_state', where: 'id = ?', whereArgs: [_queueKey]);
    } catch (_) {}
  }
}
