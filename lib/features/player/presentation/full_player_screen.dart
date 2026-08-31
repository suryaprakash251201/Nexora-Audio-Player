import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import '../../../ui/theme.dart';
import '../../../core/utils/formatters.dart';
import '../providers/player_provider.dart';
import 'cassette_player.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});
  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> with SingleTickerProviderStateMixin {
  bool _showCassette = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final track = state.currentTrack;

    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(context))),
        body: const Center(child: Text('Nothing playing', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final isPlaying = state.isPlaying;
    final pos = state.position;
    final dur = state.duration.inMilliseconds == 0 ? (track.duration ?? Duration.zero) : state.duration;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1A2E), AppColors.background])),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white), onPressed: () => Navigator.pop(context)),
                title: const Text('Now Playing', style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.2)),
                centerTitle: true,
                actions: [IconButton(icon: Icon(_showCassette ? Icons.album : Icons.audiotrack, color: Colors.white), onPressed: () => setState(() => _showCassette = !_showCassette))],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _showCassette
                          ? CassettePlayer(isPlaying: isPlaying, artworkUrl: track.artUri?.toString())
                          : Expanded(
                              child: Hero(
                                tag: 'artwork_${track.id}',
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 16))]),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: track.artUri != null
                                        ? Image.network(track.artUri.toString(), fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => _artPlaceholder())
                                        : _artPlaceholder(),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 32),
                      Align(alignment: Alignment.centerLeft, child: Text(track.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 4),
                      Align(alignment: Alignment.centerLeft, child: Text(track.artist ?? 'Unknown Artist', style: const TextStyle(color: AppColors.primary, fontSize: 16))),
                      if (track.album != null) Align(alignment: Alignment.centerLeft, child: Text(track.album!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                      const SizedBox(height: 8),
                      // Quality badges
                      Row(children: [
                        if (track.extras?['codec'] != null) _badge((track.extras!['codec'] as String).toUpperCase()),
                        if (track.extras?['lossless'] == true) _badge('Lossless'),
                        if (track.extras?['sampleRate'] != null && (track.extras!['sampleRate'] as int) >= 48000) _badge('Hi-Res'),
                        if (track.extras?['bitrate'] != null) _badge('${track.extras!['bitrate']} kbps'),
                      ]),
                      const SizedBox(height: 24),
                      SliderTheme(
                        data: SliderThemeData(trackHeight: 4, activeTrackColor: AppColors.secondary, inactiveTrackColor: AppColors.surfaceRaised, thumbColor: Colors.white, overlayColor: AppColors.secondary.withOpacity(0.2)),
                        child: Slider(value: dur.inMilliseconds == 0 ? 0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0), onChanged: (v) => notifier.seek(Duration(milliseconds: (v * dur.inMilliseconds).round()))),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(formatDuration(pos), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), Text(formatDuration(dur), style: const TextStyle(color: AppColors.textMuted, fontSize: 12))]),
                      ),
                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                        IconButton(icon: Icon(Icons.shuffle, color: state.shuffleEnabled ? AppColors.primary : Colors.white), onPressed: () => notifier.toggleShuffle()),
                        IconButton(icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white), onPressed: () => notifier.previous()),
                        Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: IconButton(icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 36, color: Colors.white), onPressed: () => notifier.togglePlay())),
                        IconButton(icon: const Icon(Icons.skip_next, size: 36, color: Colors.white), onPressed: () => notifier.next()),
                        IconButton(icon: Icon(_repeatIcon(state.repeatMode), color: state.repeatMode != LoopMode.off ? AppColors.primary : Colors.white), onPressed: () => notifier.cycleRepeat()),
                      ]),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        IconButton(icon: const Icon(Icons.queue_music, color: AppColors.textMuted), onPressed: () => _showQueue(context)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.favorite_border, color: AppColors.textMuted), onPressed: () {}),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.more_horiz, color: AppColors.textMuted), onPressed: () {}),
                      ]),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artPlaceholder() => Container(color: AppColors.surfaceRaised, child: const Center(child: Icon(Icons.music_note, size: 100, color: AppColors.textMuted)));

  Widget _badge(String text) => Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withOpacity(0.3))), child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)));

  IconData _repeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.one: return Icons.repeat_one;
      case LoopMode.all: return Icons.repeat;
      case LoopMode.off:
      default: return Icons.repeat;
    }
  }

  void _showQueue(BuildContext context) {
    final state = ref.read(playerProvider);
    showModalBottomSheet(context: context, backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) {
      return SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Text('Queue', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Spacer(), TextButton(onPressed: () => ref.read(playerProvider.notifier).clearQueue(), child: const Text('Clear'))])),
        Expanded(child: ReorderableListView.builder(
          itemCount: state.queue.length,
          onReorder: (o, n) => ref.read(playerProvider.notifier).move(o, n > o ? n - 1 : n),
          itemBuilder: (cx, i) {
            final item = state.queue[i];
            final isCurrent = state.currentTrack?.id == item.id;
            return ListTile(key: ValueKey(item.id + '_$i'), leading: isCurrent ? const Icon(Icons.equalizer, color: AppColors.primary) : Text('${i + 1}', style: const TextStyle(color: AppColors.textMuted)), title: Text(item.title, style: TextStyle(color: isCurrent ? AppColors.primary : Colors.white, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)), subtitle: Text(item.artist ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), trailing: IconButton(icon: const Icon(Icons.close, size: 18, color: AppColors.textDim), onPressed: () => ref.read(playerProvider.notifier).removeAt(i)), onTap: () => ref.read(playerProvider.notifier).seekToIndex(i));
          },
        )),
      ]));
    });
  }
}


