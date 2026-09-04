import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/playlists_api.dart';
import '../../../data/repositories/playlists_repository.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_rows.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';
import '../../../ui/widgets/error_view.dart';
import '../../../ui/widgets/playlist_cover.dart';
import '../../../ui/widgets/track_menu_box.dart';
import '../../../core/utils/formatters.dart';
import '../../player/providers/player_provider.dart';
import '../../../core/download/download_manager.dart';

/// Playlist detail — full audiophile redesign.
///
/// Big square mosaic cover as the hero, editorial title block, two
/// primary actions (Play / Shuffle) as full-width tonal buttons, then
/// the tracklist in a contained card so hairlines read consistently
/// across the whole list.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String playlistId;
  final Playlist? initial;
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.initial,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  Playlist? _playlist;
  List<Song> _tracks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _playlist = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(playlistsRepositoryProvider);
      final p = await repo.getPlaylist(widget.playlistId);
      // FIX #6: p.tracks is often null/empty even when the playlist has
      // songs — always fall back to the dedicated tracks endpoint.
      List<Song> tracks = p.tracks ?? const [];
      if (tracks.isEmpty) {
        try {
          tracks = await repo.getPlaylistTracks(widget.playlistId);
        } catch (_) {
          tracks = p.tracks ?? const [];
        }
      }
      setState(() {
        _playlist = p;
        _tracks = tracks;
        _loading = false;
      });
    } catch (e) {
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
    final p = _playlist!;
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: _showOptions,
                ),
              ],
            ),
            SliverToBoxAdapter(child: _hero(p)),
            SliverToBoxAdapter(child: _actions(p)),
            SliverToBoxAdapter(
              child: _CollaboratorsSection(playlistId: widget.playlistId),
            ),
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
                        _tracks.length.toString(),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_tracks.isNotEmpty)
                      Text(
                        '${formatDuration(_totalDuration() ?? Duration.zero)} total',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_tracks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: NexoraEmptyState(
                    icon: Icons.queue_music_outlined,
                    title: 'Empty playlist',
                    subtitle: 'Add songs from your library to begin.',
                  ),
                ),
              )
            else
              // #6 Card UI: each song is its own card (not a single box
              // with hairlines) so touch targets, artwork + playing state
              // all read clearly and the list never renders blank.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((c, i) {
                    final s = _tracks[i];
                    final isCurrent =
                        ref.watch(
                          playerProvider.select((s) => s.currentTrack?.id),
                        ) ==
                        s.id;
                    final playing =
                        isCurrent &&
                        ref.watch(playerProvider.select((s) => s.isPlaying));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? AppColors.selectionGradientHorizontal
                              : null,
                          color: isCurrent
                              ? null
                              : AppColors.card.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white.withValues(alpha: 0.22)
                                : AppColors.border,
                            width: 0.7,
                          ),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.28,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : (AppColors.mode == AppThemeMode.dark
                                    ? null
                                    : NexoraShadow.card(false)),
                        ),
                        child: NexoraTrackRow(
                          artworkUrl: s.coverUrl ?? s.artworkUrl,
                          title: s.title,
                          subtitle:
                              '${s.artist ?? 'Unknown'} • ${formatDuration(Duration(seconds: s.duration ?? 0))}',
                          indexLabel: (i + 1).toString().padLeft(2, '0'),
                          isCurrent: isCurrent,
                          isPlaying: playing,
                          isFavorite: s.isFavorite,
                          isDownloaded:
                              s.isDownloaded ||
                              ref.watch(downloadedIdsProvider).contains(s.id),
                          onTap: () => ref
                              .read(playerProvider.notifier)
                              .playSongs(_tracks, initialIndex: i),
                          onMoreAt: (anchor) => _showTrackOptions(s, anchor),
                        ),
                      ),
                    );
                  }, childCount: _tracks.length),
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

  Widget _hero(Playlist p) {
    final count = p.trackCount ?? _tracks.length;
    final total = _totalDuration();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Hero(
                tag: 'playlist-cover-${p.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppColors.mode == AppThemeMode.dark
                        ? null
                        : NexoraShadow.card(false),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _firstTrackArtwork(p),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            p.name,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
            ),
          ),
          if (p.description != null && p.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              p.description!,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _MetaPill(
                icon: Icons.music_note_rounded,
                label: '$count ${count == 1 ? 'track' : 'tracks'}',
              ),
              const SizedBox(width: 8),
              if (total != null)
                _MetaPill(
                  icon: Icons.schedule_rounded,
                  label: formatDuration(total),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(Playlist p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _PrimaryAction(
              icon: Icons.play_arrow_rounded,
              label: 'Play',
              onTap: _tracks.isEmpty
                  ? null
                  : () => ref
                        .read(playerProvider.notifier)
                        .playSongs(_tracks, initialIndex: 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SecondaryAction(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              onTap: _tracks.isEmpty
                  ? null
                  : () => ref
                        .read(playerProvider.notifier)
                        .playSongs([..._tracks]..shuffle(), initialIndex: 0),
            ),
          ),
        ],
      ),
    );
  }

  Duration? _totalDuration() {
    if (_tracks.isEmpty) return null;
    final seconds = _tracks.fold<int>(0, (s, t) => s + (t.duration ?? 0));
    if (seconds == 0) return null;
    return Duration(seconds: seconds);
  }

  Widget _firstTrackArtwork(Playlist p) {
    // FIX #6: hero must use loaded _tracks (p.tracks is usually empty).
    final urls = <String?>[];
    final direct = p.coverUrl;
    if (direct != null && direct.isNotEmpty) urls.add(direct);
    final source = _tracks.isNotEmpty ? _tracks : (p.tracks ?? const []);
    for (final t in source) {
      final u = t.coverUrl ?? t.artworkUrl;
      if (u != null && u.isNotEmpty) {
        urls.add(u);
        if (urls.length >= 4) break;
      }
    }
    return PlaylistCover(artworkUrls: urls, borderRadius: 0, title: p.name);
  }

  void _showTrackOptions(Song s, Rect anchor) {
    final canRemove = (s.itemRef ?? '').isNotEmpty;
    showTrackMenuBox(
      context: context,
      anchor: anchor,
      options: trackMenuOptions(
        ref: ref,
        context: context,
        song: s,
        trailing: [
          if (canRemove)
            TrackMenuOption(
              icon: Icons.delete_outline_rounded,
              label: 'Remove from playlist',
              danger: true,
              onTap: () => _removeFromPlaylist(s),
            ),
        ],
      ),
    );
  }

  Future<void> _removeFromPlaylist(Song s) async {
    try {
      await ref
          .read(playlistsRepositoryProvider)
          .removeTrack(widget.playlistId, s.itemRef!);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from playlist')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
      }
    }
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: NexoraRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textFaint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.text),
                title: Text('Rename', style: TextStyle(color: AppColors.text)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete playlist',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (cx) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: Text(
                        'Delete?',
                        style: TextStyle(color: AppColors.text),
                      ),
                      content: Text(
                        'This will delete the playlist.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(cx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(cx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    try {
                      await ref
                          .read(playlistsRepositoryProvider)
                          .deletePlaylist(widget.playlistId);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Delete failed: $e')),
                        );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// People sharing this playlist (owner / admin / editors only — the
