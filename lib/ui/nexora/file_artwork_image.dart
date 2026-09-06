export 'file_artwork_image_stub.dart'
    if (dart.library.io) 'file_artwork_image_io.dart';

/// True for cached on-disk artwork URIs. Only the explicit file:// scheme
/// counts — server-relative paths like "/covers/x.jpg" are NOT files.
bool isFileArtworkUri(String? url) =>
    url != null && url.startsWith('file://');
