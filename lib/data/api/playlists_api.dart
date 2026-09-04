import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';

final playlistsApiProvider = Provider<PlaylistsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  final s = ref.watch(secureStorageProvider);
  return PlaylistsApi(c, s);
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
  final SecureStorageService _storage;
  PlaylistsApi(this._client, this._storage);

  /// Resolves the correct API base URL from secure storage (not Dio global).
  /// Mirrors FilesApi._base / SongsApi._resolvedBaseUrl so playlist tracks get
  /// an absolute stream URL; otherwise `_client.dio.options.baseUrl` is
  /// empty/stale (the interceptor only sets it per-request) and playback fails.
  Future<String> _resolvedBaseUrl() async {
    final serverUrl = await _storage.getServerUrl();
    if (serverUrl != null && serverUrl.isNotEmpty) return serverUrl;
    return _client.dio.options.baseUrl;
  }

  /// Memoized playlist list: detail, covers, home and library rails all
  /// hit `getPlaylists()` within seconds of each other, and the backend has
  /// no single-playlist endpoint — one fetch per [cacheTtl], not per caller.
  static const cacheTtl = Duration(seconds: 30);
  List<Playlist>? _cached;
  DateTime? _cachedAt;

  void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  Future<Song> _itemToSong(
    Map<String, dynamic> raw,
    String base,
    String token,
  ) async {
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
    return NexoraFiles.toSong(
      f,
      artworkUrl: NexoraFiles.thumbnailUrl(
        base,
        rootId,
        path,
        token,
        size: 512,
      ),
      streamUrl: NexoraFiles.rawUrl(base, rootId, path, token),
      itemRef: (raw['id'] ?? '').toString(),
    );
  }

  /// Server-set cover (cover_root_id + cover_path on the playlist) as an
  /// authenticated thumbnail URL. Null when the owner never set one.
  String? _serverCover(Map<String, dynamic> raw, String base, String token) {
    final root = (raw['cover_root_id'] ?? '').toString();
    final path = (raw['cover_path'] ?? '').toString();
    if (root.isEmpty || path.isEmpty) return null;
    return NexoraFiles.thumbnailUrl(base, root, path, token, size: 512);
  }

  /// Shared parser for both `/playlists` and `/playlists/public`: same
  /// envelope, same item hydration, owner cover preferred.
  Future<List<Playlist>> _parsePlaylists(
    List<dynamic> items,
    String base,
    String token,
  ) async {
    final out = <Playlist>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final tracks = <Song>[];
      final rawItems = (raw['items'] as List?) ?? [];
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          tracks.add(await _itemToSong(it, base, token));
        }
      }
      // Prefer the owner's server-side cover; fall back to first track art.
      final serverCover = _serverCover(raw, base, token);
      final owner = (raw['owner_username'] ?? '').toString();
      out.add(
        Playlist(
          id: (raw['id'] ?? '').toString(),
          name: (raw['name'] ?? 'Untitled').toString(),
          description: raw['description']?.toString(),
          coverUrl:
              serverCover ??
              tracks
                  .map((track) => track.coverUrl ?? track.artworkUrl)
                  .firstWhere(
                    (url) => url != null && url.isNotEmpty,
                    orElse: () => null,
                  ),
          trackCount: tracks.length,
          isPublic: raw['is_public'] == true,
          ownerId: owner.isEmpty ? null : owner,
          tracks: tracks,
        ),
      );
    }
    return out;
  }

  Future<List<Playlist>> getPlaylists() async {
    final fresh =
        _cachedAt != null && DateTime.now().difference(_cachedAt!) < cacheTtl;
    if (fresh && _cached != null) return _cached!;
    final res = await _client.get(ApiConstants.playlists);
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    final base = await _resolvedBaseUrl();
    final token = await _storage.getToken() ?? '';
    final parsed = await _parsePlaylists(items, base, token);
    _cached = parsed;
    _cachedAt = DateTime.now();
    return parsed;
  }

  /// Community playlists shared by other users (same shape as mine).
  Future<List<Playlist>> getPublicPlaylists() async {
    final res = await _client.get(ApiConstants.playlistsPublic);
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    final base = await _resolvedBaseUrl();
    final token = await _storage.getToken() ?? '';
    final all = await _parsePlaylists(items, base, token);
    // Never duplicate playlists the user already owns.
    final mine = await getPlaylists();
    final mineIds = mine.map((p) => p.id).toSet();
    return all.where((p) => !mineIds.contains(p.id)).toList();
  }

  Future<Playlist> getPlaylist(String id) async {
    final all = await getPlaylists();
    for (final p in all) {
      if (p.id == id) return p;
    }
    // Discover cards open the same detail screen.
    try {
      final pub = await getPublicPlaylists();
      for (final p in pub) {
        if (p.id == id) return p;
      }
    } catch (_) {}
    return Playlist(id: id, name: 'Playlist');
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
      final base = await _resolvedBaseUrl();
      final token = await _storage.getToken() ?? '';
      final tracks = <Song>[];
      for (final it in (raw['items'] as List?) ?? []) {
        if (it is Map<String, dynamic>) {
          tracks.add(await _itemToSong(it, base, token));
        }
      }
      invalidateCache();
      return Playlist(
        id: (raw['id'] ?? '').toString(),
        name: (raw['name'] ?? name).toString(),
        description: raw['description']?.toString(),
        coverUrl: _serverCover(raw, base, token),
        trackCount: tracks.length,
        tracks: tracks,
      );
    }
    return Playlist(id: '', name: name, description: description);
  }

  Future<void> renamePlaylist(String id, String name) async {
    await _client.put(ApiConstants.playlistById(id), data: {'name': name});
    invalidateCache();
  }

  Future<void> updateDescription(String id, String description) async {
    await _client.patch(
      ApiConstants.playlistById(id),
      data: {'description': description},
    );
  }

  Future<void> deletePlaylist(String id) async {
    await _client.delete(ApiConstants.playlistById(id));
    invalidateCache();
  }

  Future<void> addTrack(String playlistId, String songId) async {
    final parts = NexoraFiles.splitId(songId);
    await _client.post(
      ApiConstants.playlistItems(playlistId),
      data: {
        'items': [
          {'root_id': parts.root, 'path': parts.path},
        ],
      },
    );
    invalidateCache();
  }

  Future<void> removeTrack(String playlistId, String itemId) async {
    await _client.delete(
      ApiConstants.playlistItems(playlistId),
      query: {'item_id': itemId},
    );
    invalidateCache();
  }

  Future<void> reorder(String playlistId, List<String> orderedItemIds) async {
    await _client.put(
      ApiConstants.playlistItemOrder(playlistId),
      data: {'item_ids': orderedItemIds},
    );
    invalidateCache();
  }

  /// Collaborators (`{collaborators:[{playlist_id,user_id,role,
  /// created_at,username}]}`). Throws 403 for non-editors — callers hide
  /// people UI in that case.
  Future<List<PlaylistCollaborator>> getCollaborators(String id) async {
    final res = await _client.get(ApiConstants.playlistCollaborators(id));
    final data = res.data;
    final items =
        (data is Map<String, dynamic>
            ? data['collaborators'] as List?
            : null) ??
        [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PlaylistCollaborator.fromJson)
        .toList();
  }

  /// `action` is `add` (role defaults to `editor`) or `remove`.
  Future<void> manageCollaborator(
    String id, {
    required String action,
    required String userId,
    String role = 'editor',
  }) async {
    await _client.post(
      ApiConstants.playlistCollaborators(id),
      data: {'action': action, 'user_id': userId, 'role': role},
    );
  }

  /// User picker (`{users:[{id,username}]}`) — no emails or roles.
  Future<List<PlaylistUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return const [];
    final res = await _client.get(
      ApiConstants.usersSearch,
      query: {'q': query.trim()},
    );
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['users'] as List? : null) ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PlaylistUser.fromJson)
        .toList();
  }
}
