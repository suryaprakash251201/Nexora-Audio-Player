import 'package:flutter/foundation.dart';

enum LogCategory {
  auth,
  api,
  player,
  queue,
  sync,
  cache,
  download,
  lifecycle,
  network,
}

class AppLogger {
  const AppLogger._();

  static void log(LogCategory category, String message) {
    if (kDebugMode) {
      final cat = category.name.toUpperCase().padRight(8);
      // ignore: avoid_print
      print('[$cat] $message');
    }
  }

  static void auth(String msg) => log(LogCategory.auth, msg);
  static void api(String msg) => log(LogCategory.api, msg);
  static void player(String msg) => log(LogCategory.player, msg);
  static void queue(String msg) => log(LogCategory.queue, msg);
  static void sync(String msg) => log(LogCategory.sync, msg);
  static void cache(String msg) => log(LogCategory.cache, msg);
  static void download(String msg) => log(LogCategory.download, msg);
  static void lifecycle(String msg) => log(LogCategory.lifecycle, msg);
  static void network(String msg) => log(LogCategory.network, msg);

  /// Never log tokens / secrets. This helper redacts Authorization header.
  static String redact(String input) {
    return input.replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***');
  }
}
