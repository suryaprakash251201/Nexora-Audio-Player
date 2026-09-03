import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

final sharesApiProvider = Provider<SharesApi>((ref) {
  return SharesApi(ref.watch(apiClientProvider));
});

/// Cached share list. Invalidated after create/revoke.
final sharesProvider = FutureProvider<List<ShareLink>>((ref) async {
  return ref.watch(sharesApiProvider).getShares();
});

/// A public link share (`{id,token,url,root_id,path,name,scope,…}`).
class ShareLink {
  final String id;
  final String token;
  final String url;
  final String rootId;
  final String path;
  final String name;
  final String scope;
  final bool hasPassword;
  final String? expiresAt;
  final int maxDownloads;
  final int downloadCount;
  final String createdAt;

  const ShareLink({
    required this.id,
    required this.token,
    required this.url,
    required this.rootId,
    required this.path,
    required this.name,
    required this.scope,
    required this.hasPassword,
    required this.expiresAt,
    required this.maxDownloads,
    required this.downloadCount,
    required this.createdAt,
  });

  static int _i(dynamic v) =>
      v is int ? v : int.tryParse((v ?? '0').toString()) ?? 0;

  factory ShareLink.fromJson(Map<String, dynamic> j) => ShareLink(
    id: (j['id'] ?? '').toString(),
    token: (j['token'] ?? '').toString(),
    url: (j['url'] ?? '').toString(),
    rootId: (j['root_id'] ?? '').toString(),
    path: (j['path'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    scope: (j['scope'] ?? '').toString(),
    hasPassword: j['has_password'] == true,
    expiresAt: j['expires_at']?.toString(),
    maxDownloads: _i(j['max_downloads']),
    downloadCount: _i(j['download_count']),
    createdAt: (j['created_at'] ?? '').toString(),
  );
}

class SharesApi {
  final ApiClient _client;
  SharesApi(this._client);

  Future<List<ShareLink>> getShares() async {
    final res = await _client.get(ApiConstants.shares);
    final data = res.data;
    final items =
        (data is Map<String, dynamic> ? data['items'] as List? : null) ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ShareLink.fromJson)
        .toList();
  }

  /// Creates a public link. `scope` is `preview` (stream + download) or
  /// `download`. Expiry/downloads caps are optional (0 = unlimited).
  Future<ShareLink> createShare({
    required String root,
    required String path,
    String scope = 'preview',
    String password = '',
    int expiresInHours = 0,
    int maxDownloads = 0,
  }) async {
    final res = await _client.post(
      ApiConstants.shares,
      data: {
        'root': root,
        'path': path,
        'scope': scope,
        'password': password,
        'expires_in_hours': expiresInHours,
        'max_downloads': maxDownloads,
      },
    );
    final data = res.data;
    final raw = (data is Map<String, dynamic> ? data['share'] : null);
    if (raw is Map<String, dynamic>) return ShareLink.fromJson(raw);
    throw Exception('Unexpected share response');
  }

  Future<void> revokeShare(String id) async {
    await _client.delete(ApiConstants.shareById(id));
  }
}
