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

class NexoraAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  NexoraAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
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
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  // Load a playlist or track
  Future<void> loadMedia(List<MediaItem> items, {int initialIndex = 0}) async {
    final audioSource = ConcatenatingAudioSource(
      children: items.map((item) {
        // Here we'd map standard network URLs or local file paths
        final source = item.extras?['localPath'] != null
            ? AudioSource.uri(Uri.file(item.extras!['localPath']))
            : AudioSource.uri(Uri.parse(item.id));
        return source;
      }).toList(),
    );
    
    queue.add(items);
    await _player.setAudioSource(audioSource, initialIndex: initialIndex);
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
}
