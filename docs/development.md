# Development

## Prerequisites
- Flutter 3.24+ (stable)
- Dart 3.5+
- Android SDK / Xcode for platform builds

## Setup
```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter run          # picks connected device
flutter run -d chrome # web (audio limited)
```

## Environment
Server URL priority: SecureStorage → --dart-define → fallback
```bash
flutter run --dart-define=NEXORA_API_BASE_URL=https://music.example.com/api/v1
flutter run --dart-define=NEXORA_API_BASE_URL=http://192.168.1.100:3000/api/v1
```

LAN dev: ensure phone & server same network, firewall allows PORT, use http.

## Project Structure
See `architecture.md`.

## Key Commands
```bash
# Format
dart format .

# Analyze (no errors)
flutter analyze

# Tests
flutter test
flutter test --coverage

# Build Android (unsigned)
flutter build apk --release

# Build iOS (unsigned, simulator)
flutter build ios --release --no-codesign
```

## Testing
- Unit: DTO parsing, repos (FakeApiClient), queue, sync
- Widget: player, library
- Integration: see `test/` coverage

Mocks: inject `FakeApiClient` via Riverpod overrides; never mock in production code.

## Logging
Debug logs: `[AUTH]`, `[API]`, `[PLAYER]`, `[QUEUE]`, `[SYNC]`, `[CACHE]`
Enable via `kDebugMode`; no token logging.

## Adding a New Endpoint
1. Add path to `ApiConstants`
2. Create method in `data/api/<resource>_api.dart`
3. Add DTO if needed
4. Expose via `domain/entities` + repository
5. Update `api-contract.md`

## CI
- `flutter_ci.yml` — analyze, format, test on push/PR
- `build_apps.yml` — release builds (Android unsigned, iOS simulator)

## Troubleshooting
- `audio_service` init fails on web → fallback handler
- No server connection → check `Test Connection` in Server Setup, verify firewall/cors
- Re-run `flutter pub get` after changing pubspec
