# iOS

## Capabilities
- `UIBackgroundModes: audio` (and `fetch` for sync polling)
- Audio Session category `.playback` via `audio_service` / `audio_session`

## Info.plist
- `CFBundleDisplayName: Nexora`
- `UIBackgroundModes` includes `audio`
- `NSAppTransportSecurity` → `NSAllowsLocalNetworking: true` (LAN http allowed), `NSAllowsArbitraryLoads: false` (HTTPS in prod)

## Remote Controls (lock-screen card + Control Center)
- Lock-screen / Control Center / StandBy card is `MPNowPlayingInfoCenter`,
  fed automatically by `audio_service` from `MediaItem` (title, artist,
  album, artwork, duration) + `playbackState` (playing, position, speed).
- Artwork: `MediaItem.artUri` thumbnails carry `?token=` auth, so the
  system can download them without app headers (512px downscale).
- Remote commands handled in `NexoraAudioHandler`: play, pause, stop,
  seek (lock-screen scrubber), skip next/previous/queue-item, ±10s
  rewind/fast-forward, headset click-to-toggle.
- Control Center, headset, Bluetooth, Siri.

## Session ownership (do not break this)
- `just_audio` owns the AVPlayer graph; `audio_service` owns the shared
  `AVAudioSession` (playback category) that powers the lock-screen card.
- App/native code must NEVER call `setCategory`/`setActive` outside those
  plugins. A past `IOSAudioEqualizerBridge` build did exactly that on
  every EQ apply and stalled lock-screen updates — it is now a pure,
  side-effect-free validator (real per-band DSP needs an
  `MTAudioProcessingTap` inside just_audio's pipeline, which an app-side
  engine cannot inject). EQ curves stay stored locally; iOS honestly
  reports them unavailable instead of faking it.

## Interruptions & Route Changes
- `audio_session` handles interruption (call, Siri) → pause/resume
- Route change (headphones unplugged, Bluetooth) → pause if needed via `just_audio` + `audio_session`

## Build
```bash
flutter build ios --release --no-codesign   # simulator/unsigned
open ios/Runner.xcworkspace                  # for signing & archive
```

CI: `flutter build ios --release --no-codesign` with workspace detection.

## Testing
- Simulator: audio_service limited; test on real device for background/lock screen.
- Real device: ensure signing, enable Background Modes in Xcode → Signing & Capabilities.
- LAN http: `NSAllowsLocalNetworking` permits local http; production uses https.

## App Store
- Explain background audio usage
- Request media permissions if needed
- Provide privacy policy for LAN access

## Known Issues
- Simulator may not show notification controls; use device.
- Background fetch interval managed by iOS.
