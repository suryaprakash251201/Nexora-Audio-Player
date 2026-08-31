import '../../domain/entities/album.dart';

class AlbumDto {
  final String id;
  final String title;
  final String? artist;
  final String? artistId;
  final int? year;
  final String? genre;
  final String? coverUrl;
  final int? trackCount;
  final int? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AlbumDto({
    required this.id,
    required this.title,
    this.artist,
    this.artistId,
    this.year,
    this.genre,
    this.coverUrl,
    this.trackCount,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory AlbumDto.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      try { return DateTime.parse(v.toString()); } catch (_) { return null; }
    }
    int? pi(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return AlbumDto(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      title: (j['title'] ?? j['name'] ?? 'Unknown Album').toString(),
      artist: (j['artist'] ?? j['artistName'])?.toString(),
      artistId: (j['artistId'] ?? j['artist_id'])?.toString(),
      year: pi(j['year']),
      genre: j['genre']?.toString(),
      coverUrl: (j['coverUrl'] ?? j['artwork'] ?? j['image'] ?? j['cover_url'])?.toString(),
      trackCount: pi(j['trackCount'] ?? j['songCount'] ?? j['count']),
      duration: pi(j['duration']),
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: parseDate(j['updatedAt'] ?? j['updated_at']),
    );
  }

  Album toEntity() => Album(
        id: id,
        title: title,
        artist: artist,
        artistId: artistId,
        year: year,
        genre: genre,
        coverUrl: coverUrl,
        trackCount: trackCount,
        duration: duration,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
