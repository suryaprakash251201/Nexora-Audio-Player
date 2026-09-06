/// Non-IO platforms (web): no temp-file cache — callers show placeholders.
Future<String?> readCachedArtworkUri(String fileName) async => null;

/// Non-IO platforms (web): no temp-file cache — callers show placeholders.
Future<String?> writeCachedArtwork(String fileName, List<int> bytes) async =>
    null;
