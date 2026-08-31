import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/search_result.dart';
import '../api/search_api.dart';
import '../../core/storage/prefs_service.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final api = ref.watch(searchApiProvider);
  final prefs = ref.watch(prefsServiceProvider);
  return SearchRepository(api, prefs);
});

class SearchRepository {
  final SearchApi _api;
  final PrefsService _prefs;
  SearchRepository(this._api, this._prefs);

  Future<SearchResult> search(String query, {CancelToken? cancelToken}) async {
    final res = await _api.search(query, cancelToken: cancelToken);
    if (query.trim().isNotEmpty) {
      try { await _prefs.addRecentSearch(query.trim()); } catch (_) {}
    }
    return res;
  }

  Future<List<String>> recentSearches() => _prefs.getRecentSearches();
  Future<void> clearRecent() => _prefs.clearRecentSearches();
}
