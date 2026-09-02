import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/history_repository.dart';
import '../../../domain/entities/playback_history.dart';
import '../../../domain/entities/song.dart';

/// How many history entries feed the stats window.
///
/// Large enough to describe real habits, small enough that the aggregate
/// stays instant on a phone.
const int statsHistoryLimit = 200;

/// Aggregated listening behaviour.
///
/// Everything here is computed on-device from the merged history feed, so
/// the figures remain accurate even when the Nexora server is unreachable.
class ListeningStats {
  const ListeningStats({
    required this.totalPlays,
    required this.totalSeconds,
    required this.uniqueTracks,
    required this.topArtists,
    required this.playsByHour,
    required this.dayStreak,
    this.topTrack,
    this.topTrackPlays = 0,
  });

  /// Number of history entries considered.
  final int totalPlays;

  /// Sum of every recorded play duration, in seconds.
  final int totalSeconds;

  /// Distinct song ids in the window.
  final int uniqueTracks;

  /// Artists ordered by time listened (descending).
  final List<ArtistListening> topArtists;

  /// 24 buckets, one per hour of the day.
  final List<int> playsByHour;

  /// Consecutive days with at least one play, ending today or yesterday.
  final int dayStreak;

  /// The single most-played track, when it can be resolved.
  final Song? topTrack;

  /// How many times [topTrack] appears in the window.
  final int topTrackPlays;

  factory ListeningStats.empty() => ListeningStats(
        totalPlays: 0,
        totalSeconds: 0,
        uniqueTracks: 0,
        topArtists: const <ArtistListening>[],
        playsByHour: List<int>.filled(24, 0),
        dayStreak: 0,
      );

  factory ListeningStats.fromHistory(List<PlaybackHistoryItem> items) {
    final artistTallies = <String, _Tally>{};
    final trackTallies = <String, _Tally>{};
    final trackLookup = <String, Song>{};
    final playsByHour = List<int>.filled(24, 0);
    final days = <DateTime>[];

    var totalSeconds = 0;
    for (final item in items) {
      final seconds = item.playDuration ?? 0;
      totalSeconds += seconds;

      playsByHour[item.playedAt.hour] += 1;
      days.add(_dateOnly(item.playedAt));

      final song = item.song;
      if (song == null) continue;

      final artist = (song.artist ?? '').trim().isEmpty
          ? 'Unknown Artist'
          : song.artist!.trim();
      final artistTally =
          artistTallies.putIfAbsent(artist, () => _Tally());
      artistTally.plays += 1;
      artistTally.seconds += seconds;

      final trackTally = trackTallies.putIfAbsent(song.id, () => _Tally());
      trackTally.plays += 1;
      trackTally.seconds += seconds;
      trackLookup.putIfAbsent(song.id, () => song);
    }

    final topArtists = artistTallies.entries
        .map(
          (e) => ArtistListening(
            name: e.key,
            plays: e.value.plays,
            seconds: e.value.seconds,
          ),
        )
        .toList()
      ..sort((a, b) => b.seconds.compareTo(a.seconds));

    String? topTrackId;
    var topTrackPlays = 0;
    for (final entry in trackTallies.entries) {
      if (entry.value.plays > topTrackPlays) {
        topTrackPlays = entry.value.plays;
        topTrackId = entry.key;
      }
    }

    return ListeningStats(
      totalPlays: items.length,
      totalSeconds: totalSeconds,
      uniqueTracks: trackTallies.length,
      topArtists: topArtists.take(5).toList(),
      playsByHour: playsByHour,
      dayStreak: _streakFrom(days),
      topTrack: topTrackId == null ? null : trackLookup[topTrackId],
      topTrackPlays: topTrackPlays,
    );
  }

  double get totalHours => totalSeconds / 3600;

  /// Highest value in [playsByHour], or 0 when there is no history.
  int get peakHourPlays =>
      playsByHour.isEmpty ? 0 : playsByHour.reduce(_max);

  /// Hour of day (0–23) with the most plays; -1 when there is no history.
  int get peakHour =>
      peakHourPlays == 0 ? -1 : playsByHour.indexOf(peakHourPlays);

  /// Human label for the busiest hour, e.g. "20:00".
  String get peakHourLabel {
    final hour = peakHour;
    if (hour < 0) return '—';
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  bool get isEmpty => totalPlays == 0;

  static int _max(int a, int b) => a > b ? a : b;

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Counts consecutive days ending today (or yesterday, so a streak is not
  /// broken simply because the listener has not started today yet).
  static int _streakFrom(List<DateTime> days) {
    if (days.isEmpty) return 0;
    final unique = days.toSet().toList()..sort((a, b) => b.compareTo(a));

    final today = _dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final DateTime? start = unique.first == today
        ? today
        : (unique.first == yesterday ? yesterday : null);
    if (start == null) return 0;

    var cursor = start;
    var streak = 0;
    for (final day in unique) {
      if (day == cursor) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (day.isBefore(cursor)) {
        break;
      }
    }
    return streak;
  }
}

/// One artist's share of listening time.
class ArtistListening {
  const ArtistListening({
    required this.name,
    required this.plays,
    required this.seconds,
  });

  final String name;
  final int plays;
  final int seconds;
}

class _Tally {
  int plays = 0;
  int seconds = 0;
}

/// Aggregated listening stats for the current user.
final listeningStatsProvider = FutureProvider<ListeningStats>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  final items = await repo.getHistory(page: 1, limit: statsHistoryLimit);
  return ListeningStats.fromHistory(items);
});
