import 'package:flutter_test/flutter_test.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:nexora_flutter/core/audio/queue_manager.dart';
import 'package:nexora_flutter/core/database/database_service.dart';
import 'package:nexora_flutter/data/local/device_music.dart';
import 'package:nexora_flutter/domain/entities/song.dart';

/// On-device library: mapping + playback-URL contract.
///
/// - Android file paths play via Song.localPath (Uri.file).
/// - iOS ipod-library:// asset URLs play via Song.streamUrl (sandboxed
///   file access makes raw paths unusable on iOS).
/// - Neither may be rebuilt into server /files/raw URLs by the queue
///   mapping, and no auth headers may leak onto device URIs.
SongModel _model(Map<String, dynamic> m) => SongModel(m);

Map<String, dynamic> _android({
  int id = 7,
  String data = '/storage/emulated/0/Music/aurora.mp3',
  String title = 'Aurora',
  String? artist = 'Nexora',
  String? album = 'Dreams',
  int duration = 212000,
  bool? isMusic = true,
}) => {
  '_id': id,
  '_data': data,
  'title': title,
  'artist': artist,
  'album': album,
  'duration': duration,
  'track': 3,
  'genre': 'Ambient',
  '_display_name_wo_ext': 'aurora',
  '_size': 8123456,
  'is_music': isMusic,
};

void main() {
  test('android maps to file-backed song', () {
    final s = deviceSongFromModel(_model(_android()), android: true);
    expect(s.id, 'device_7');
    expect(s.title, 'Aurora');
    expect(s.artist, 'Nexora');
    expect(s.album, 'Dreams');
    expect(s.duration, 212);
    expect(s.trackNumber, 3);
    expect(s.localPath, '/storage/emulated/0/Music/aurora.mp3');
    expect(s.streamUrl, 'file:///storage/emulated/0/Music/aurora.mp3');
    expect(s.rootId, '');
  });

  test('android normalizes <unknown> metadata to null', () {
    final s = deviceSongFromModel(
      _model(_android(artist: '<unknown>', album: '<unknown>')),
      android: true,
    );
    expect(s.artist, isNull);
    expect(s.album, isNull);
  });

  test('ios keeps ipod-library asset URL, no local path', () {
    const asset = 'ipod-library://item/item.mp3?id=42';
    final s = deviceSongFromModel(
      _model(_android(data: asset)),
      android: false,
    );
    expect(s.streamUrl, asset);
    expect(s.localPath, isNull);
    expect(s.rootId, '');
  });

  test('non-music clutter is filtered out', () {
    final list = deviceSongsFromModels([
      _model(_android(id: 1)),
      _model(_android(id: 2, title: 'Ping', isMusic: false)),
      _model(_android(id: 3, title: 'Beep', isMusic: null)),
    ], android: true);
    expect(list.map((s) => s.id), ['device_1', 'device_3']);
  });

  test('queue mapping never rebuilds device URIs into server URLs', () {
    final qm = QueueManager(DatabaseService());
    const base = 'https://music.example.com/api/v1';

    final android = deviceSongFromModel(_model(_android()), android: true);
    final aItem = qm.songToMediaItem(android, baseUrl: base, token: 'tok');
    expect(aItem.id, android.streamUrl);
    expect(aItem.id, isNot(contains('/files/raw')));
    expect(aItem.extras?['localPath'], android.localPath);
    expect((aItem.extras?['headers'] as Map?)?.isEmpty ?? true, isTrue);

    const asset = 'ipod-library://item/item.mp3?id=42';
    final ios = deviceSongFromModel(
      _model(_android(data: asset)),
      android: false,
    );
    final iItem = qm.songToMediaItem(ios, baseUrl: base, token: 'tok');
    expect(iItem.id, asset);
    expect(iItem.id, isNot(contains('/files/raw')));
    expect((iItem.extras?['headers'] as Map?)?.isEmpty ?? true, isTrue);
  });

  test('queue mapping still rebuilds server songs', () {
    final qm = QueueManager(DatabaseService());
    const server = Song(id: 'root_abc|x.mp3', title: 'Server track');
    final item = qm.songToMediaItem(
      server,
      baseUrl: 'https://music.example.com/api/v1',
      token: 'tok',
    );
    expect(item.id, contains('/files/raw'));
    expect(item.id, contains('root=root_abc'));
  });
}
