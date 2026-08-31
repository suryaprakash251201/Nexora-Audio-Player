import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';

final playlistsApiProvider = Provider<PlaylistsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return PlaylistsApi(c);
});

/// Real Nexora playlists:
/// GET  /playlists -> {items:[{id,name,description,cover_root_id,cover_path,is_public,created_at,updated_at,items:[{id,root_id,path,name,extension,mime,size,modified}]}]}
/// POST /playlists {name,description,items?} -> 201 playlist
/// PUT  /playlists/{id} {name} | PATCH {description,is_public,...}
/// POST /playlists/{id}/items {items:[{root_id,path}]}
/// DEL  /playlists/{id}/items?item_id=
/// PUT  /playlists/{id}/items/order {item_ids:[...]}
class PlaylistsApi {
  final ApiClient _client;
  PlaylistsApi(this._client);

  Song _itemToSong(Map<String, dynamic> raw) {
    final rootId = (raw['root_id'] ?? '').toString();
    final path = (raw['path'] ?? '').toString();
    final name = (raw['name'] ?? '').toString();
    final f = FileItemDto(
      name: name,
      path: path,
      size: (raw['size'] is int) ? raw['size'] as int : 0,
      isDir: false,
      modified: (raw['modified'] ?? '').toString(),
      mime: (raw['mime'] ?? '').toString(),
      rootId: rootId,
      extension:
          (raw['extension'] ?? (name.contains('.') ? name.split('.').last : ''))
              .toString(),
    );
    return NexoraFiles.toSong(f, itemRef: (raw['id'] ?? '').toString());
  }

  Future<List<Playlist>> getPlaylists() async {
    final res = await _client.get(ApiConstants.playlists);
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    final out = <Playlist>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final tracks = <Song>[];
      final rawItems = (raw['items'] as List?) ?? [];
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) tracks.add(_itemToSong(it));
      }
      out.add(
        Playlist(
          id: (raw['id'] ?? '').toString(),
          name: (raw['name'] ?? 'Untitled').toString(),
          description: raw['description']?.toString(),
          coverUrl: null,
          trackCount: tracks.length,
          isPublic: raw['is_public'] == true,
          tracks: tracks,
        ),
      );
    }
    return out;
  }

  Future<Playlist> getPlaylist(String id) async {
    final all = await getPlaylists();
    return all.firstWhere(
      (p) => p.id == id,
      orElse: () => Playlist(id: id, name: 'Playlist'),
    );
  }

  Future<List<Song>> getPlaylistTracks(String id) async {
    final p = await getPlaylist(id);
    return p.tracks ?? [];
  }

  Future<Playlist> createPlaylist({
    required String name,
    String? description,
  }) async {
    final res = await _client.post(
      ApiConstants.playlists,
      data: {
        'name': name,
        'description': description ?? '',
        'items': <Map<String, dynamic>>[],
      },
    );
    final raw = res.data;
    if (raw is Map<String, dynamic>) {
      final tracks = <Song>[];
      for (final it in (raw['items'] as List?) ?? []) {
        if (it is Map<String, dynamic>) tracks.add(_itemToSong(it));
      }
      return Playlist(
        id: (raw['id'] ?? '').toString(),
        name: (raw['name'] ?? name).toString(),
        description: raw['description']?.toString(),
        trackCount: tracks.length,
        tracks: tracks,
      );
    }
    return Playlist(id: '', name: name, description: description);
  }

  Future<void> renamePlaylist(String id, String name) async {
    await _client.put(ApiConstants.playlistById(id), data: {'name': name});
  }

  Future<void> updateDescription(String id, String description) async {
    await _client.patch(
      ApiConstants.playlistById(id),
      data: {'description': description},
    );
  }

  Future<void> deletePlaylist(String id) async {
    await _client.delete(ApiConstants.playlistById(id));
  }

  Future<void> addTrack(String playlistId, String songId) async {
    final root = NexoraFiles.parseRootId(songId);
    final path = NexoraFiles.parsePath(songId);
    await _client.post(
      ApiConstants.playlistItems(playlistId),
      data: {
        'items': [
          {'root_id': root, 'path': path},
        ],
      },
    );
  }

  Future<void> removeTrack(String playlistId, String itemId) async {
    await _client.delete(
      ApiConstants.playlistItems(playlistId),
      query: {'item_id': itemId},
    );
  }

  Future<void> reorder(String playlistId, List<String> orderedItemIds) async {
    await _client.put(
      ApiConstants.playlistItemOrder(playlistId),
      data: {'item_ids': orderedItemIds},
    );
  }
}
