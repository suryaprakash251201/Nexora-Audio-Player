import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/api/server_stats_api.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_icons.dart';
import '../../../ui/nexora/nexora_motion.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_surfaces.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/artwork_image.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/shimmer_loading.dart';
import '../../player/providers/player_provider.dart';

/// Listening insights, computed locally from playback history.
///
/// The screen is deliberately quiet: one hero figure, a handful of supporting
/// numbers, then two charts. No badges, no streak shaming — just a record of
/// what the listener actually played.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(listeningStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: NexoraAurora(intensity: 0.45)),
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(listeningStatsProvider),
              child: asyncStats.when(
                data: (stats) => _StatsBody(stats: stats),
                loading: () => const _StatsSkeleton(),
                error: (e, _) => ListView(
                  padding: const EdgeInsets.only(top: 120),
                  children: [
                    ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(listeningStatsProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return CustomScrollView(
        slivers: [
          _appBar(context),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _ServerLibraryCard(),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: NexoraEmptyState(
              icon: Icons.insights_outlined,
              title: 'No listening history yet',
              subtitle:
                  'Play a few tracks and your habits — total time, peak hours and top artists — will show up here.',
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        _appBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 170),
            child: NexoraStaggeredColumn(
              children: [
                const SizedBox(height: 12),
                const _ServerLibraryCard(),
                const SizedBox(height: 22),
                _TotalTimeCard(stats: stats),
                const SizedBox(height: 22),
                _MetricRow(stats: stats),
                const SizedBox(height: 30),
                _SectionTitle('Listening by hour'),
                const SizedBox(height: 14),
                _HourlyChartCard(stats: stats),
                if (stats.topArtists.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _SectionTitle('Top artists'),
                  const SizedBox(height: 14),
                  _TopArtistsCard(stats: stats),
                ],
                if (stats.topTrack != null) ...[
                  const SizedBox(height: 30),
                  _SectionTitle('Most played track'),
                  const SizedBox(height: 14),
                  _TopTrackCard(stats: stats),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _appBar(BuildContext context) => SliverAppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    pinned: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 60,
    flexibleSpace: const NexoraSliverAppBarBackground(),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => Navigator.of(context).maybePop(),
      tooltip: 'Back',
    ),
    title: Text(
      'Your stats',
      style: TextStyle(
        color: AppColors.text,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
    ),
  );
}

/// The one figure that matters: total time spent listening.
/// Server library at a glance (audio tracks, sizes, quota).
/// Independent of local history: hides itself on error/offline/empty so
/// the local stats below always render regardless.
class _ServerLibraryCard extends ConsumerWidget {
  const _ServerLibraryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(serverLibraryStatsProvider);
    return async.when(
      data: (s) {
        if (s == null || s.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.cloud_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SERVER LIBRARY',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${formatCount(s.audioCount)} tracks',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatFileSize(s.audioSize)} audio · ${formatCount(s.totalFiles)} files · ${formatFileSize(s.totalSize)} total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              if (s.quotaTotal > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: s.quotaFraction,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatFileSize(s.quotaUsed)} of ${formatFileSize(s.quotaTotal)} used',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => ShimmerLoading(
        child: Container(
          height: 148,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _TotalTimeCard extends StatelessWidget {
  const _TotalTimeCard({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    return NexoraGradientCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NexoraGlyph(
                kind: NexoraGlyphKind.stats,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'TOTAL LISTENING TIME',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NexoraCountUp(
            value: stats.totalHours,
            fractionDigits: 1,
            suffix: ' h',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 46,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.6,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${stats.totalPlays} plays across ${stats.uniqueTracks} '
            '${stats.uniqueTracks == 1 ? 'track' : 'tracks'}',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three supporting figures beneath the hero.
class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: NexoraGlyph(
              kind: NexoraGlyphKind.waveform,
              size: 18,
              color: AppColors.accent,
            ),
            value: stats.totalPlays,
            label: 'Plays',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: NexoraGlyph(
              kind: NexoraGlyphKind.vinyl,
              size: 18,
              color: AppColors.accent,
            ),
            value: stats.topArtists.length,
            label: 'Artists',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            icon: NexoraGlyph(
              kind: NexoraGlyphKind.night,
              size: 18,
              color: AppColors.accent,
            ),
            value: stats.dayStreak,
            label: 'Day streak',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.66),
        borderRadius: NexoraRadius.card,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(height: 12),
          NexoraCountUp(
            value: value.toDouble(),
            style: TextStyle(
              color: AppColors.text,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
    );
  }
}

class _HourlyChartCard extends StatelessWidget {
  const _HourlyChartCard({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final peak = stats.peakHourPlays;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.66),
        borderRadius: NexoraRadius.card,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'When you listen',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'peak ${stats.peakHourLabel}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _HourlyChart(playsByHour: stats.playsByHour, peak: peak),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _HourLabel('00'),
              _HourLabel('06'),
              _HourLabel('12'),
              _HourLabel('18'),
              _HourLabel('23'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.playsByHour, required this.peak});

  final List<int> playsByHour;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final safeMax = peak == 0 ? 1 : peak;
    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var hour = 0; hour < 24; hour++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: _HourBar(
                  height: (playsByHour[hour] / safeMax) * 72,
                  isPeak: peak > 0 && playsByHour[hour] == peak,
                  hour: hour,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HourBar extends StatelessWidget {
  const _HourBar({
    required this.height,
    required this.isPeak,
    required this.hour,
  });

  final double height;
  final bool isPeak;
  final int hour;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${hour.toString().padLeft(2, '0')}:00',
      child: Container(
        height: math.max(height, 2),
        decoration: BoxDecoration(
          color: isPeak ? AppColors.accent : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _HourLabel extends StatelessWidget {
  const _HourLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textDim,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _TopArtistsCard extends StatelessWidget {
  const _TopArtistsCard({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context) {
    final artists = stats.topArtists;
    final leader = artists.first.seconds == 0 ? 1 : artists.first.seconds;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.66),
        borderRadius: NexoraRadius.card,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        children: [
          for (var i = 0; i < artists.length; i++)
            _ArtistRow(
              artist: artists[i],
              rank: i + 1,
              share: (artists[i].seconds / leader).clamp(0.0, 1.0),
            ),
        ],
      ),
    );
  }
}

class _ArtistRow extends StatelessWidget {
  const _ArtistRow({
    required this.artist,
    required this.rank,
    required this.share,
  });

  final ArtistListening artist;
  final int rank;
  final double share;

  @override
  Widget build(BuildContext context) {
    final minutes = (artist.seconds / 60).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rank.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$minutes min',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 3,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accent.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTrackCard extends ConsumerWidget {
  const _TopTrackCard({required this.stats});

  final ListeningStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = stats.topTrack;
    if (track == null) return const SizedBox.shrink();

    return NexoraGradientCard(
      padding: const EdgeInsets.all(12),
      onTap: () => ref.read(playerProvider.notifier).playSongs(<Song>[track]),
      child: Row(
        children: [
          ArtworkImage(
            url: track.effectiveArtwork,
            size: 58,
            borderRadius: 8,
            showShadow: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${track.displayArtist} • ${stats.topTrackPlays} '
                  '${stats.topTrackPlays == 1 ? 'play' : 'plays'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.play_circle_filled_rounded,
            color: AppColors.accent,
            size: 34,
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
      children: [
        ShimmerLoading(
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: NexoraRadius.card,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: ShimmerLoading(
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.shimmerBase,
                      borderRadius: NexoraRadius.card,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 30),
        ShimmerLoading(
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: NexoraRadius.card,
            ),
          ),
        ),
      ],
    );
  }
}
