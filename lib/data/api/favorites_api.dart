import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/song.dart';
import '../dto/file_dto.dart';

final favoritesApiProvider = Provider<FavoritesApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return FavoritesApi(c);
});

/// Real Nexora favorites: root+path based.
/// GET /favorites -> {items:[{root_id,root_name,path,name,created_at}]}
/// POST /favorites {root,path} / DELETE /favorites?root=&path=
class FavoritesApi {
  final ApiClient _client;
  FavoritesApi(this._client);

  Future<List<Song>> getFavorites() async {
    final res = await _client.get(ApiConstants.favorites);
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    final songs = <Song>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final rootId = (raw['root_id'] ?? '').toString();
      final path = (raw['path'] ?? '').toString();
      final name = (raw['name'] ?? '').toString();
      if (rootId.isEmpty || path.isEmpty) continue;
      final f = FileItemDto(
        name: name,
        path: path,
        size: 0,
        isDir: false,
        modified: (raw['created_at'] ?? '').toString(),
        mime: '',
        rootId: rootId,
        extension: name.contains('.') ? name.split('.').last : '',
      );
      songs.add(NexoraFiles.toSong(f, isFavorite: true));
    }
    return songs;
  }

  Future<void> addFavorite(String songId) async {
    final parts = NexoraFiles.splitId(songId);
    await _client.post(
      ApiConstants.favorites,
      data: {'root': parts.root, 'path': parts.path},
    );
  }

  Future<void> removeFavorite(String songId) async {
    final parts = NexoraFiles.splitId(songId);
    await _client.delete(
      ApiConstants.favorites,
      query: {'root': parts.root, 'path': parts.path},
    );
  }
}
