# Nexora Flutter — Architecture

## Overview
Nexora is a self-hosted audiophile music player. The Flutter client is a **first-class client of the Nexora server**; the server is the source of truth for cloud data. The app works offline via a local cache + sync queue.

```
UI (Widgets) 
  ↓ Riverpod providers
Repositories (domain)
  ↓
Data Sources: Remote API (Dio) + Local DB (sqflite) + Secure Storage
  ↓
Nexora Server / Local SQLite
```

Playback is independent from HTTP: `audio_service` + `just_audio` own the audio engine.

---

## Tech Stack
- **Flutter** + **Riverpod** (state, DI)
- **GoRouter** (navigation)
- **Dio** (HTTP)
- **flutter_secure_storage** (tokens)
- **sqflite** (offline cache)
- **just_audio** (streaming)
- **audio_service** (background, lock screen, notifications)
- **cached_network_image** (artwork)
- `connectivity_plus` / `internet_connection_checker` (offline awareness)

---

## Project Structure

```
lib/
├── app/                          # App bootstrap
│   └── app.dart
├── core/
│   ├── config/app_config.dart    # Env, baseUrl logic
│   ├── constants/                # API paths, keys
│   ├── errors/                   # Failures, exceptions
│   ├── network/                  # ApiClient, interceptors, connectivity
│   ├── storage/                  # Secure + prefs
│   ├── database/                 # sqflite service
│   ├── audio/                    # handler, player service, queue
│   ├── download/                 # DownloadManager
│   ├── sync/                     # SyncManager + queue
│   ├── utils/                    # logger, debouncer, formatters
│   └── logging/
├── data/
│   ├── api/                      # Typed API services (auth, songs...)
│   ├── dto/                      # JSON ↔ Dart
│   ├── models/                   # Domain-ish models if needed
│   ├── repositories/             # Impl of domain repos
│   └── local/                    # sqflite datasources
├── domain/
│   ├── entities/                 # User, Song, Album...
│   └── repositories/             # Abstract interfaces
├── features/
│   ├── auth/                     # login, server config
│   ├── home/                     # dashboard
│   ├── library/                  # songs/albums/artists tabs
│   ├── search/                   # global search
│   ├── playlists/                # list + detail + reorder
│   ├── player/                   # mini, full, cassette, queue
│   ├── equalizer/                # EQ UI (no fake DSP)
│   ├── settings/                 # server, playback, about
│   ├── favorites/
│   └── history/
├── ui/
│   ├── theme.dart
│   └── widgets/
├── router.dart
└── main.dart
```

---

## Layers

### 1. Core/Network
Central `ApiClient` wraps Dio:
- baseUrl from `SecureStorage` + `AppConfig` (env fallback)
- `Authorization` interceptor, token refresh queue
- Logging in debug, timeouts (15s connect / 15s receive), retry for idempotent GETs
- `ApiException` mapping (401, 404, 500, timeout, no internet)
- Connectivity awareness → throws `NoInternetException` early if offline and cache available.

Widgets **never** import `dio`.

### 2. Data / API
One file per resource:
- `auth_api.dart`, `songs_api.dart`, `albums_api.dart`, `artists_api.dart`, `playlists_api.dart`, `search_api.dart`, `favorites_api.dart`, `history_api.dart`, `server_api.dart`
- Each returns typed entities (never `Map` to UI)
- Handles pagination envelope unwrapping
- Uses `CancelToken` for search debouncing

### 3. DTO → Entity
- DTOs in `data/dto/` handle nullable/missing fields defensively (no crash on backend version change)
- `toEntity()` maps to `domain/entities/` (e.g., `SongDto → Song`)
- Extra fields ignored.

### 4. Repositories
- Interface in `domain/repositories/` (e.g., `abstract class SongsRepository { Future<Paginated<Song>> getSongs(...) }`)
- Impl in `data/repositories/` orchestrates remote + local:
```
Repository.getSongs():
  try remote → cache to sqflite → return
  catch NoInternet → return cached sqflite
  catch other → rethrow as Failure
```
- Playlist mutations: optimistic local update → enqueue `SyncManager` → POST remote → on failure rollback.

### 5. Domain
- Pure entities: `User, Song, Album, Artist, Playlist, QueueItem, PlaybackState`
- `Paginated<T>` generic.
- No Flutter imports.

