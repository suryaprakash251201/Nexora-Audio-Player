import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/search_result.dart';
import '../dto/file_dto.dart';

final searchApiProvider = Provider<SearchApi>((ref) {
  final c = ref.watch(apiClientProvider);
  return SearchApi(c);
});

class SearchApi {
  final ApiClient _client;
  SearchApi(this._client);

  Future<SearchResult> search(String query, {CancelToken? cancelToken}) async {
    final res = await _client.get(
      ApiConstants.search,
      query: {'q': query, 'kind': 'audio', 'limit': 100},
      cancelToken: cancelToken,
    );
    final data = res.data;
    List<dynamic> items = [];
    if (data is Map<String, dynamic>) {
      items = (data['items'] as List?) ?? [];
    } else if (data is List) {
      items = data;
    }
    final songs = <Song>[];
    for (final raw in items) {
      if (raw is! Map<String, dynamic>) continue;
      final f = FileItemDto.fromJson(raw);
      if (!NexoraFiles.isAudio(f)) continue;
      songs.add(NexoraFiles.toSong(f));
    }
    return SearchResult(query: query, songs: songs);
  }
}
