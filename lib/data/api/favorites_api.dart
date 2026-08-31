import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/song.dart';
import '../dto/song_dto.dart';

final favoritesApiProvider = Provider<FavoritesApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return FavoritesApi(c);
});

class FavoritesApi {
  final ApiClient _client;
  FavoritesApi(this._client);

  Future<List<Song>> getFavorites() async {
    final res = await _client.get(ApiConstants.favorites);
    final data = res.data;
    List<dynamic> list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List)
        list = data['data'] as List;
      else if (data['songs'] is List)
        list = data['songs'] as List;
      else if (data['favorites'] is List)
        list = data['favorites'] as List;
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

  Future<void> addFavorite(String songId) async {
    await _client.post(ApiConstants.favoriteBySongId(songId));
  }

  Future<void> removeFavorite(String songId) async {
    await _client.delete(ApiConstants.favoriteBySongId(songId));
  }

  Future<bool> isFavorite(String songId) async {
    // No dedicated endpoint; infer from list. Use GET /favorites and check, or try HEAD.
    // Optimized: try to fetch single if server supports.
    try {
      await _client.get(ApiConstants.favoriteBySongId(songId));
      return true;
    } catch (_) {
      return false;
    }
  }
}
