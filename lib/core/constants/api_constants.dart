class ApiConstants {
  const ApiConstants._();

  // Auth
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/auth/me';

  // Server
  static const serverInfo = '/server/info';
  static const health = '/health'; // may be outside /api/v1

  // Library
  static const songs = '/songs';
  static String songById(String id) => '/songs/$id';
  static String songStream(String id) => '/songs/$id/stream';
  static String songArtwork(String id) => '/songs/$id/artwork';
  static String songDownload(String id) => '/songs/$id/download';

  static const albums = '/albums';
  static String albumById(String id) => '/albums/$id';
  static String albumTracks(String id) => '/albums/$id/tracks';
  static String albumArtwork(String id) => '/albums/$id/artwork';

  static const artists = '/artists';
  static String artistById(String id) => '/artists/$id';
  static String artistSongs(String id) => '/artists/$id/songs';
  static String artistAlbums(String id) => '/artists/$id/albums';
  static String artistArtwork(String id) => '/artists/$id/artwork';

  // Playlists
  static const playlists = '/playlists';
  static String playlistById(String id) => '/playlists/$id';
  static String playlistTracks(String id) => '/playlists/$id/tracks';
  static String playlistTrackById(String playlistId, String songId) =>
      '/playlists/$playlistId/tracks/$songId';
  static String playlistReorder(String id) => '/playlists/$id/reorder';

  // Favorites
  static const favorites = '/favorites';
  static String favoriteBySongId(String songId) => '/favorites/$songId';

  // History
  static const history = '/history';

  // Search
  static const search = '/search';

  // Settings
  static const settings = '/settings';
  static const user = '/user';
}
