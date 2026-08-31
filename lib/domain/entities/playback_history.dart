import 'song.dart';

class PlaybackHistoryItem {
  final String songId;
  final Song? song;
  final DateTime playedAt;
  final int? playDuration;
  final double? completion; // 0..1

  const PlaybackHistoryItem({
    required this.songId,
    this.song,
    required this.playedAt,
    this.playDuration,
    this.completion,
  });
}
