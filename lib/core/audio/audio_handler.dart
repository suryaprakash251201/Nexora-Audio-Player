import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioHandlerProvider = Provider<NexoraAudioHandler>((ref) {
  throw UnimplementedError('Initialize provider in main.dart first');
});

Future<NexoraAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => NexoraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nexora.audio.channel.audio',
      androidNotificationChannelName: 'Nexora Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}

class NexoraAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  NexoraAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  AudioPlayer get player => _player;

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          repeatMode:
              const {
                LoopMode.off: AudioServiceRepeatMode.none,
                LoopMode.one: AudioServiceRepeatMode.one,
                LoopMode.all: AudioServiceRepeatMode.all,
              }[_player.loopMode] ??
              AudioServiceRepeatMode.none,
          shuffleMode: _player.shuffleModeEnabled
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final currentQueue = queue.value;
      if (index == null || currentQueue.isEmpty) return;
      if (index >= currentQueue.length) return;
      final oldMediaItem = currentQueue[index];
      final newMediaItem = oldMediaItem.copyWith(duration: duration);
      final newQueue = List<MediaItem>.of(currentQueue);
      newQueue[index] = newMediaItem;
      queue.add(newQueue);
      mediaItem.add(newMediaItem);
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      final queueVal = queue.value;
      if (index == null || queueVal.isEmpty) return;
      if (index >= queueVal.length) return;
      mediaItem.add(queueVal[index]);
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((SequenceState? sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
      final items = sequence.map((source) => source.tag as MediaItem).toList();
      queue.add(items);
    });
  }

  Future<void> loadMedia(
    List<MediaItem> items, {
    int initialIndex = 0,
    bool playOnLoad = true,
  }) async {
    if (items.isEmpty) return;
    final audioSources = items.map((item) {
      final localPath = item.extras?['localPath'] as String?;
      final headers = (item.extras?['headers'] as Map?)?.cast<String, String>();
      if (localPath != null && localPath.isNotEmpty) {
        return AudioSource.uri(Uri.file(localPath), tag: item);
      }
      // Remote streaming with optional auth header
      return AudioSource.uri(Uri.parse(item.id), tag: item, headers: headers);
    }).toList();

    final source = ConcatenatingAudioSource(children: audioSources);
    queue.add(items);
    mediaItem.add(items[initialIndex.clamp(0, items.length - 1)]);
    await _player.setAudioSource(source, initialIndex: initialIndex);
    if (playOnLoad) await _player.play();
  }

  Future<void> addQueueItems(List<MediaItem> items) async {
    final currentQueue = queue.value;
    final newQueue = [...currentQueue, ...items];
    final sources = items.map((item) {
      final localPath = item.extras?['localPath'] as String?;
      final headers = (item.extras?['headers'] as Map?)?.cast<String, String>();
      if (localPath != null && localPath.isNotEmpty) {
        return AudioSource.uri(Uri.file(localPath), tag: item);
      }
      return AudioSource.uri(Uri.parse(item.id), tag: item, headers: headers);
    }).toList();

    final seq = _player.sequence;
    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      await concat.addAll(sources);
    } else {
      // No source yet, create one
      await loadMedia(items, playOnLoad: false);
      return;
    }
    queue.add(newQueue);
  }

  Future<void> insertNext(MediaItem item) async {
    final currentQueue = queue.value;
    final currentIndex = _player.currentIndex ?? 0;
    final insertIndex = (currentIndex + 1).clamp(0, currentQueue.length);
    final newQueue = [...currentQueue]..insert(insertIndex, item);

    final localPath = item.extras?['localPath'] as String?;
    final headers = (item.extras?['headers'] as Map?)?.cast<String, String>();
    final source = localPath != null && localPath.isNotEmpty
        ? AudioSource.uri(Uri.file(localPath), tag: item)
        : AudioSource.uri(Uri.parse(item.id), tag: item, headers: headers);

    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      if (insertIndex >= concat.length) {
        await concat.add(source);
      } else {
        await concat.insert(insertIndex, source);
      }
    }
    queue.add(newQueue);
  }

  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    final newQueue = [...queue.value]..removeAt(index);
    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      await concat.removeAt(index);
    }
    queue.add(newQueue);
  }

  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    if (oldIndex < 0 || oldIndex >= queue.value.length) return;
    if (newIndex < 0 || newIndex >= queue.value.length) return;
    final newQueue = [...queue.value];
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);
    if (_player.audioSource is ConcatenatingAudioSource) {
      final concat = _player.audioSource as ConcatenatingAudioSource;
      await concat.move(oldIndex, newIndex);
    }
    queue.add(newQueue);
  }

  Future<void> clearQueue() async {
    await _player.stop();
    try {
      if (_player.audioSource is ConcatenatingAudioSource) {
        final concat = _player.audioSource as ConcatenatingAudioSource;
        await concat.clear();
      }
    } catch (_) {}
    queue.add([]);
    mediaItem.add(null);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
    mediaItem.add(queue.value[index]);
  }

  Future<void> setShuffle(bool enable) async {
    await _player.setShuffleModeEnabled(enable);
    if (enable) await _player.shuffle();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    final loop = {
      AudioServiceRepeatMode.none: LoopMode.off,
      AudioServiceRepeatMode.one: LoopMode.one,
      AudioServiceRepeatMode.all: LoopMode.all,
      AudioServiceRepeatMode.group: LoopMode.all,
    }[mode]!;
    await _player.setLoopMode(loop);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> setRepeatModeAudio(AudioServiceRepeatMode repeatMode) async {
    await setRepeatMode(repeatMode);
  }
}
