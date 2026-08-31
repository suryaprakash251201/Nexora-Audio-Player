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
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
