import '../../domain/entities/song.dart';

/// A file item from the real Nexora server (`/files`, `/search`).
/// shape: {name, path, size, is_dir, modified, mime, root_id, extension}
class FileItemDto {
  final String name;
  final String path;
  final int size;
  final bool isDir;
  final String modified;
  final String mime;
  final String rootId;
  final String extension;

  FileItemDto({
    required this.name,
    required this.path,
    required this.size,
    required this.isDir,
    required this.modified,
    required this.mime,
    required this.rootId,
    required this.extension,
  });

  factory FileItemDto.fromJson(Map<String, dynamic> j) {
    final name = (j['name'] ?? '').toString();
    // Fallback: extract extension from filename if server doesn't provide it
    final rawExt = (j['extension'] ?? '').toString();
    final ext = rawExt.isNotEmpty
        ? rawExt
        : (name.contains('.') ? name.split('.').last : '');
    return FileItemDto(
      name: name,
      path: (j['path'] ?? '').toString(),
      size: (j['size'] is int)
          ? j['size'] as int
          : int.tryParse((j['size'] ?? '0').toString()) ?? 0,
      isDir: j['is_dir'] == true,
      modified: (j['modified'] ?? '').toString(),
      mime: (j['mime'] ?? '').toString(),
      rootId: (j['root_id'] ?? '').toString(),
      extension: ext,
    );
  }
}

class NexoraFiles {
  static const audioExtensions = {
    'mp3',
    'flac',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'opus',
    'wma',
    'alac',
    'aiff',
    'aif',
    'ape',
    'dsf',
    'wv',
    'oga',
    'mka',
  };

  static bool isAudio(FileItemDto f) =>
      !f.isDir &&
      (NexoraFiles.audioExtensions.contains(f.extension.toLowerCase()) ||
          f.mime.startsWith('audio/'));

  static bool isDir(FileItemDto f) => f.isDir;

  /// Stable server identifier: "rootId|path"
  static String songId(FileItemDto f) => '${f.rootId}|${f.path}';

  static String parseRootId(String id) =>
      id.contains('|') ? id.split('|').first : id;
  static String parsePath(String id) =>
      id.contains('|') ? id.split('|').skip(1).join('|') : id;

  /// Absolute thumbnail URL for a file path. The `?token=` query fully
  /// authenticates the request (verified against the live server), so plain
  /// `Image.network` and `MediaItem.artUri` both work without headers.
  static String thumbnailUrl(
    String baseUrl,
    String rootId,
    String path,
    String token, {
    int size = 512,
  }) {
    // Strip /api/v1 suffix to get the origin, then append the full API path
    final origin = baseUrl.split('/api').first;
    final base = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return '$base/api/v1/files/thumbnail'
        '?root=${Uri.encodeComponent(rootId)}&path=${Uri.encodeComponent(path)}'
        '&size=$size&token=${Uri.encodeComponent(token)}';
  }

  /// Absolute stream URL for an audio file path.
  static String rawUrl(
    String baseUrl,
    String rootId,
    String path,
    String token,
  ) {
    // Strip /api/v1 suffix to get the origin, then append the full API path
    final origin = baseUrl.split('/api').first;
    final base = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return '$base/api/v1/files/raw'
        '?root=${Uri.encodeComponent(rootId)}&path=${Uri.encodeComponent(path)}'
        '&token=${Uri.encodeComponent(token)}';
  }

  /// "03 - usurey poguthu (from Ravaanan).flac" -> "usurey poguthu (from Ravaanan)"
  static String parseTitle(String fileName) {
    var t = fileName;
    final dot = t.lastIndexOf('.');
    if (dot > 0) t = t.substring(0, dot);
    t = t.replaceFirst(RegExp(r'^\s*\d+[\.\)\-]?\s*'), '');
    return t.trim().isEmpty ? fileName : t.trim();
  }

  /// Derive artist/album from path segments:
  /// "Album Songs/<Artist>/<Album>/track.flac" -> artist=<Artist>, album=<Album>
  static (String?, String?) parseArtistAlbum(String path) {
    final segs = path.split('/')..removeWhere((s) => s.isEmpty);
    if (segs.isEmpty) return (null, null);
    String? album = segs.length >= 2 ? segs[segs.length - 2] : null;
    String? artist = segs.length >= 3 ? segs[segs.length - 3] : null;
    // Skip generic container folder names
    const generic = {
      'music',
      'songs',
      'loseless',
      'lossless',
      'album songs',
      'media',
      'audio',
      'albums',
      'artists',
    };
    if (album != null && generic.contains(album.toLowerCase())) album = null;
    if (artist != null && generic.contains(artist.toLowerCase())) {
      artist = album; // fall back to album name as artist
    }
    return (artist, album);
  }

  /// Convert a file item into the domain Song.
  static Song toSong(
    FileItemDto f, {
    String? streamUrl,
    String? artworkUrl,
    bool isFavorite = false,
    bool isDownloaded = false,
    String? localPath,
    String? itemRef,
  }) {
    final (artist, album) = parseArtistAlbum(f.path);
    DateTime? modified;
    try {
      modified = DateTime.parse(f.modified);
    } catch (_) {}
    return Song(
      id: songId(f),
      title: parseTitle(f.name),
      artist: artist,
      album: album,
      duration: null,
      year: null,
      genre: null,
      coverUrl: artworkUrl,
      streamUrl: streamUrl,
      bitrate: null,
      sampleRate: null,
      codec: f.extension.toUpperCase(),
      lossless: const {
        'flac',
        'wav',
        'alac',
        'aiff',
        'aif',
        'ape',
        'dsf',
        'wv',
      }.contains(f.extension.toLowerCase()),
      fileSize: f.size,
      createdAt: modified,
      isFavorite: isFavorite,
      isDownloaded: isDownloaded,
      localPath: localPath,
      itemRef: itemRef,
    );
  }
}
