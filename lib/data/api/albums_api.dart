import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/paginated.dart';
import '../../domain/entities/song.dart';
import '../dto/album_dto.dart';
import '../dto/paginated_response_dto.dart';
import '../dto/song_dto.dart';

final albumsApiProvider = Provider<AlbumsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return AlbumsApi(c);
});

class AlbumsApi {
  final ApiClient _client;
  AlbumsApi(this._client);

  Future<Paginated<Album>> getAlbums({
    int page = 1,
    int limit = 20,
    String? query,
    CancelToken? cancelToken,
  }) async {
    final res = await _client.get(
      ApiConstants.albums,
      query: {
        'page': page,
        'limit': limit,
        if (query != null && query.isNotEmpty) 'q': query,
      },
      cancelToken: cancelToken,
    );
    final dto = PaginatedResponseDto.fromJson<Album>(
      res.data,
      (m) => AlbumDto.fromJson(m).toEntity(),
      fallbackPage: page,
      fallbackLimit: limit,
    );
    return dto.toEntity();
  }

  Future<Album> getAlbum(String id) async {
    final res = await _client.get(ApiConstants.albumById(id));
    final raw = res.data as Map<String, dynamic>?;
    Map<String, dynamic> j = raw?['data'] is Map
        ? raw!['data'] as Map<String, dynamic>
        : (raw ?? {});
    if (j['album'] is Map) j = j['album'] as Map<String, dynamic>;
    return AlbumDto.fromJson(j).toEntity();
  }

  Future<List<Song>> getAlbumTracks(String id) async {
    final res = await _client.get(ApiConstants.albumTracks(id));
    final data = res.data;
    List<dynamic> list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List)
        list = data['data'] as List;
      else if (data['tracks'] is List)
        list = data['tracks'] as List;
      else if (data['songs'] is List)
        list = data['songs'] as List;
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

  String artworkUrl(String id, {String size = 'medium'}) {
    final base = _client.dio.options.baseUrl;
    return '$base${ApiConstants.albumArtwork(id)}?size=$size';
  }
}
