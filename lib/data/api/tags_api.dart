import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

final tagsApiProvider = Provider<TagsApi>((ref) {
  return TagsApi(ref.watch(apiClientProvider));
});

/// Cached tag list. Invalidated after create/rename/delete.
final tagsProvider = FutureProvider<List<NexoraTag>>((ref) async {
  return ref.watch(tagsApiProvider).getTags();
});

/// Personal file tag (`{id,name,color,created_at,count}`).
class NexoraTag {
  final String id;
  final String name;
  final String colorHex;
  final String createdAt;
  final int count;

  const NexoraTag({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.createdAt,
    required this.count,
  });

  factory NexoraTag.fromJson(Map<String, dynamic> j) => NexoraTag(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    colorHex: (j['color'] ?? '#6366f1').toString(),
    createdAt: (j['created_at'] ?? '').toString(),
    count: j['count'] is int
        ? j['count'] as int
        : int.tryParse((j['count'] ?? '0').toString()) ?? 0,
  );

  /// `#rrggbb` (or `#aarrggbb`) → Color, brand fallback on garbage.
  Color get color {
    var hex = colorHex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final v = int.tryParse(hex, radix: 16);
    if (v == null) return const Color(0xFF6366F1);
    return Color(v);
  }
}

class TagsApi {
  final ApiClient _client;
  TagsApi(this._client);

  Future<List<NexoraTag>> getTags() async {
    final res = await _client.get(ApiConstants.tags);
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['tags'] as List? : null) ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(NexoraTag.fromJson)
        .toList();
  }

  Future<NexoraTag> createTag(String name, {String color = '#6366f1'}) async {
    final res = await _client.post(
      ApiConstants.tags,
      data: {'name': name, 'color': color},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return NexoraTag.fromJson(data);
    throw Exception('Unexpected tag response');
  }

  Future<void> updateTag(String id, {String? name, String? color}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (color != null) data['color'] = color;
    await _client.patch(ApiConstants.tagById(id), data: data);
  }

  Future<void> deleteTag(String id) async {
    await _client.delete(ApiConstants.tagById(id));
  }

  /// Applies a tag to one file. Read access suffices server-side.
  Future<void> tagFile({
    required String tagId,
    required String rootId,
    required String path,
  }) async {
    await _client.post(
      ApiConstants.filesTag,
      data: {
        'tag_id': tagId,
        'root_id': rootId,
        'paths': [path],
      },
    );
  }

  /// Removes a tag from one file (web-client query-string convention).
  Future<void> untagFile({
    required String tagId,
    required String rootId,
    required String path,
  }) async {
    await _client.delete(
      ApiConstants.filesTag,
      query: {'tag_id': tagId, 'root_id': rootId, 'paths': path},
    );
  }
}
