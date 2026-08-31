import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/paginated.dart';
import '../../domain/entities/song.dart';
import '../dto/album_dto.dart';
import '../dto/artist_dto.dart';
import '../dto/paginated_response_dto.dart';
import '../dto/song_dto.dart';

final artistsApiProvider = Provider<ArtistsApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return ArtistsApi(c);
});

class ArtistsApi {
  final ApiClient _client;
  ArtistsApi(this._client);

  Future<Paginated<Artist>> getArtists({int page = 1, int limit = 20, String? query, CancelToken? cancelToken}) async {
    final res = await _client.get(ApiConstants.artists, query: {
      'page': page,
      'limit': limit,
      if (query != null && query.isNotEmpty) 'q': query,
    }, cancelToken: cancelToken);
    final dto = PaginatedResponseDto.fromJson<Artist>(res.data, (m) => ArtistDto.fromJson(m).toEntity(), fallbackPage: page, fallbackLimit: limit);
    return dto.toEntity();
  }

  Future<Artist> getArtist(String id) async {
    final res = await _client.get(ApiConstants.artistById(id));
    final raw = res.data as Map<String, dynamic>?;
    Map<String, dynamic> j = raw?['data'] is Map ? raw!['data'] as Map<String, dynamic> : (raw ?? {});
    if (j['artist'] is Map) j = j['artist'] as Map<String, dynamic>;
    return ArtistDto.fromJson(j).toEntity();
  }

  Future<Paginated<Song>> getArtistSongs(String id, {int page = 1, int limit = 20, CancelToken? cancelToken}) async {
    final res = await _client.get(ApiConstants.artistSongs(id), query: {'page': page, 'limit': limit}, cancelToken: cancelToken);
    final dto = PaginatedResponseDto.fromJson<Song>(res.data, (m) => SongDto.fromJson(m).toEntity(), fallbackPage: page, fallbackLimit: limit);
    // If endpoint returns raw list without pagination wrapper
    if (dto.data.isEmpty && res.data is List) {
      final list = (res.data as List).whereType<Map<String, dynamic>>().map((e) => SongDto.fromJson(e).toEntity()).toList();
      return Paginated.singlePage(list);
    }
    return dto.toEntity();
  }

  Future<Paginated<Album>> getArtistAlbums(String id, {int page = 1, int limit = 20, CancelToken? cancelToken}) async {
    final res = await _client.get(ApiConstants.artistAlbums(id), query: {'page': page, 'limit': limit}, cancelToken: cancelToken);
    final dto = PaginatedResponseDto.fromJson<Album>(res.data, (m) => AlbumDto.fromJson(m).toEntity(), fallbackPage: page, fallbackLimit: limit);
    return dto.toEntity();
  }
}
