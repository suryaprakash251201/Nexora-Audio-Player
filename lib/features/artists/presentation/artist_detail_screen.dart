import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/artists_api.dart';
import '../../../domain/entities/artist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';

/// Artist detail — audiophile redesign.
///
/// Circular avatar on the left, editorial title block with "ARTIST"
/// kicker, album/track count metadata, two full-width tonal action
/// buttons, and tracks inside a contained card with hairlines.
class ArtistDetailScreen extends ConsumerStatefulWidget {
  final String artistId;
  final Artist? initial;
  const ArtistDetailScreen({super.key, required this.artistId, this.initial});

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  Artist? _artist;
  List<Song> _songs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _artist = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(artistsApiProvider);
      final artist = _artist ?? await api.getArtist(widget.artistId);
      final songs = await api.getArtistSongs(widget.artistId);
      if (!mounted) return;
      setState(() {
        _artist = artist;
        _songs = songs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.text),
        ),
        body: const LoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.text),
        ),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }
    final a = _artist!;
    final isDark = AppColors.mode == AppThemeMode.dark;
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              iconTheme: IconThemeData(color: AppColors.text),
              flexibleSpace: const NexoraSliverAppBarBackground(),
            ),
            SliverToBoxAdapter(child: _hero(a, isDark)),
            SliverToBoxAdapter(child: _actions()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'TRACKS',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _songs.length.toString(),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_songs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: NexoraEmptyState(
                    icon: Icons.person_outline_rounded,
                    title: 'No tracks',
                    subtitle: 'We could not find tracks for this artist.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: NexoraRadius.card,
                      border: Border.all(color: AppColors.border, width: 0.7),
                      boxShadow: isDark ? null : NexoraShadow.card(false),
                    ),
                    child: ClipRRect(
                      borderRadius: NexoraRadius.card,
                      child: Column(
                        children: [
                          for (var i = 0; i < _songs.length; i++) ...[
                            Builder(
                              builder: (c) {
                                final s = _songs[i];
                                final isCurrent =
                                    ref
                                        .watch(playerProvider)
                                        .currentTrack
                                        ?.id ==
                                    s.id;
                                return NexoraTrackRow(
                                  artworkUrl: s.coverUrl,
                                  title: s.title,
                                  subtitle: s.album ?? 'Single',
                                  duration: formatDuration(
                                    Duration(seconds: s.duration ?? 0),
                                  ),
                                  indexLabel: (i + 1).toString().padLeft(
                                    2,
                                    '0',
                                  ),
                                  isCurrent: isCurrent,
                                  isPlaying:
                                      isCurrent &&
                                      ref.watch(playerProvider).isPlaying,
                                  isFavorite: s.isFavorite,
                                  isDownloaded: s.isDownloaded,
                                  onTap: () => ref
                                      .read(playerProvider.notifier)
                                      .playSongs(_songs, initialIndex: i),
                                  onMore: () {},
                                );
                              },
                            ),
                            if (i != _songs.length - 1)
                              const NexoraDivider(indent: 64, endIndent: 0),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: NexoraSpacing.dockBottomReserve),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(Artist a, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : NexoraShadow.card(false),
            ),
            child: ClipOval(
              child: a.artworkUrl != null
                  ? Image.network(
                      a.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceRaised,
                        child: Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: AppColors.textDim,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceRaised,
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.textDim,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: NexoraSpacing.s20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 11,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ARTIST',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  a.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((a.albumCount ?? 0) > 0)
                      NexoraTag(
                        label: '${a.albumCount} albums',
                        icon: Icons.album_rounded,
                      ),
                    NexoraTag(
                      label: '${a.trackCount ?? _songs.length} tracks',
                      icon: Icons.music_note_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _PrimaryAction(
              icon: Icons.play_arrow_rounded,
              label: 'Play All',
              onTap: _songs.isEmpty
                  ? null
                  : () => ref
                        .read(playerProvider.notifier)
                        .playSongs(_songs, initialIndex: 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SecondaryAction(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              onTap: _songs.isEmpty
                  ? null
                  : () => ref
                        .read(playerProvider.notifier)
                        .playSongs([..._songs]..shuffle(), initialIndex: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.7),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.text, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
