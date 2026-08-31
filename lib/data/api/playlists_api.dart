import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../dto/playlist_dto.dart';
import '../dto/song_dto.dart';

final playlistsApiProvider = Provider<PlaylistsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return PlaylistsApi(c);
});

class PlaylistsApi {
  final ApiClient _client;
  PlaylistsApi(this._client);

  Future<List<Playlist>> getPlaylists() async {
    final res = await _client.get(ApiConstants.playlists);
    final data = res.data;
    List<dynamic> list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List)
        list = data['data'] as List;
      else if (data['playlists'] is List)
        list = data['playlists'] as List;
      else if (data['items'] is List)
        list = data['items'] as List;
      else
        list = [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => PlaylistDto.fromJson(e).toEntity())
        .toList();
  }

  Future<Playlist> getPlaylist(String id) async {
    final res = await _client.get(ApiConstants.playlistById(id));
    final raw = res.data as Map<String, dynamic>?;
    Map<String, dynamic> j = raw?['data'] is Map
        ? raw!['data'] as Map<String, dynamic>
        : (raw ?? {});
    if (j['playlist'] is Map) j = j['playlist'] as Map<String, dynamic>;
    // Some APIs embed tracks under j['tracks']
    return PlaylistDto.fromJson(j).toEntity();
  }

  Future<List<Song>> getPlaylistTracks(String id) async {
    final res = await _client.get(ApiConstants.playlistTracks(id));
    final data = res.data;
    List<dynamic> list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List)
        list = data['data'] as List;
      else if (data['tracks'] is List)
        list = data['tracks'] as List;
      else if (data['songs'] is List)
        list = data['songs'] as List;
      else if (data['data'] is Map && data['data']['tracks'] is List)
        list = data['data']['tracks'] as List;
      else
        list = [];
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => SongDto.fromJson(e).toEntity())
        .toList();
  }

  Future<Playlist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final res = await _client.post(
      ApiConstants.playlists,
      data: {'name': name, if (description != null) 'description': description},
    );
    final raw = res.data as Map<String, dynamic>?;
    Map<String, dynamic> j = raw?['data'] is Map
        ? raw!['data'] as Map<String, dynamic>
        : (raw ?? {});
    if (j['playlist'] is Map) j = j['playlist'] as Map<String, dynamic>;
    return PlaylistDto.fromJson(j).toEntity();
  }

  Future<Playlist> updatePlaylist(
    String id, {
    String? name,
    String? description,
  }) async {
    final res = await _client.put(
      ApiConstants.playlistById(id),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      },
    );
    final raw = res.data as Map<String, dynamic>?;
    Map<String, dynamic> j = raw?['data'] is Map
        ? raw!['data'] as Map<String, dynamic>
        : (raw ?? {});
    if (j['playlist'] is Map) j = j['playlist'] as Map<String, dynamic>;
    return PlaylistDto.fromJson(j).toEntity();
  }

  Future<void> deletePlaylist(String id) async {
    await _client.delete(ApiConstants.playlistById(id));
  }

  Future<void> addTrack(String playlistId, String songId) async {
    // Try batch and single
    try {
      await _client.post(
        ApiConstants.playlistTracks(playlistId),
        data: {'songId': songId},
      );
    } catch (e) {
      // Fallback for servers expecting songIds array
      await _client.post(
        ApiConstants.playlistTracks(playlistId),
        data: {
          'songIds': [songId],
        },
      );
    }
  }

  Future<void> addTracks(String playlistId, List<String> songIds) async {
    await _client.post(
      ApiConstants.playlistTracks(playlistId),
      data: {'songIds': songIds},
    );
  }

  Future<void> removeTrack(String playlistId, String songId) async {
    await _client.delete(ApiConstants.playlistTrackById(playlistId, songId));
  }

  Future<void> reorder(String playlistId, List<String> orderedIds) async {
    await _client.put(
      ApiConstants.playlistReorder(playlistId),
      data: {'orderedIds': orderedIds},
    );
  }
}
