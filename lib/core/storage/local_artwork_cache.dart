/// Temp-file cache for binary artwork (e.g. on-device song covers).
///
/// Web-safe barrel: native platforms read/write real temp files, other
/// platforms degrade to null (callers fall back to placeholders).
export 'local_artwork_cache_stub.dart'
    if (dart.library.io) 'local_artwork_cache_io.dart';
