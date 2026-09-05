import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';
import 'audio_api.dart';

final songsApiProvider = Provider<SongsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return SongsApi(c, s);
});

/// Real Nexora file-server backed songs API.
/// Songs are audio files; the search index (kind=audio) is the library.
class SongsApi {
  final ApiClient _client;
  final SecureStorageService _storage;
  SongsApi(this._client, this._storage);

  static const audioExt =
      'mp3,flac,wav,m4a,aac,ogg,opus,wma,alac,aiff,ape,dsf,wv,mka';

  /// Resolves the correct API base URL from secure storage (not Dio global).
  Future<String> _resolvedBaseUrl() async {
    final serverUrl = await _storage.getServerUrl();
    if (serverUrl != null && serverUrl.isNotEmpty) return serverUrl;
    return _client.dio.options.baseUrl;
  }

  /// Stream URL for a song: /files/raw?root=&path=&token=
  /// Token as query param bypasses CSRF; the audio player also sends the
  /// Authorization header (see queue_manager). Both are accepted by Nexora.
  /// Pass a batch [token] to avoid one secure-storage roundtrip per song.
  Future<String> streamUrl(String songId, {String? token}) async {
    final root = Uri.encodeComponent(NexoraFiles.parseRootId(songId));
    final path = Uri.encodeComponent(NexoraFiles.parsePath(songId));
    final t = Uri.encodeComponent(token ?? await _storage.getToken() ?? '');
    final base = await _resolvedBaseUrl();
    return '$base${ApiConstants.filesRaw}?root=$root&path=$path&token=$t';
  }

  /// Artwork (embedded cover fallback chain on the server).
  Future<String> artworkUrl(
    String songId, {
    int size = 512,
    String? token,
  }) async {
    final root = Uri.encodeComponent(NexoraFiles.parseRootId(songId));
    final path = Uri.encodeComponent(NexoraFiles.parsePath(songId));
    final t = Uri.encodeComponent(token ?? await _storage.getToken() ?? '');
    final base = await _resolvedBaseUrl();
    return '$base${ApiConstants.filesThumbnail}?root=$root&path=$path&size=$size&token=$t';
  }

  /// Download URL for offline.
  Future<String> downloadUrl(String songId) async {
    final root = Uri.encodeComponent(NexoraFiles.parseRootId(songId));
    final path = Uri.encodeComponent(NexoraFiles.parsePath(songId));
    final token = Uri.encodeComponent(await _storage.getToken() ?? '');
    final base = await _resolvedBaseUrl();
    return '$base${ApiConstants.filesDownload}?root=$root&path=$path&token=$token';
  }

  /// Search-index based library listing (kind=audio). Empty query lists all.
  Future<PaginatedSongs> getSongs({
    int offset = 0,
    int limit = 50,
    String query = '',
    String? rootId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get(
      ApiConstants.search,
      query: {
        'q': query,
        'kind': 'audio',
        'offset': offset,
        'limit': limit,
        if (rootId != null) 'root': rootId,
      },
      cancelToken: cancelToken,
    );
    final data = res.data;
    List<dynamic> items = [];
    bool hasMore = false;
    if (data is Map<String, dynamic>) {
      items = (data['items'] as List?) ?? [];
      hasMore = data['has_more'] == true;
    } else if (data is List) {
      items = data;
    }
    // One token/base read per page — not per song (secure storage is a
    // platform-channel roundtrip each time).
    final token = await _storage.getToken() ?? '';
    final songs = <Song>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final f = FileItemDto.fromJson(raw);
      if (!NexoraFiles.isAudio(f)) continue;
      final id = NexoraFiles.songId(f);
      songs.add(
        NexoraFiles.toSong(
          f,
          streamUrl: await streamUrl(id, token: token),
          artworkUrl: await artworkUrl(id, size: 512, token: token),
        ),
      );
    }
    return PaginatedSongs(
      songs: await enrichWithTags(songs),
      offset: offset,
      limit: limit,
      hasMore: hasMore,
    );
  }

