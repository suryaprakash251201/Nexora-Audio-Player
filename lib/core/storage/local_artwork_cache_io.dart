import 'dart:io';

import 'package:path_provider/path_provider.dart';

const _subdir = 'device_art';

Future<Directory> _dir() async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory('${tmp.path}/$_subdir');
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

/// File:// URI of a previously cached artwork file, or null.
Future<String?> readCachedArtworkUri(String fileName) async {
  try {
    final file = File('${(await _dir()).path}/$fileName');
    if (await file.exists()) return Uri.file(file.path).toString();
    return null;
  } catch (_) {
    return null;
  }
}

/// Persists artwork bytes, returning their file:// URI (or null).
Future<String?> writeCachedArtwork(String fileName, List<int> bytes) async {
  try {
    final file = File('${(await _dir()).path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return Uri.file(file.path).toString();
  } catch (_) {
    return null;
  }
}
