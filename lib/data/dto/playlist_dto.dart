import '../../domain/entities/playlist.dart';
import 'song_dto.dart';

class PlaylistDto {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? ownerId;
  final int? trackCount;
  final int? duration;
  final bool? isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<SongDto>? tracks;

  PlaylistDto({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.ownerId,
    this.trackCount,
    this.duration,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
    this.tracks,
  });

  factory PlaylistDto.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    int? pi(dynamic v) =>
        v == null ? null : (v is int ? v : int.tryParse(v.toString()));
    List<SongDto>? parseTracks(dynamic v) {
      if (v == null) return null;
      if (v is List) {
        return v
            .whereType<Map<String, dynamic>>()
            .map((e) => SongDto.fromJson(e))
            .toList();
      }
      return null;
    }

    return PlaylistDto(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: (j['name'] ?? j['title'] ?? 'Untitled').toString(),
      description: (j['description'] ?? j['desc'])?.toString(),
      coverUrl: (j['coverUrl'] ?? j['cover_url'] ?? j['image'] ?? j['artwork'])
          ?.toString(),
      ownerId: (j['ownerId'] ?? j['userId'])?.toString(),
      trackCount: pi(j['trackCount'] ?? j['count'] ?? j['songCount']),
      duration: pi(j['duration']),
      isPublic: j['isPublic'] as bool? ?? j['public'] as bool?,
      createdAt: parseDate(j['createdAt'] ?? j['created_at']),
      updatedAt: parseDate(j['updatedAt'] ?? j['updated_at']),
      tracks: parseTracks(j['tracks'] ?? j['songs'] ?? j['items']),
    );
  }

  Playlist toEntity() => Playlist(
    id: id,
    name: name,
    description: description,
    coverUrl: coverUrl,
    ownerId: ownerId,
    trackCount: trackCount ?? tracks?.length,
    duration: duration,
    isPublic: isPublic,
    createdAt: createdAt,
    updatedAt: updatedAt,
    tracks: tracks?.map((e) => e.toEntity()).toList(),
  );
}
