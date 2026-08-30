# Nexora Audiophile — Mobile Client

Standalone Android + iOS audiophile player for the self-hosted Nexora file workspace (`suryaprakash251201/nexora`). This repo is **client-only**; the backend runs unchanged at your Nexora server URL.

## Status

Milestone 1 (foundation + typecheck) is complete. See `docs/ROADMAP.md`.

## Quick start

```bash
npm install --legacy-peer-deps   # patch-package runs automatically
npm run typecheck                # must be clean
npm start                        # expo dev client (requires a dev build)
npm run android                  # builds + installs the dev client on a connected device/emulator
npm run ios                      # builds + installs on a connected iPhone/simulator (macOS)
```

The first native build: `npm run prebuild` generates `android/` + `ios/`; subsequent builds reuse them.

## Connecting to your Nexora server

Open the app, enter your server URL (e.g. `https://nexora.example.com`), then log in with your Nexora username + password (+ TOTP code if enabled). The token is stored in `expo-secure-store` with an AsyncStorage fallback and an automatic 401 sign-out, mirroring the upstream mobile app.

## What works in M1

- Install succeeds (`patch-package` applies the TrackPlayer Kotlin patch).
- `npm run typecheck` is clean.
- The navigation shell (Expo Router tabs) boots; the player, theme, library,
  DSP, downloads and sync contexts are stubbed so later milestones can land
  incrementally without touching `app/_layout.tsx`.

## Configuration

`app.json` declares the audio stack:

- Android `READ_MEDIA_AUDIO`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS` and `MODIFY_AUDIO_SETTINGS` for lock-screen + BT.
- iOS `UIBackgroundModes: ["audio"]` for background playback and Control Center.

## Design

`docs/ARCHITECTURE.md` is the contract; `src/` contains the first-pass audio abstractions (`src/audio/`, `src/library/types.ts`, `src/storage/db.ts`). The UI palette is in `src/ui/theme.ts`.