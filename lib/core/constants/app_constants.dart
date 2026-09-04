class AppConstants {
  const AppConstants._();

  static const appName = 'Nexora';
  static const artworkPlaceholder = 'assets/logo.png';
  static const defaultPaginationLimit = 20;
  static const maxPaginationLimit = 100;
  static const debounceMs = 300;
  static const cacheMaxAgeSongs = Duration(minutes: 2);
  static const cacheMaxAgeServerInfo = Duration(minutes: 5);

  // Storage keys
  static const serverUrlKey = 'nexora_server_url';
  static const tokenKey = 'nexora_auth_token';
  static const refreshTokenKey = 'nexora_refresh_token';
  static const userKey = 'nexora_user_json';
}
