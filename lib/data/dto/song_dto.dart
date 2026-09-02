import '../../domain/entities/song.dart';

class SongDto {
  final String id;
  final String title;
  final String? artist;
  final String? artistId;
  final String? album;
  final String? albumId;
  final int? duration;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final String? coverUrl;
  final String? streamUrl;
  final String? artworkUrl;
  final int? bitrate;
  final int? sampleRate;
  final String? codec;
  final bool? lossless;
  final int? fileSize;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isFavorite;
  final String? rootId;

  SongDto({
    required this.id,
    required this.title,
    this.artist,
    this.artistId,
    this.album,
    this.albumId,
    this.duration,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.coverUrl,
    this.streamUrl,
    this.artworkUrl,
    this.bitrate,
    this.sampleRate,
    this.codec,
    this.lossless,
    this.fileSize,
    this.createdAt,
    this.updatedAt,
    this.isFavorite,
    this.rootId,
  });

  factory SongDto.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    // Handle multiple backend field naming conventions
    String id = (j['id'] ?? j['_id'] ?? j['songId'] ?? '').toString();
    if (id.isEmpty) id = DateTime.now().millisecondsSinceEpoch.toString();

    return SongDto(
      id: id,
      title: (j['title'] ?? j['name'] ?? 'Unknown Title').toString(),
      artist: (j['artist'] ?? j['artistName'])?.toString(),
      artistId: (j['artistId'] ?? j['artist_id'])?.toString(),
      album: (j['album'] ?? j['albumName'])?.toString(),
      albumId: (j['albumId'] ?? j['album_id'])?.toString(),
      duration: parseInt(j['duration'] ?? j['length'] ?? j['durationSeconds']),
      trackNumber: parseInt(
        j['trackNumber'] ?? j['track'] ?? j['track_number'],
      ),
      discNumber: parseInt(j['discNumber'] ?? j['disc']),
      year: parseInt(j['year']),
      genre: j['genre']?.toString(),
      coverUrl:
          (j['coverUrl'] ??
                  j['cover_url'] ??
                  j['artwork'] ??
                  j['image'] ??
                  j['artworkUrl'])
              ?.toString(),
      streamUrl: (j['streamUrl'] ?? j['stream_url'] ?? j['url'] ?? j['src'])
          ?.toString(),
      artworkUrl: (j['artworkUrl'] ?? j['artwork_url'])?.toString(),
      bitrate: parseInt(j['bitrate'] ?? j['bitRate']),
      sampleRate: parseInt(j['sampleRate'] ?? j['sample_rate']),
      codec: (j['codec'] ?? j['format'] ?? j['extension'])?.toString(),
      lossless: j['lossless'] as bool? ?? (j['isLossless'] as bool?),
      fileSize: parseInt(j['fileSize'] ?? j['size'] ?? j['file_size']),
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: parseDate(j['updatedAt'] ?? j['updated_at']),
      isFavorite:
          j['isFavorite'] as bool? ??
          j['favorite'] as bool? ??
          j['liked'] as bool?,
      rootId: (j['rootId'] ?? j['root_id'])?.toString(),
    );
  }

  Song toEntity({bool isDownloaded = false, String? localPath}) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      artistId: artistId,
      album: album,
      albumId: albumId,
      duration: duration,
      trackNumber: trackNumber,
      discNumber: discNumber,
      year: year,
      genre: genre,
      coverUrl: coverUrl,
      streamUrl: streamUrl,
      artworkUrl: artworkUrl,
      bitrate: bitrate,
      sampleRate: sampleRate,
      codec: codec,
      lossless: lossless,
      fileSize: fileSize,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isFavorite: isFavorite ?? false,
      isDownloaded: isDownloaded,
      localPath: localPath,
      rootId: rootId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (artist != null) 'artist': artist,
    if (artistId != null) 'artistId': artistId,
    if (album != null) 'album': album,
    if (albumId != null) 'albumId': albumId,
    if (duration != null) 'duration': duration,
    if (trackNumber != null) 'trackNumber': trackNumber,
    if (discNumber != null) 'discNumber': discNumber,
    if (year != null) 'year': year,
    if (genre != null) 'genre': genre,
    if (coverUrl != null) 'coverUrl': coverUrl,
    if (streamUrl != null) 'streamUrl': streamUrl,
    if (bitrate != null) 'bitrate': bitrate,
    if (sampleRate != null) 'sampleRate': sampleRate,
    if (codec != null) 'codec': codec,
    if (lossless != null) 'lossless': lossless,
  };
}