### 6. Audio Engine
```
AudioService (system)
   ↓
NexoraAudioHandler (audio_service) — owns AudioPlayer (just_audio)
   ↓
AudioPlayerService — queue, shuffle, repeat, position
   ↓
QueueManager — persistence, reorder, playNext, add, remove
   ↓
Riverpod: playbackProvider (Stream), queueProvider, currentTrackProvider
   ↓
UI (mini, full, lock screen)
```
- `NexoraAudioHandler` translates `just_audio` events to `playbackState` for notifications.
- `just_audio` consumes real stream URLs: `AudioSource.uri(Uri.parse(streamUrl), headers: {Authorization})`
- For offline files: `AudioSource.uri(Uri.file(localPath))`

### 7. State Management (Riverpod)
- `Provider`, `StateNotifier`/`Notifier`, `AsyncNotifier`, `StreamProvider`
- `authProvider` holds `AsyncValue<User?>` and exposes `login, logout, restoreSession`
- `songsProvider` is `FutureProvider` with pagination state held in `SongsNotifier`
- `playerProvider` streams `PlaybackState` from handler
- All providers injected via `ref.read(apiClientProvider)` etc. — no globals.

### 8. Navigation (GoRouter)
```
/login          → LoginScreen
/server-setup   → ServerConfigScreen
/               → Shell (with mini-player)
/home
/search
/library (tabs: songs/albums/artists/downloads)
/playlists
/playlists/:id
/favorites
/history
/settings
/player         → Full screen (or overlay)
```
ShellRoute keeps mini-player persistent above bottom nav. Full player is overlay or separate route.

---

## Caching & Offline

```
Server → Repository → sqflite cache → UI
         ↘ on mutation → SyncManager queue → retry when online
```

- **sqflite tables:** `tracks, albums, artists, playlists, playlist_items, sync_ops, history, favorites`
- Reads: serve cache immediately, then refresh from network (optional stale-while-revalidate).
- Writes (playlists/favorites): apply locally, enqueue, show optimistic UI, sync in background.
- **SyncManager:** WAL mode, `PRAGMA foreign_keys = ON`, handles 4xx (mark FAILED) vs network/5xx (retry with backoff).
- When offline: show cached data + offline banner; queue mutations; playable downloads via `localPath`.

Connectivity:
- `connectivity_service` distinguishes: `NoInternet` vs `ServerUnavailable` vs `Unauthorized` → different banners.

---

## Error Handling

Every request goes through `ApiErrorHandler` → `Failure` (user-friendly) vs raw exception (logged).

UI states per screen: `loading / success / empty / error / offline / refreshing`

Retry: only idempotent GETs auto-retry (exponential backoff, max 2). Mutations never auto-retry without idempotency key.

Logs: structured categories `[AUTH] [API] [PLAYER] [QUEUE] [SYNC] [CACHE]` — never log tokens.

---

## Security

- Tokens in `flutter_secure_storage` (`AndroidOptions.encryptedSharedPreferences`, `IOSOptions.accessibility: firstUnlock`)
- HTTPS enforcement in release (warning if http)
- No secrets in Git
- Sanitized logs
- Biometric/PIN not required but pluggable

---

## Platform

### Android
- `INTERNET`, `ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (Android 14+), `POST_NOTIFICATIONS` (13+)
- Notification channel `com.nexora.audio.channel.audio`
- Media controls via `audio_service`
- Audio focus & headset/Bluetooth handling via `audio_session`

### iOS
- `UIBackgroundModes: audio`
- `Audio Session` category `.playback`
- Lock screen metadata via `MPNowPlayingInfoCenter` (via audio_service)
- Remote commands (play/pause/next/prev/seek)
- Interruption & route change handling

---

## Testing
- Unit: DTO parsing, repositories (fake ApiClient), queue logic, sync logic
- Widget: player, mini, library
- Integration: login → fetch library → open album → play → next/prev → create playlist → favorite → search → logout
- Abstractions allow `FakeApiClient` injection; no live server in unit tests.

---

## Docs
- `api-contract.md` — endpoint specs
- `authentication.md` — auth flow
- `playback.md` — engine details
- `synchronization.md` — sync rules
- `offline-mode.md` — offline UX
- `android.md` / `ios.md` — platform specifics
- `development.md` — run/build/test

---

## Definition of Done (not just UI)

App is done when:
- auth against real server works
- library streams real audio
- background + lock screen works
- playlists/favorites/history sync
- offline mode serves cache
- Android+iOS hardened + tests pass + `flutter analyze` clean

