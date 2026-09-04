import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/playlists_repository.dart';
import '../../../domain/entities/playlist.dart';
import '../../../domain/entities/song.dart';
import '../../../ui/nexora/nexora_icons.dart';
import '../../../ui/nexora/nexora_primitives.dart';
import '../../../ui/nexora/nexora_snack.dart';
import '../../../ui/nexora/nexora_tokens.dart';
import '../../../ui/theme.dart';

/// The user's playlists, cached while the sheet is open.
final _playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  return ref.watch(playlistsRepositoryProvider).getPlaylists();
});

/// Slides up the user's playlists so a track can be filed away without
/// leaving whatever screen is currently on top.
///
/// Returns a future that completes when the sheet is dismissed.
Future<void> showAddToPlaylistSheet(
  BuildContext context, {
  required Song song,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AddToPlaylistSheet(song: song),
  );
}

class _AddToPlaylistSheet extends ConsumerStatefulWidget {
  const _AddToPlaylistSheet({required this.song});

  final Song song;

  @override
  ConsumerState<_AddToPlaylistSheet> createState() =>
      _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends ConsumerState<_AddToPlaylistSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _add(Playlist playlist) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(playlistsRepositoryProvider)
          .addTrack(playlist.id, widget.song.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNexoraSnack(
        context,
        'Added to “${playlist.name}”',
        severity: NexoraSnackSeverity.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _createAndAdd() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(playlistsRepositoryProvider);
      final created = await repo.createPlaylist(name);
      await repo.addTrack(created.id, widget.song.id);
      ref.invalidate(_playlistsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showNexoraSnack(
        context,
        'Created “$name” and added the track',
        severity: NexoraSnackSeverity.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncPlaylists = ref.watch(_playlistsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: NexoraRadius.sheetTop,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 16),
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
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    NexoraGlyph(
                      kind: NexoraGlyphKind.playlist,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to playlist',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_error case final String message)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(
                    message,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 10),
              asyncPlaylists.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: Text(
                        'No playlists yet — create your first one below.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final playlist in playlists)
                        _PlaylistTile(
                          name: playlist.name,
                          disabled: _busy,
                          onTap: () => _add(playlist),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Could not load playlists.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(_playlistsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const NexoraDivider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _createAndAdd(),
                        style: TextStyle(color: AppColors.text, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'New playlist name',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _busy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : NexoraTextButton(
                            label: 'Create',
                            primary: true,
                            onTap: _createAndAdd,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.name,
    required this.onTap,
    required this.disabled,
  });

  final String name;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return NexoraPressable(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            NexoraGlyph(
              kind: NexoraGlyphKind.playlist,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.add_rounded, size: 18, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}
