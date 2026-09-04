import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_reporter.dart';

final audioHandlerProvider = Provider<NexoraAudioHandler>((ref) {
  throw UnimplementedError('Initialize provider in main.dart first');
});

/// Native notification + background playback entry point.
///
/// - Android: foreground `mediaPlayback` service (see AndroidManifest),
///   ongoing notification with prev/play/next, compact actions [0,1,3].
/// - iOS: `audio` + `fetch` background modes (Info.plist) + lock-screen
///   / Control-Center integration via audio_service + audio_session.
/// - Headset / Bluetooth / interruptions route through audio_session
///   (configured in [NexoraAudioHandler._initSession]).
/// - "PiP" for a pure-audio app == background audio: playback continues
///   with screen off / app backgrounded / notification dismissed to
///   background (stop only via notification stop or queue clear).
Future<NexoraAudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => NexoraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.nexora.audio.channel.audio',
      androidNotificationChannelName: 'Nexora Audio Playback',
      androidNotificationChannelDescription:
          'Playback controls, artwork and track info on the lock screen',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
      androidNotificationClickStartsActivity: true,
      androidResumeOnClick: true,
      // 10s skip shown on lock-screen / Android Auto / headset long-press.
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
      // Downscale lock-screen art for fast notification updates.
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
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
    _initSession();
  }

  /// Audio focus / headset / Bluetooth / ducking.
  /// Must run once: music focus, duck others, resume on noisy (unplug).
  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      // Phone call / alarm interruption → pause; headphone unplug → pause.
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(_player.volume * 0.4);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              // Don't auto-resume calls — user presses play.
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) => _player.pause());
    } catch (_) {
      // audio_session unavailable (e.g. desktop/web) — playback still works.
    }
  }

  AudioPlayer get player => _player;

  // ── Network loss / reconnect auto-resume ─────────────────────────────────
  //
  // When the internet drops: playback pauses, but the queue, track index
  // and position are remembered. When the internet comes back, the queue
  // is re-loaded (fresh stream URLs / token) and the song auto-resumes
  // exactly where it stopped.
  bool _hasPendingResume = false;
  bool _resumeWasPlaying = false;
  Duration _resumePosition = Duration.zero;
  int _resumeIndex = 0;

  /// True while playback is intentionally paused due to no internet and a
  /// resume is queued for when the connection returns.
  bool get hasPendingNetworkResume => _hasPendingResume;

  void _rememberResumeIntent({required bool resumePlaying}) {
    final idx = _player.currentIndex;
    if (queue.value.isEmpty) return;
    _resumeWasPlaying = resumePlaying || _resumeWasPlaying;
    _resumeIndex = idx ?? _resumeIndex;
    _resumePosition = _player.position;
    _hasPendingResume = true;
  }

  /// Called when a remote audio stream errors out (usually no internet).
  /// Reports offline so the monitor reacts fast, and remembers the track
  /// + position so it can auto-resume when the connection returns.
  void _onPlaybackError() {
    // Only treat as a network problem when the failing item is remote —
    // local (downloaded) files failing is not an internet issue.
    final index = _player.currentIndex;
    final q = queue.value;
    if (index == null || index >= q.length) return;
    final item = q[index];
    final localPath = item.extras?['localPath'] as String?;
    final isRemote = localPath == null || localPath.isEmpty;
    if (!isRemote) return;
    ConnectivityReporter.instance.reportOffline();
    if (_player.playing ||
        _player.processingState == ProcessingState.loading ||
        _player.processingState == ProcessingState.buffering) {
      _rememberResumeIntent(resumePlaying: true);
      _player.pause();
    }
  }

  /// Internet just dropped: stop playback immediately but keep the queue,
  /// current track and position so we can resume automatically later.
  Future<void> pauseForNetworkLoss() async {
    if (_player.playing) _rememberResumeIntent(resumePlaying: true);
    await _player.pause();
  }

  /// Internet is back: auto-fetch the queue again (fresh stream URLs +
  /// token) and resume the interrupted song from where it stopped.
  Future<void> resumeAfterNetworkRestore() async {
    if (!_hasPendingResume || !_resumeWasPlaying) return;
    _hasPendingResume = false;
    final items = List<MediaItem>.of(queue.value);
    if (items.isEmpty) return;
    final idx = _resumeIndex.clamp(0, items.length - 1);
    final position = _resumePosition;
    _resumeWasPlaying = false;

    // The connection that just came back may not be fully settled for a
    // fresh audio socket yet — retry a few times before giving up.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await loadMedia(items, initialIndex: idx, playOnLoad: false);
        if (position > Duration.zero) {
          await _player.seek(position, index: idx);
        }
        await _player.play();
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    // Could not recover yet — arm again so the next online transition
    // (probe / request success) retries the resume.
    _hasPendingResume = true;
    _resumeWasPlaying = true;
    _resumeIndex = idx;
    _resumePosition = position;
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.rewind,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.fastForward,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          // Compact: prev / play-pause / next (indices into controls above).
          androidCompactActionIndices: const [0, 2, 5],
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
    },
    // A remote stream that dies mid-playback is almost always a network
    // drop. Feed the connectivity monitor so the app flips offline fast,
    // and remember the playback position for auto-resume on reconnect.
    onError: (Object e, StackTrace st) => _onPlaybackError(),
    );
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
    // OFFLINE GUARD: set the audio source FIRST. If it throws (no
    // internet + remote URL, DNS, socket), the previous playable queue
    // (downloads / cache) stays intact instead of being wiped.
    await _player.setAudioSource(source, initialIndex: initialIndex);
    queue.add(items);
    mediaItem.add(items[initialIndex.clamp(0, items.length - 1)]);
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
  Future<void> rewind() => _seekBy(const Duration(seconds: -10));

  @override
  Future<void> fastForward() => _seekBy(const Duration(seconds: 10));

  @override
  Future<void> seekForward(bool begin) =>
      _seekBy(begin ? const Duration(seconds: 10) : Duration.zero);

  @override
  Future<void> seekBackward(bool begin) =>
      _seekBy(begin ? const Duration(seconds: -10) : Duration.zero);

  Future<void> _seekBy(Duration offset) async {
    final dur = _player.duration ?? Duration.zero;
    var target = _player.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    await _player.seek(target);
  }

  @override
  Future<void> click([MediaButton? button]) async {
    // Headset single-click toggles, double-click handled by OS as skip.
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

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

  Future<void> setRepeatModeAudio(AudioServiceRepeatMode repeatMode) async {
    await setRepeatMode(repeatMode);
  }
}
