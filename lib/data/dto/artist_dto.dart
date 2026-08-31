import '../../domain/entities/artist.dart';

class ArtistDto {
  final String id;
  final String name;
  final String? artworkUrl;
  final int? albumCount;
  final int? trackCount;
  final String? bio;

  ArtistDto({
    required this.id,
    required this.name,
    this.artworkUrl,
    this.albumCount,
    this.trackCount,
    this.bio,
  });

  factory ArtistDto.fromJson(Map<String, dynamic> j) {
    int? pi(dynamic v) => v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    return ArtistDto(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: (j['name'] ?? j['title'] ?? 'Unknown Artist').toString(),
      artworkUrl: (j['artworkUrl'] ?? j['artwork'] ?? j['image'] ?? j['coverUrl'])?.toString(),
      albumCount: pi(j['albumCount'] ?? j['albums']),
      trackCount: pi(j['trackCount'] ?? j['songs'] ?? j['count']),
      bio: j['bio']?.toString(),
    );
  }

  Artist toEntity() => Artist(
        id: id,
        name: name,
        artworkUrl: artworkUrl,
        albumCount: albumCount,
        trackCount: trackCount,
        bio: bio,
      );
}
