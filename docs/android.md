# Android

## Permissions (AndroidManifest.xml)
- `INTERNET`, `ACCESS_NETWORK_STATE`
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (Android 14+)
- `POST_NOTIFICATIONS` (Android 13+ request at runtime)
- `WAKE_LOCK`, `MODIFY_AUDIO_SETTINGS`

## Foreground Service
`com.ryanheise.audioservice.AudioService` with `foregroundServiceType="mediaPlayback"` handles notification and lock screen.

Notification channel: `com.nexora.audio.channel.audio` (“Nexora Audio Playback”, ongoing).

## Audio Focus & Media Buttons
- `audio_session` configures focus; `audio_service` receives `MEDIA_BUTTON` broadcasts.
- Play/pause/next/prev, seek, handled in `NexoraAudioHandler`.

## Lifecycle
- `singleTop` launchMode, audio continues when screen off / background / other app.
- `androidStopForegroundOnPause: true` — stops foreground when paused.

## Build
```bash
flutter build apk --release
flutter build appbundle --release
```

CI uses `subosito/flutter-action` + `flutter build apk`.

## Testing on Device
- Enable developer options, USB debugging
- `flutter run` or `adb install build/app/outputs/flutter-apk/app-release.apk`
- For LAN: allow cleartext to your server via network_security_config if http (debug).

## Notifications (13+)
Request `POST_NOTIFICATIONS` at first play; fallback gracefully if denied (playback still works, no notification).

## Known Issues
- Some OEMs kill foreground services — advise user to disable battery optimization for Nexora.
