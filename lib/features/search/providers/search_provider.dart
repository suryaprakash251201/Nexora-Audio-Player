import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/search_repository.dart';
import '../../../domain/entities/search_result.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<SearchResult?>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return null;
  final repo = ref.watch(searchRepositoryProvider);
  // Per-keystroke debounce: each keystroke rebuilds this provider,
  // cancelling the previous evaluation (and its request) via onDispose.
  final cancelToken = CancelToken();
  ref.onDispose(() => cancelToken.cancel());
  // Small delay to debounce rapid provider changes
  await Future.delayed(const Duration(milliseconds: 300));
  if (cancelToken.isCancelled) return null;
  return repo.search(query, cancelToken: cancelToken);
});

final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(searchRepositoryProvider);
  return repo.recentSearches();
});
