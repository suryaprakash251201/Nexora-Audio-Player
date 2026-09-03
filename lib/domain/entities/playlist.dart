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

/// A user sharing (or shared into) a playlist.
class PlaylistCollaborator {
  final String playlistId;
  final String userId;
  final String role;
  final String createdAt;
  final String username;

  const PlaylistCollaborator({
    required this.playlistId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.username,
  });

  factory PlaylistCollaborator.fromJson(Map<String, dynamic> j) =>
      PlaylistCollaborator(
        playlistId: (j['playlist_id'] ?? '').toString(),
        userId: (j['user_id'] ?? '').toString(),
        role: (j['role'] ?? 'viewer').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
      );
}

/// Minimal user row for the collaborator picker.
class PlaylistUser {
  final String id;
  final String username;

  const PlaylistUser({required this.id, required this.username});

  factory PlaylistUser.fromJson(Map<String, dynamic> j) => PlaylistUser(
    id: (j['id'] ?? '').toString(),
    username: (j['username'] ?? '').toString(),
  );
}
