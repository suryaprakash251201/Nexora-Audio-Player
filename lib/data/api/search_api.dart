import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/search_result.dart';
import '../dto/album_dto.dart';
import '../dto/artist_dto.dart';
import '../dto/playlist_dto.dart';
import '../dto/song_dto.dart';

final searchApiProvider = Provider<SearchApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return SearchApi(c);
});

class SearchApi {
  final ApiClient _client;
  SearchApi(this._client);

  Future<SearchResult> search(String query, {CancelToken? cancelToken}) async {
    if (query.trim().isEmpty) return SearchResult(query: query);
    final res = await _client.get(ApiConstants.search, query: {'q': query, 'query': query}, cancelToken: cancelToken);
    final data = res.data;

    List<Map<String, dynamic>> _asList(dynamic v) {
      if (v is List) return v.whereType<Map<String, dynamic>>().toList();
      return [];
    }

    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map ? data['data'] as Map<String, dynamic> : data;
      // Nested results: {results: {songs:[], albums:[]}}
      Map<String, dynamic> results = {};
      if (payload['results'] is Map) {
        results = payload['results'] as Map<String, dynamic>;
      } else if (payload['songs'] != null || payload['albums'] != null) {
        results = payload;
      }

      final songs = _asList(results['songs'] ?? payload['songs']).map((e) => SongDto.fromJson(e).toEntity()).toList();
      final albums = _asList(results['albums'] ?? payload['albums']).map((e) => AlbumDto.fromJson(e).toEntity()).toList();
      final artists = _asList(results['artists'] ?? payload['artists']).map((e) => ArtistDto.fromJson(e).toEntity()).toList();
      final playlists = _asList(results['playlists'] ?? payload['playlists']).map((e) => PlaylistDto.fromJson(e).toEntity()).toList();

      // Fallback: if API returned flat lists per type under different keys
      return SearchResult(query: query, songs: songs, albums: albums, artists: artists, playlists: playlists);
    } else if (data is List) {
      // Single-type search returning songs
      final songs = data.whereType<Map<String, dynamic>>().map((e) => SongDto.fromJson(e).toEntity()).toList();
      return SearchResult(query: query, songs: songs);
    }
    return SearchResult(query: query);
  }
}