  /// List a directory (used for album/artist browsing).
  /// Returns (songs with artwork+stream URLs attached, sub-directories).
  Future<(List<Song>, List<({String id, String name})>)> browseDirectory({
    required String rootId,
    String path = '',
    int limit = 500,
  }) async {
    final res = await _client.get(
      ApiConstants.files,
      query: {
        'root': rootId,
        'path': path,
        'limit': limit,
        'offset': 0,
        'dirs_first': 'true',
      },
    );
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? (data['items'] as List?) : null) ?? [];
    final token = await _storage.getToken() ?? '';
    final songs = <Song>[];
    final dirs = <({String id, String name})>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final f = FileItemDto.fromJson(raw);
      if (f.isDir) {
        final dirPath = f.path.isEmpty ? f.name : f.path;
        dirs.add((id: '$rootId|$dirPath', name: f.name));
      } else if (NexoraFiles.isAudio(f)) {
        final id = NexoraFiles.songId(f);
        songs.add(
          NexoraFiles.toSong(
            f,
            streamUrl: await streamUrl(id, token: token),
            artworkUrl: await artworkUrl(id, size: 512, token: token),
          ),
        );
      }
    }
    return (await enrichWithTags(songs), dirs);
  }

  /// Resolve the best "music" root id (icon/name heuristic, else first root).
  Future<String?> musicRootId() async {
    try {
      final res = await _client.get(ApiConstants.roots);
      final data = res.data;
      final roots =
          (data is Map<String, dynamic> ? data['roots'] as List? : null) ?? [];
      String? music;
      String? first;
      for (final raw in roots) {
        if (raw is! Map<String, dynamic>) continue;
        if (raw['enabled'] == false) continue;
        final id = (raw['id'] ?? '').toString();
        final name = (raw['name'] ?? '').toString().toLowerCase();
        final icon = (raw['icon'] ?? '').toString().toLowerCase();
        first ??= id;
        if (icon == 'music' ||
            name.contains('music') ||
            name.contains('songs')) {
          music = id;
          break;
        }
      }
      return music ?? first;
    } catch (_) {
      return null;
    }
  }

  /// ffprobe-backed audio metadata (codec, bitrate, sample rate, duration).
  Future<Map<String, dynamic>?> getAudioInfo(String songId) async {
    try {
      final root = NexoraFiles.parseRootId(songId);
      final path = NexoraFiles.parsePath(songId);
      final res = await _client.get(
        ApiConstants.audioInfo,
        query: {'root': root, 'path': path},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}
    return null;
  }

  /// Batch-enrich one page of songs with server tag metadata.
  ///
  /// Exactly one POST /audio/info/batch per 50 songs (never N+1 single
  /// GETs). Failures (offline / old server without the endpoint) return
  /// the input untouched so filename/path fallbacks keep working.
  Future<List<Song>> enrichWithTags(List<Song> songs) async {
    if (songs.isEmpty) return songs;
    try {
      final base = await _resolvedBaseUrl();
      final byId = <String, AudioInfo>{};
      for (var i = 0; i < songs.length; i += 50) {
        final chunk = songs.sublist(
          i,
          (i + 50) > songs.length ? songs.length : i + 50,
        );
        final res = await _client.post(
          '$base${ApiConstants.audioInfoBatch}',
          data: {
            'items': [
              for (final s in chunk)
                (() {
                  final split = NexoraFiles.splitId(s.id);
                  return {'root': split.root, 'path': split.path};
                })(),
            ],
          },
        );
        final data = res.data;
        final list =
            (data is Map<String, dynamic> ? data['items'] as List? : null) ??
            (data is List ? data : const []);
        for (final raw in list) {
          if (raw is! Map<String, dynamic>) continue;
          if (raw['ok'] != true) continue;
          final rawInfo = raw['info'];
          if (rawInfo is! Map<String, dynamic>) continue;
          try {
            final info = AudioInfo.fromJson(rawInfo);
            final root = (raw['root'] ?? '').toString();
            final path = (raw['path'] ?? '').toString();
            byId['$root|$path'] = info;
          } catch (_) {}
        }
      }
      if (byId.isEmpty) return songs;
      return [for (final s in songs) _mergeTagInfo(s, byId[s.id])];
    } catch (_) {
      return songs;
    }
  }

  /// Merge one [AudioInfo] into its [Song]; filename/path values win only
  /// when the tag is missing or blank.
  Song _mergeTagInfo(Song song, AudioInfo? info) {
    if (info == null) return song;
    final artist = info.effectiveArtist;
    final genre = info.effectiveGenre;
    final year = info.effectiveYear;
    return song.copyWith(
      title: (info.title != null && info.title!.trim().isNotEmpty)
          ? info.title!.trim()
          : song.title,
      artist: (artist != null && artist.isNotEmpty) ? artist : song.artist,
      album: (info.album != null && info.album!.trim().isNotEmpty)
          ? info.album!.trim()
          : song.album,
      genre: (genre != null && genre.isNotEmpty) ? genre : song.genre,
      year: (year != null && year > 0) ? year : song.year,
      trackNumber: (info.trackNo != null && info.trackNo! > 0)
          ? info.trackNo
          : song.trackNumber,
      discNumber: (info.discNo != null && info.discNo! > 0)
          ? info.discNo
          : song.discNumber,
      duration:
          (song.duration == null || song.duration == 0) && info.duration > 0
          ? info.duration.round()
          : song.duration,
      codec:
          (song.codec == null || song.codec!.isEmpty) && info.codec.isNotEmpty
          ? info.codec
          : song.codec,
      bitrate: (song.bitrate == null || song.bitrate == 0) && info.bitRate > 0
          ? info.bitRate
          : song.bitrate,
      sampleRate:
          (song.sampleRate == null || song.sampleRate == 0) &&
              info.sampleRate > 0
          ? info.sampleRate
          : song.sampleRate,
      lossless: song.lossless ?? info.lossless,
    );
  }
}

class PaginatedSongs {
  final List<Song> songs;
  final int offset;
  final int limit;
  final bool hasMore;
  PaginatedSongs({
    required this.songs,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });
}
