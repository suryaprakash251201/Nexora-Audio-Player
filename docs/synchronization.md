# Synchronization

## Principle
Server is source of truth. Mobile is optimistic offline-first with a durable sync queue.

```
UI → Repository (optimistic local update)
       → enqueue SyncOperation
       → try immediate remote POST
         → success → confirm
         → offline/5xx → keep PENDING, retry on reconnect
         → 4xx → mark FAILED (no retry)
```

## Tables
- `tracks`, `albums`, `artists` — read cache (stale-while-revalidate, TTL 2-5m)
- `playlists` + `playlist_items` — authoritative playlist cache
- `favorites` — local favorites mirror
- `history` — local playback history + queued records
- `sync_ops` — queue of mutations

## SyncManager
- `enqueueOperation(type, payload)` — inserts PENDING, triggers `processSyncQueue()`
- `processSyncQueue()` — sequential, ordered by `createdAt`
  - Maps type → `Dio` call:
    - `CREATE_PLAYLIST` → `POST /playlists`
    - `ADD_TO_PLAYLIST` → `POST /playlists/:id/tracks`
    - `REMOVE_FROM_PLAYLIST`, `REORDER_PLAYLIST`, `ADD/REMOVE_FAVORITE`, `RECORD_HISTORY`
  - Handles `DioException`: 4xx (except 401/429) → `FAILED`; network/5xx → increment `retryCount`, keep `PENDING`, break loop to backoff
- Called on app resume, connectivity restore, and after each enqueue.

## Playlists
- `getPlaylists()` → try remote → cache to sqflite → return; on offline return cached
- `createPlaylist()` → insert temp row `tmp_...` → try remote → replace with real id; offline → enqueue, return temp
- Mutations similar; optimistic UI via Riverpod, rollback on permanent failure.

## Favorites & History
- Same optimistic pattern; `history.recordPlay` debounced (10s periodic, completion immediate) to avoid per-second POSTs.

## Realtime (optional)
If `GET /events` (SSE) or `WS /ws` available, `RealtimeService` would listen for `playlist.updated`, `library.updated` etc. and invalidate providers. Currently fallback is pull-to-refresh + app-resume polling.

## Conflict Resolution
Last-write-wins for playlists (server timestamp is authoritative). Failed ops remain `FAILED` for manual inspection; `clearFailed()` available.

## Monitoring
`pendingCount()` for UI badge; logs `[SYNC]` category.
