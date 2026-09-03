String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (d.inHours > 0) {
    final h = d.inHours.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
  return '$m:$s';
}

String formatBitrate(int? kbps) {
  if (kbps == null) return '--';
  return '$kbps kbps';
}

String formatSampleRate(int? hz) {
  if (hz == null) return '--';
  if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(1)} kHz';
  return '$hz Hz';
}

String formatFileSize(int? bytes) {
  if (bytes == null) return '--';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes < 1024 * 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)} TB';
}

/// Thousands-separated integer, e.g. 1234567 -> "1,234,567".
String formatCount(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
