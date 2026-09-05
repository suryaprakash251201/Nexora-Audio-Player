import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/artist.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';
import 'songs_api.dart';

final artistsApiProvider = Provider<ArtistsApi>((ref) {
  final songsApi = ref.watch(songsApiProvider);
  return ArtistsApi(songsApi);
});

/// Artists: tag-based grouping first, directory heuristic as fallback.
///
/// Tag ids look like `tag/<url-encoded name>`; directory ids keep the
/// legacy `rootId|path` shape so old navigation keeps working.
class ArtistsApi {
  final SongsApi _songs;
  ArtistsApi(this._songs);

  static const _tagPrefix = 'tag|';

  static bool isTagId(String id) => id.startsWith(_tagPrefix);

  static String tagIdFor(String name) =>
      '$_tagPrefix${Uri.encodeComponent(name.trim())}';

  static String tagNameOf(String tagId) {
    final raw = tagId.substring(_tagPrefix.length);
    try {
      return Uri.decodeComponent(raw).trim();
    } catch (_) {
      return raw.trim();
    }
  }

  Future<List<Artist>> getArtists({
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    // 1. Tag-based grouping (bounded scan; getSongs pages are already
    //    batch-enriched with server tags, one batch POST per page).
    try {
      final tagged = await getArtistsFromTags(
        limit: limit,
        cancelToken: cancelToken,
      );
      if (tagged.isNotEmpty) return tagged;
    } catch (_) {
      // Fall through to directory heuristic.
    }
    // 2. Offline / old-server fallback: directories.
    return getArtistsFromDirectories(limit: limit);
  }

  /// Group a bounded library scan by the `artist` tag.
  Future<List<Artist>> getArtistsFromTags({
    int limit = 100,
    CancelToken? cancelToken,
  }) async {
    final budget = limit <= 20 ? 100 : 300;
    const pageSize = 50;
    final counts = <String, int>{};
    final display = <String, String>{};
    final artwork = <String, String?>{};
    var offset = 0;
    var scanned = 0;
    while (scanned < budget) {
      final page = await _songs.getSongs(
        offset: offset,
        limit: pageSize,
        cancelToken: cancelToken,
      );
      if (page.songs.isEmpty) break;
      for (final s in page.songs) {
        final name = (s.artist ?? '').trim();
        if (name.isEmpty || name.toLowerCase() == 'unknown artist') continue;
        final key = name.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
        display.putIfAbsent(key, () => name);
        if (artwork[key] == null && s.effectiveArtwork != null) {
          artwork[key] = s.effectiveArtwork;
        }
      }
      scanned += page.songs.length;
      if (!page.hasMore) break;
      offset += pageSize;
    }
    if (counts.isEmpty) return const [];
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        if (c != 0) return c;
        return display[a]!.toLowerCase().compareTo(display[b]!.toLowerCase());
      });
    return [
      for (final k in keys.take(limit))
        Artist(
          id: tagIdFor(display[k]!),
          name: display[k]!,
          artworkUrl: artwork[k],
          trackCount: counts[k],
        ),
    ];
  }

  /// Legacy directory heuristic (offline fallback, unchanged behavior).
  Future<List<Artist>> getArtistsFromDirectories({int limit = 100}) async {
    final rootId = await _songs.musicRootId();
    if (rootId == null) return [];
    final (_, dirs) = await _songs.browseDirectory(
      rootId: rootId,
      limit: limit,
    );
    final artistsDir = dirs
        .where((d) => d.name.toLowerCase() == 'artists')
        .toList();
    final source = artistsDir.isNotEmpty ? artistsDir : dirs;
    return source.map((d) => Artist(id: d.id, name: d.name)).toList();
  }

  Future<Artist> getArtist(String artistId) async {
    if (isTagId(artistId)) {
      final name = tagNameOf(artistId);
      return Artist(id: artistId, name: name.isEmpty ? artistId : name);
    }
    final path = NexoraFiles.parsePath(artistId);
    final name = path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? path;
    return Artist(id: artistId, name: name);
  }

  Future<List<Song>> getArtistSongs(String artistId, {int limit = 200}) async {
    if (isTagId(artistId)) {
      return getTagArtistSongs(tagNameOf(artistId), limit: limit);
    }
    final root = NexoraFiles.parseRootId(artistId);
    final path = NexoraFiles.parsePath(artistId);
    final (songs, subDirs) = await _songs.browseDirectory(
      rootId: root,
      path: path,
    );
    if (songs.isEmpty && subDirs.isNotEmpty) {
      for (final d in subDirs.take(20)) {
        final p = NexoraFiles.parsePath(d.id);
        final (s2, _) = await _songs.browseDirectory(rootId: root, path: p);
        songs.addAll(s2);
        if (songs.length > limit) break;
      }
    }
    return songs;
  }

  /// Tracks whose enriched `artist` tag matches [name] (case-insensitive).
  Future<List<Song>> getTagArtistSongs(String name, {int limit = 200}) async {
    final want = name.trim().toLowerCase();
    if (want.isEmpty) return const [];
    const pageSize = 50;
    final out = <Song>[];
    var offset = 0;
    while (out.length < limit) {
      final page = await _songs.getSongs(
        offset: offset,
        limit: pageSize,
        query: name.trim(),
      );
      if (page.songs.isEmpty) break;
      for (final s in page.songs) {
        if ((s.artist ?? '').trim().toLowerCase() == want) {
          out.add(s);
          if (out.length >= limit) break;
        }
      }
      if (!page.hasMore) break;
      offset += pageSize;
      // Server search may return the same window for fuzzy queries;
      // stop rather than loop forever.
      if (offset > 1000) break;
    }
    return out;
  }
}
