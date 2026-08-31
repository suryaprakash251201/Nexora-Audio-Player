import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/audio/audio_handler.dart';
import '../../../core/audio/queue_manager.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../domain/entities/song.dart';

class PlaybackStateData {
  final MediaItem? currentTrack;
  final List<MediaItem> queue;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final ProcessingState processingState;
  final bool shuffleEnabled;
  final LoopMode repeatMode;
  final double volume;

  const PlaybackStateData({
    this.currentTrack,
    this.queue = const [],
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.processingState = ProcessingState.idle,
    this.shuffleEnabled = false,
    this.repeatMode = LoopMode.off,
    this.volume = 1.0,
  });

  PlaybackStateData copyWith({
    MediaItem? currentTrack,
    List<MediaItem>? queue,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    ProcessingState? processingState,
    bool? shuffleEnabled,
    LoopMode? repeatMode,
    double? volume,
  }) => PlaybackStateData(
    currentTrack: currentTrack ?? this.currentTrack,
    queue: queue ?? this.queue,
    isPlaying: isPlaying ?? this.isPlaying,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    bufferedPosition: bufferedPosition ?? this.bufferedPosition,
    processingState: processingState ?? this.processingState,
    shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
    repeatMode: repeatMode ?? this.repeatMode,
    volume: volume ?? this.volume,
  );
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlaybackStateData>(
  (ref) {
    final handler = ref.watch(audioHandlerProvider);
    final queueManager = ref.watch(queueManagerProvider);
    final storage = ref.watch(secureStorageProvider);
    final history = ref.watch(historyRepositoryProvider);
    return PlayerNotifier(handler, queueManager, storage, history);
  },
);

class PlayerNotifier extends StateNotifier<PlaybackStateData> {
  final NexoraAudioHandler _handler;
  final QueueManager _queueManager;
  final SecureStorageService _storage;
  final HistoryRepository _history;
  StreamSubscription? _posSub;
  StreamSubscription? _playbackSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _mediaItemSub;
  Timer? _historyTimer;

  PlayerNotifier(
    this._handler,
    this._queueManager,
    this._storage,
    this._history,
  ) : super(const PlaybackStateData()) {
    _init();
  }

  void _init() {
    // Position stream
    _posSub = _handler.player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    _handler.player.durationStream.listen((d) {
      if (d != null) state = state.copyWith(duration: d);
    });
    _handler.player.bufferedPositionStream.listen((b) {
      state = state.copyWith(bufferedPosition: b);
    });
    _handler.player.playerStateStream.listen((ps) {
      state = state.copyWith(
        isPlaying: ps.playing,
        processingState: ps.processingState,
      );
      if (ps.processingState == ProcessingState.completed) {
        // Auto record completion
        _recordHistory(completed: true);
      }
      if (ps.playing) {
        _historyTimer?.cancel();
        _historyTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _recordHistory(),
        );
      } else {
        _historyTimer?.cancel();
      }
    });
    _handler.player.shuffleModeEnabledStream.listen((e) {
      state = state.copyWith(shuffleEnabled: e);
    });
    _handler.player.loopModeStream.listen((m) {
      state = state.copyWith(repeatMode: m);
    });

    _mediaItemSub = _handler.mediaItem.listen((item) {
      state = state.copyWith(
        currentTrack: item,
        duration: item?.duration ?? state.duration,
      );
      if (item != null) {
        AppLogger.player('Now playing: ${item.title}');
        _recordHistory();
      }
    });

    _queueSub = _handler.queue.listen((q) {
      state = state.copyWith(queue: q);
      // Persist queue
      final idx = _handler.player.currentIndex ?? 0;
      _queueManager.persistQueue(q, idx);
    });

    // Restore queue if needed
    _restoreQueue();
  }

  Future<void> _restoreQueue() async {
    try {
      final (items, idx) = await _queueManager.restoreQueue();
      if (items.isNotEmpty) {
        await _handler.loadMedia(items, initialIndex: idx, playOnLoad: false);
        state = state.copyWith(
          queue: items,
          currentTrack: items[idx.clamp(0, items.length - 1)],
        );
      }
    } catch (_) {}
  }

  void _recordHistory({bool completed = false}) {
    final item = state.currentTrack;
    if (item == null) return;
    final songId = (item.extras?['songId'] as String?) ?? item.id;
    if (songId.isEmpty) return;
    _history.recordPlay(
      songId,
      duration: state.duration.inSeconds,
      completed: completed,
    );
  }

  // Public actions
  Future<void> playSongs(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;
    final baseUrl = await _storage.getServerUrl();
    final token = await _storage.getToken();
    final items = songs
        .map(
          (s) =>
              _queueManager.songToMediaItem(s, baseUrl: baseUrl, token: token),
        )
        .toList();
    await _handler.loadMedia(items, initialIndex: initialIndex);
  }

  Future<void> playNext(Song song) async {
    final baseUrl = await _storage.getServerUrl();
    final token = await _storage.getToken();
    final item = _queueManager.songToMediaItem(
      song,
      baseUrl: baseUrl,
      token: token,
    );
    await _handler.insertNext(item);
  }

  Future<void> addToQueue(Song song) async {
    final baseUrl = await _storage.getServerUrl();
    final token = await _storage.getToken();
    final item = _queueManager.songToMediaItem(
      song,
      baseUrl: baseUrl,
      token: token,
    );
    await _handler.addQueueItems([item]);
  }

  Future<void> removeAt(int index) => _handler.removeQueueItemAt(index);
  Future<void> move(int oldIndex, int newIndex) =>
      _handler.moveQueueItem(oldIndex, newIndex);
  Future<void> clearQueue() async {
    await _handler.clearQueue();
    await _queueManager.clearPersistedQueue();
    state = const PlaybackStateData();
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> togglePlay() => state.isPlaying ? pause() : play();
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();
  Future<void> seek(Duration pos) => _handler.seek(pos);
  Future<void> seekToIndex(int index) => _handler.skipToQueueItem(index);
  Future<void> toggleShuffle() => _handler.setShuffle(!state.shuffleEnabled);
  Future<void> cycleRepeat() async {
    final nextMode =
        {
          LoopMode.off: LoopMode.all,
          LoopMode.all: LoopMode.one,
          LoopMode.one: LoopMode.off,
        }[state.repeatMode] ??
        LoopMode.off;
    await _handler.player.setLoopMode(nextMode);
  }

  Future<void> setVolume(double v) async {
    await _handler.player.setVolume(v);
    state = state.copyWith(volume: v);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _playbackSub?.cancel();
    _queueSub?.cancel();
    _mediaItemSub?.cancel();
    _historyTimer?.cancel();
    super.dispose();
  }
}

// Convenience providers
final currentTrackProvider = Provider<MediaItem?>(
  (ref) => ref.watch(playerProvider).currentTrack,
);
final isPlayingProvider = Provider<bool>(
  (ref) => ref.watch(playerProvider).isPlaying,
);
final queueProvider = Provider<List<MediaItem>>(
  (ref) => ref.watch(playerProvider).queue,
);