/// section hides itself on 403 so viewers never see a dead UI).
class _CollaboratorsSection extends ConsumerStatefulWidget {
  final String playlistId;
  const _CollaboratorsSection({required this.playlistId});

  @override
  ConsumerState<_CollaboratorsSection> createState() =>
      _CollaboratorsSectionState();
}

class _CollaboratorsSectionState extends ConsumerState<_CollaboratorsSection> {
  late Future<List<PlaylistCollaborator>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PlaylistCollaborator>> _load() =>
      ref.read(playlistsApiProvider).getCollaborators(widget.playlistId);

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaylistCollaborator>>(
      future: _future,
      builder: (c, snap) {
        // Not permitted / failed → hide (viewers, offline, gone).
        if (snap.hasError || !snap.hasData) {
          return const SizedBox.shrink();
        }
        final people = snap.data!;
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PEOPLE',
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
                        people.length.toString(),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddSheet(),
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            size: 15,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (people.isNotEmpty) const SizedBox(height: 8),
                for (final person in people)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.13),
                          ),
                          child: Text(
                            person.username.isNotEmpty
                                ? person.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.username.isNotEmpty
                                    ? person.username
                                    : person.userId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                person.role,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: AppColors.textDim,
                          ),
                          tooltip: 'Remove',
                          onPressed: () => _remove(person),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _remove(PlaylistCollaborator person) async {
    try {
      await ref
          .read(playlistsApiProvider)
          .manageCollaborator(
            widget.playlistId,
            action: 'remove',
            userId: person.userId,
          );
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Remove failed: $e')));
      }
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (c) => _AddCollaboratorSheet(
        playlistId: widget.playlistId,
        onAdded: _refresh,
      ),
    );
  }
}

class _AddCollaboratorSheet extends ConsumerStatefulWidget {
  final String playlistId;
  final VoidCallback onAdded;
  const _AddCollaboratorSheet({
    required this.playlistId,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddCollaboratorSheet> createState() =>
      _AddCollaboratorSheetState();
}

class _AddCollaboratorSheetState extends ConsumerState<_AddCollaboratorSheet> {
  final _query = TextEditingController();
  String _role = 'editor';
  String _search = '';
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: NexoraRadius.sheetTop,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.7)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDim.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Add people',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _query,
                        autofocus: true,
                        onChanged: (v) => setState(() => _search = v.trim()),
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search username',
                          isDense: true,
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: Text(_role == 'editor' ? 'Editor' : 'Viewer'),
                      selected: true,
                      selectedColor: AppColors.accent,
                      labelStyle: const TextStyle(color: Colors.white),
                      onSelected: (_) => setState(
                        () => _role = _role == 'editor' ? 'viewer' : 'editor',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: _search.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          'Type to search users on this server.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : FutureBuilder<List<PlaylistUser>>(
                        future: ref
                            .read(playlistsApiProvider)
                            .searchUsers(_search),
                        builder: (c, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final users = snap.data ?? const [];
                          if (users.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: Text(
                                'No users match “$_search”.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (c, i) {
                              final user = users[i];
                              return ListTile(
                                leading: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surfaceRaised,
                                  ),
                                  child: Text(
                                    user.username.isNotEmpty
                                        ? user.username[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.username,
                                  style: TextStyle(color: AppColors.text),
                                ),
                                trailing: _busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.add_rounded,
                                        color: AppColors.accent,
                                      ),
                                onTap: _busy ? null : () => _add(user),
                              );
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _add(PlaylistUser user) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(playlistsApiProvider)
          .manageCollaborator(
            widget.playlistId,
            action: 'add',
            userId: user.id,
            role: _role,
          );
      widget.onAdded();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Add failed: $e')));
    }
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
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
    return NexoraPressable(
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
    return NexoraPressable(
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
