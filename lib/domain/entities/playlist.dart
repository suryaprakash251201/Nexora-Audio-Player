import 'song.dart';

class Playlist {
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
  final List<Song>? tracks; // when expanded

  const Playlist({
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

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? coverUrl,
    String? ownerId,
    int? trackCount,
    int? duration,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Song>? tracks,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      ownerId: ownerId ?? this.ownerId,
      trackCount: trackCount ?? this.trackCount,
      duration: duration ?? this.duration,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tracks: tracks ?? this.tracks,
    );
  }
}
