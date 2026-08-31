# iOS

## Capabilities
- `UIBackgroundModes: audio` (and `fetch` for sync polling)
- Audio Session category `.playback` via `audio_service` / `audio_session`

## Info.plist
- `CFBundleDisplayName: Nexora`
- `UIBackgroundModes` includes `audio`
- `NSAppTransportSecurity` → `NSAllowsLocalNetworking: true` (LAN http allowed), `NSAllowsArbitraryLoads: false` (HTTPS in prod)

## Remote Controls
- Lock screen `MPNowPlayingInfoCenter` updated by `audio_service` from `MediaItem` (title, artist, album, artwork, duration)
- Remote commands: play/pause/next/prev/seek handled in `NexoraAudioHandler`
- Control Center, headset, Bluetooth, Siri.

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
