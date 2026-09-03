# Playback

## Engine
- `just_audio` — HTTP streaming + local file (`AudioSource.uri`)
- `audio_service` — system integration (notification, lock screen, headset, Bluetooth)

## Architecture
```
NexoraAudioHandler (BaseAudioHandler)
 ├─ AudioPlayer (just_audio)
 ├─ queue (List<MediaItem>)
 ├─ mediaItem (current)
 └─ playbackState (controls, processingState, position)

QueueManager — persist/restore queue to sqflite `queue_state`, map Song → MediaItem (adds auth header)

PlayerNotifier (Riverpod) — single source of truth
 ├─ streams: position, buffered, playerState, queue, mediaItem
 ├─ persists queue via QueueManager
 ├─ records history (debounced 10s, completion)
 └─ exposes: playSongs(), playNext(), addToQueue(), seek(), toggle, etc.

UI — MiniPlayer + FullPlayer (StreamProvider via playerProvider)
```

## Streaming
```
Song.streamUrl (relative or absolute)
  → QueueManager.songToMediaItem → AudioSource.uri(Uri.parse(fullUrl), headers: {Authorization})
  → just_audio handles Range, buffering, seek
  → Offline: AudioSource.uri(Uri.file(localPath))
```

## Features
- Play now (replace queue), Play next (insert after current), Add to queue (append)
- Remove, reorder (drag), clear, shuffle (`setShuffleModeEnabled`), repeat (`LoopMode.off/all/one`)
- Resume position not yet persisted per-track (future: save position to prefs)
- Volume control via `player.setVolume`

## State Exposed
`currentTrack`, `queue`, `isPlaying`, `position`, `duration`, `bufferedPosition`, `processingState`, `shuffleEnabled`, `repeatMode`, `volume`

## Background (native notification + lock-screen + headset)
- Android: `AudioService` foreground service `mediaPlayback` (manifest) + channel `com.nexora.audio.channel.audio` with description, ongoing notification, compact actions prev/play/next, 512px art, ±10s FF/RW, click-to-resume, `BLUETOOTH_CONNECT` for headsets/cars
- iOS: `UIBackgroundModes: audio,fetch` (Info.plist), `AudioSessionConfiguration.music()`, lock-screen + Control Center + AirPods via audio_service
- Interruptions: call/alarm → pause, duck → 0.4× volume + restore, unplug (`becomingNoisy`) → pause; headset click toggles
- "PiP for audio" == background audio: screen-off / backgrounded / notification-minimized keeps playing; stop only via notification stop or queue clear
- Code: `initAudioService()` config + `NexoraAudioHandler._initSession()` + `rewind/fastForward/seekForward/seekBackward/click` overrides

## Error Handling
- Load failure → show Snackbar, skip to next if possible
- Network stall → buffering state, retry logic in just_audio
- Duration unreported → fallback to MediaItem duration

## Quality Metadata
- Display only when available: `codec`, `bitrate`, `sampleRate`, `lossless`, `fileSize`
- Badge logic in `Song.qualityBadge` — never fake “Hi-Res”
