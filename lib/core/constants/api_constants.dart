class ApiConstants {
  const ApiConstants._();

  // Auth (real Nexora)
  static const login = '/auth/login';
  static const session = '/auth/session';
  static const logout = '/auth/logout';
  static const me = '/auth/session';
  static const needsSetup = '/auth/needs-setup';
  static const version = '/version';
  static const healthz = '/healthz';

  // Storage roots
  static const roots = '/roots';

  // Files (library source of truth: audio files)
  static const files = '/files';
  static const filesRaw = '/files/raw';
  static const filesThumbnail = '/files/thumbnail';
  static const filesDownload = '/files/download';
  static const audioInfo = '/audio/info';
  static const audioLyrics = '/audio/lyrics';

  // Search
  static const search = '/search';

  // Favorites (real: root+path based)
  static const favorites = '/favorites';

  // Recents (playback history as tracked by the server)
  static const recents = '/recents';

  // Playlists
  static const playlists = '/playlists';
  static const playlistsPublic = '/playlists/public';
  static String playlistById(String id) => '/playlists/$id';
  static String playlistItems(String id) => '/playlists/$id/items';
  static String playlistItemOrder(String id) => '/playlists/$id/items/order';

  // Home dashboard
  static const home = '/home';

  // Legacy/compat (unused by real server but kept for alt backends)
  static const refresh = '/auth/refresh';
  static const albums = '/albums';
  static const artists = '/artists';
  static const history = '/history';
  static const serverInfo = '/server/info';
  static const health = '/health';
}
