# Sideloading (AltStore / Sideloadly)

Nexora Audiophile ships an **unsigned IPA** for iOS — no App Store, no paid Apple Developer account required.

## iOS (AltStore)

1. Install [AltStore](https://altstore.io/) on your iPhone + AltServer on macOS/Windows.
2. Download the latest `Nexora-Audiophile-*.ipa` from GitHub Releases (pushed on `v*` tags via `mobile-build.yml`).
3. Open AltStore → My Apps → + → select the IPA → sign with your free Apple ID.
4. The app appears on your home screen. Re-sign every 7 days (AltStore does it automatically when your phone is on the same Wi-Fi as AltServer).

Alternative: [Sideloadly](https://sideloadly.io/) works the same way.

## iOS (Simulator)

The `ios-simulator` artifact from CI is a `.app` you can drag onto a Simulator or install with:

```
xcrun simctl install booted NexoraAudiophile.app
```

## Android

Install `app-release.apk` from Releases. Enable "Install unknown apps" for your browser/file manager when prompted. The APK is a standard `assembleRelease` (debug keystore in CI; replace with your own keystore for Play Store).

## Notes

- Bundle IDs: `dev.suryaprakash.nexora.audio` (new audiophile app; the upstream file-manager app is `dev.suryaprakash.nexora`).
- Permissions are declared in `app.json`: audio background, media-library read, notifications, foreground service.
- For local HTTP servers (e.g. `http://192.168.1.50:8080`), `usesCleartextTraffic` and `NSAllowsArbitraryLoads` are enabled.
