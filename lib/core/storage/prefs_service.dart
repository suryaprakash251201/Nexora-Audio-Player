import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final prefsServiceProvider = Provider<PrefsService>((ref) => PrefsService());

class PrefsService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> setString(String key, String value) async {
    final p = await _instance;
    await p.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final p = await _instance;
    return p.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    final p = await _instance;
    await p.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final p = await _instance;
    return p.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    final p = await _instance;
    await p.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final p = await _instance;
    return p.getInt(key);
  }

  Future<void> remove(String key) async {
    final p = await _instance;
    await p.remove(key);
  }

  // Server info cache
  static const _serverInfoKey = 'cache_server_info';
  static const _serverInfoTsKey = 'cache_server_info_ts';

  Future<void> cacheServerInfo(String json) async {
    final p = await _instance;
    await p.setString(_serverInfoKey, json);
    await p.setInt(_serverInfoTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getCachedServerInfo() async {
    final p = await _instance;
    return p.getString(_serverInfoKey);
  }

  Future<int?> getCachedServerInfoTs() async {
    final p = await _instance;
    return p.getInt(_serverInfoTsKey);
  }

  // Recent searches
  static const _recentSearchesKey = 'recent_searches';
  Future<List<String>> getRecentSearches() async {
    final p = await _instance;
    return p.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String q) async {
    final p = await _instance;
    final list = p.getStringList(_recentSearchesKey) ?? [];
    list.remove(q);
    list.insert(0, q);
    if (list.length > 10) list.removeLast();
    await p.setStringList(_recentSearchesKey, list);
  }

  Future<void> clearRecentSearches() async {
    final p = await _instance;
    await p.remove(_recentSearchesKey);
  }
}
