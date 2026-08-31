class ServerFeatures {
  final bool supportsLyrics;
  final bool supportsPlaylists;
  final bool supportsFavorites;
  final bool supportsHistory;
  final bool supportsDownloads;
  final bool supportsRealtimeSync;
  final bool supportsEqualizer;

  const ServerFeatures({
    this.supportsLyrics = false,
    this.supportsPlaylists = true,
    this.supportsFavorites = true,
    this.supportsHistory = true,
    this.supportsDownloads = true,
    this.supportsRealtimeSync = false,
    this.supportsEqualizer = false,
  });

  factory ServerFeatures.fromJson(Map<String, dynamic> json) {
    return ServerFeatures(
      supportsLyrics: json['supportsLyrics'] as bool? ?? false,
      supportsPlaylists: json['supportsPlaylists'] as bool? ?? true,
      supportsFavorites: json['supportsFavorites'] as bool? ?? json['supportsLikes'] as bool? ?? true,
      supportsHistory: json['supportsHistory'] as bool? ?? true,
      supportsDownloads: json['supportsDownloads'] as bool? ?? true,
      supportsRealtimeSync: json['supportsRealtimeSync'] as bool? ?? false,
      supportsEqualizer: json['supportsEqualizer'] as bool? ?? false,
    );
  }
}

class ServerInfo {
  final String serverVersion;
  final String apiVersion;
  final String name;
  final ServerFeatures features;

  const ServerInfo({
    required this.serverVersion,
    required this.apiVersion,
    required this.name,
    required this.features,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as Map<String, dynamic>? ?? {};
    return ServerInfo(
      serverVersion: (json['serverVersion'] ?? json['version'] ?? 'unknown').toString(),
      apiVersion: (json['apiVersion'] ?? 'v1').toString(),
      name: (json['name'] ?? 'Nexora').toString(),
      features: ServerFeatures.fromJson(featuresJson),
    );
  }

  factory ServerInfo.fallback() => const ServerInfo(
        serverVersion: 'unknown',
        apiVersion: 'v1',
        name: 'Nexora',
        features: ServerFeatures(),
      );
}
