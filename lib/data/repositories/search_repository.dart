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

  /// Pure search — never touches recents. Recents are saved explicitly on
  /// submit (see `saveRecentSearch`), otherwise every intermediate
  /// keystroke that completes pollutes the recent list.
  Future<SearchResult> search(String query, {CancelToken? cancelToken}) async {
    return _api.search(query, cancelToken: cancelToken);
  }

  Future<void> saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    try {
      await _prefs.addRecentSearch(q);
    } catch (_) {}
  }

  Future<List<String>> recentSearches() => _prefs.getRecentSearches();
  Future<void> clearRecent() => _prefs.clearRecentSearches();
}
