# Offline Mode

## Goals
- Fast launch even without internet
- Show cached library/playlists/favorites
- Keep downloaded tracks playable
- Avoid repeated failed API calls
- Queue changes, sync when back online

## Detection
`ConnectivityService` distinguishes:
- `NoInternet` (socket/connectionError) → show offline banner, serve cache
- `ServerUnavailable` (500/502/503, timeout) → show server banner
- `Unauthorized` (401) → logout, not offline

## Cached Data
| Data | Source | TTL | Offline UI |
|------|--------|-----|------------|
| Songs | `tracks` | 2m | List + search local |
| Albums/Artists | `albums`/`artists` | 5m | Grid / list |
| Playlists | `playlists`+`playlist_items` | 1m | Full list, optimistic edits |
| Favorites/History | `favorites`/`history` | 1m | Local |
| Artwork | disk cache (Image.network) | 7d | Cached images, fallback icon |
| Queue | `queue_state` | forever | Restore after restart |

## Behavior When Offline
- Repository catches `NoInternetException`, returns cached; UI shows `OfflineBanner`
- Mutations (create playlist, favorite, history) → optimistic local success + `SyncManager.enqueue` → Snackbar “Will sync when online”
- Search → if offline, fallback to `SongsLocalDataSource.searchLocal` (title/artist/album LIKE)
- Streaming → if `localPath` exists use file, else show “Offline — download first”

## When Connection Returns
```
offline changes → SyncManager.processSyncQueue() → server → confirm → update local ids/timestamps
```
Triggered on app resume + periodic check.

## 2026-09 — Live connectivity architecture (no native plugin)

```
ApiClient ──success/fail──▶ ConnectivityReporter (broadcast bus)
                                  │
                                  ▼
                    ConnectivityMonitor (debounced StateNotifier)
                     ├─ 2× fail ⇒ offline · 1× ok ⇒ online
                     ├─ 20s light ping (GET /healthz) as idle backstop
                     ├─ offline→online ⇒ showBackOnline pill (4s) + onReconnect
                     └─ mirrors legacy connectivityProvider for old watchers
                                  │
                    AppShell (router.dart)
                     ├─ attach(onProbe: ApiClient.ping, onReconnect: sync+refresh)
                     ├─ ConnectivityBanner top overlay (offline persistent /
                     │   back-online transient, auto-hide, AnimatedSwitcher)
                     ├─ MiniPlayer keeps playing (queue_state + downloads)
                     │   + amber cloud-off dot on artwork while offline
                     └─ FullPlayer shows inline OfflineChip under title

AudioHandler.loadMedia — source-first ordering: setAudioSource() before
queue.add(), so a failed remote load offline never wipes the playable queue.
```

- No `connectivity_plus` needed: HTTP outcomes + `/healthz` ping work on
  Android/iOS/web/desktop with zero native config.
- `unknown` counts as online (cold start never flashes offline).
- Banner lives in the shell Stack above content + below nothing else, so
  Home/Search/Library/Playlists/Settings all get it free.

## Download Manager
- `DownloadManager.downloadTrack` → `Dio.download` to `appDocuments/tracks/{id}.mp3` → update `tracks.isDownloaded`
- Progress via callback; `removeTrackDownload` deletes file + DB flag.

## UX Rules
- Never silently lose user changes (queue in sync_ops)
- Empty states explain offline vs empty library
- Pull-to-refresh forces remote fetch; if offline shows Snackbar

## Future
- Background sync via WorkManager (Android) / BGTask (iOS)
- Per-track position persistence for resume
