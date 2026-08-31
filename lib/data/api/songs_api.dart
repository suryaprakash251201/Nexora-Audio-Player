import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/paginated.dart';
import '../../domain/entities/song.dart';
import '../dto/paginated_response_dto.dart';
import '../dto/song_dto.dart';

final songsApiProvider = Provider<SongsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return SongsApi(c);
});

class SongsApi {
  final ApiClient _client;
  SongsApi(this._client);

  Future<Paginated<Song>> getSongs({
    int page = 1,
    int limit = 20,
    String? sort,
    String? order,
    String? query,
    String? albumId,
    String? artistId,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get(
      ApiConstants.songs,
      query: {
        'page': page,
        'limit': limit,
        if (sort != null) 'sort': sort,
        if (order != null) 'order': order,
        if (query != null && query.isNotEmpty) 'q': query,
        if (albumId != null) 'albumId': albumId,
        if (artistId != null) 'artistId': artistId,
      },
      cancelToken: cancelToken,
    );
    final dto = PaginatedResponseDto.fromJson<Song>(
      res.data,
      (m) => SongDto.fromJson(m).toEntity(),
      fallbackPage: page,
      fallbackLimit: limit,
    );
    // If total ==0 but data has items (single page), fix
    return dto.toEntity();
  }

  Future<Song> getSong(String id, {CancelToken? cancelToken}) async {
    final res = await _client.get(ApiConstants.songById(id), cancelToken: cancelToken);
    final data = res.data;
    Map<String, dynamic> j;
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        j = data['data'] as Map<String, dynamic>;
        // Some APIs nest song under data.song
        if (j['song'] is Map) j = j['song'] as Map<String, dynamic>;
      } else if (data['song'] is Map) {
        j = data['song'] as Map<String, dynamic>;
      } else {
        j = data;
      }
    } else {
      j = {};
    }
    return SongDto.fromJson(j).toEntity();
  }

  String streamUrl(String id) {
    final base = _client.dio.options.baseUrl;
    // Use constant to build
    return '$base${ApiConstants.songStream(id)}';
  }

  String artworkUrl(String id, {String size = 'medium'}) {
    final base = _client.dio.options.baseUrl;
    return '$base${ApiConstants.songArtwork(id)}?size=$size';
  }
}
