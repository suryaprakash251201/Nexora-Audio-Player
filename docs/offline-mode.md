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
