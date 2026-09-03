# Nexora Server — API Contract

> **Version:** 1.0.0  
> **Base URL:** `{serverUrl}/api/v1` — user-configurable, supports self-hosted LAN & HTTPS production  
> **Date:** 2026-08-31  
> **Status:** Audited from existing Flutter client + inferred production REST conventions. All endpoints are strongly typed in the mobile data layer.

This document is the **single source of truth** for the Flutter mobile client's network integration. Widgets never call Dio directly; they go through `ApiClient` → typed API services → repositories.

---

## 1. General Conventions

### 1.1 Base URL & Versioning
```
https://music.example.com/api/v1
http://192.168.1.100:3000/api/v1
http://localhost:3000/api/v1   // dev only
```
- API is versioned under `/api/v1`. Future `/api/v2` can be added without rewriting UI; isolation is in `data/api/`.
- `ApiClient` normalizes user input:
  - trims whitespace
  - prepends `http://` for bare IPs / `localhost`, `https://` otherwise
  - strips trailing `/`
  - appends `/api/v1` if missing

### 1.2 Authentication
- **Scheme:** Bearer JWT
- Header: `Authorization: Bearer <accessToken>`
- Tokens stored in `flutter_secure_storage` (never `shared_preferences`).
- Refresh token (if provided by server) stored alongside access token.
- Unauthorized flow:
```
request → attach token → 401 → try refresh → retry once → if still 401 → clear storage → redirect to /login
```
- Avoid infinite refresh loops (single retry per request, queued refresh).

### 1.3 Common Headers
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>  // when authenticated
X-Client-Version: 1.0.0
X-Platform: android | ios
```

### 1.4 Pagination
Cursor or offset pagination. Preferred format:
```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 543,
    "totalPages": 28,
    "hasNext": true,
    "hasPrev": false
  }
}
```
Query params: `?page=1&limit=20&sort=recent&order=desc&q=query`

Alternative (some endpoints): `?offset=0&limit=20`

Client handles both. Default `limit=20`, max `100`.

### 1.5 Sorting & Filtering
```
?sort=title|artist|album|createdAt|playCount&order=asc|desc
?filter=favorites|downloaded
?year=2023
?genre=rock
```

### 1.6 Error Format
Standard envelope:
```json
{
  "success": false,
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Human readable message",
    "details": { }
  }
}
```
HTTP status codes:
| Code | Meaning |
|------|---------|
| 400 | Bad Request / validation |
| 401 | Unauthorized (token missing/expired) |
| 403 | Forbidden |
| 404 | Not Found |
| 409 | Conflict (duplicate playlist name) |
| 422 | Validation error |
| 429 | Rate limited |
| 500 | Internal |
| 502/503 | Server unavailable |

Client maps to `ApiException` with `type` and `message` and shows user-friendly string.

### 1.7 Success Envelope (optional)
Some endpoints wrap in `{ success: true, data: ... }`. Others return raw object/array. `ApiClient` unwraps both.

---

## 2. Health & Server Info

### `GET /health`
No auth. Used for server URL validation screen.
- **Response 200:**
```json
{ "status": "ok", "uptime": 12345 }
```

### `GET /api/v1/server/info`
No auth (or optional auth).
- **Response 200:**
```json
{
  "serverVersion": "1.4.2",
  "apiVersion": "v1",
  "name": "Nexora",
  "features": {
    "supportsLyrics": true,
    "supportsPlaylists": true,
    "supportsFavorites": true,
    "supportsHistory": true,
    "supportsDownloads": true,
    "supportsRealtimeSync": false,
    "supportsEqualizer": false
  }
}
```
- **Caching:** 5 minutes. Used for capability discovery.

### `GET /api/v1/server/capabilities`
- Same as above, alternative path.

---

## 3. Authentication

### `POST /api/v1/auth/login`
Auth: none
```json
// Request
{ "username": "alex", "password": "s3cret" }
// or
{ "email": "alex@example.com", "password": "s3cret" }
```
Response 200:
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ... (optional)",
  "expiresIn": 3600,
  "user": {
    "id": "u_123",
    "username": "alex",
    "email": "alex@example.com",
    "displayName": "Alex",
    "avatarUrl": "https://..."
  }
}
```
Errors: 401 invalid credentials, 422 validation

### `POST /api/v1/auth/refresh`
Auth: refresh token in body or header
```json
{ "refreshToken": "eyJ..." }
```
Response 200: same as login (new tokens)

### `POST /api/v1/auth/logout`
Auth: required
Response 200: `{ "success": true }` — client clears storage regardless.

### `GET /api/v1/auth/me`
Auth: required
Response 200: `User` object
Used for session restoration on app launch.

### `POST /api/v1/auth/register` (optional)
If self-hosted allows registration.

---

## 4. Songs / Library

### `GET /api/v1/songs`
Auth: required
Query: `page, limit, offset, sort, order, q, albumId, artistId, genre`
Response 200: paginated `Song[]`
```json
{
  "data": [
    {
      "id": "s_abc123",
      "title": "Time",
      "artist": "Pink Floyd",
      "artistId": "ar_001",
      "album": "The Dark Side of the Moon",
      "albumId": "al_001",
      "duration": 414,
      "trackNumber": 3,
      "discNumber": 1,
      "year": 1973,
      "genre": "Progressive Rock",
      "coverUrl": "/api/v1/songs/s_abc123/artwork",
      "streamUrl": "/api/v1/songs/s_abc123/stream",
      "bitrate": 320,
      "sampleRate": 44100,
      "codec": "MP3",
      "lossless": false,
      "fileSize": 16543210,
      "createdAt": "2026-08-01T12:00:00Z",
      "updatedAt": "2026-08-01T12:00:00Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 543, "hasNext": true }
}
```
Caching: cache 2 min, plus SQLite offline cache.

### `GET /api/v1/songs/:id`
Auth: required  
Response 200: single `Song`

### `GET /api/v1/songs/:id/stream`
Auth: required (token via header or query `?token=` for native player)  
Response: audio binary `audio/mpeg`, `audio/flac`, etc. with `Range` support.  
- Client uses `just_audio` with `AudioSource.uri(Uri.parse("$baseUrl/songs/$id/stream"), headers: {"Authorization": "Bearer ..."})`  
- Handles `206 Partial Content`, buffering, seek.

### `GET /api/v1/songs/:id/artwork`
Auth: optional/required depending on server  
Query: `?size=small|medium|large` (e.g., 300, 600, 1200)  
Response: image/jpeg/png  
- Client uses `cached_network_image` with stable cache key `song-artwork-$id-$size` + fallback placeholder.

### `GET /api/v1/songs/:id/download`
Auth: required  
Response: binary download with `Content-Disposition`. For offline downloads via `DownloadManager`.

### `POST /api/v1/songs/:id/play` (optional)
Body: `{ "position": 0 }` — increment play count.

---

## 5. Albums

### `GET /api/v1/albums`
Auth: required  
Query: `page, limit, sort, q`
Response 200: paginated `Album[]`
```json
{
  "id": "al_001",
  "title": "The Dark Side of the Moon",
  "artist": "Pink Floyd",
  "artistId": "ar_001",
  "year": 1973,
  "genre": "Progressive Rock",
  "coverUrl": "/api/v1/albums/al_001/artwork",
  "trackCount": 10,
  "duration": 2580,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### `GET /api/v1/albums/:id`
Auth: required  
Response 200: `Album` detail

### `GET /api/v1/albums/:id/tracks`
Auth: required  
Response 200: `Song[]` (ordered by `trackNumber`) — may be paginated.

### `GET /api/v1/albums/:id/artwork`
Same as songs artwork.

---

## 6. Artists

### `GET /api/v1/artists`
Auth: required  
Query: `page, limit, q, sort`
Response: paginated `Artist[]`
```json
{
  "id": "ar_001",
  "name": "Pink Floyd",
  "artworkUrl": "/api/v1/artists/ar_001/artwork",
  "albumCount": 15,
  "trackCount": 120,
  "bio": "... (optional)"
}
```

### `GET /api/v1/artists/:id`
Auth: required  
Response 200: `Artist` detail

### `GET /api/v1/artists/:id/songs`
Auth: required  
Query: pagination  
Response: paginated `Song[]`

### `GET /api/v1/artists/:id/albums`
Auth: required  
Response: paginated `Album[]`

### `GET /api/v1/artists/:id/artwork`
Image endpoint.

---

## 7. Playlists

### `GET /api/v1/playlists`
Auth: required  
Response 200: `Playlist[]` (or paginated)
```json
{
  "id": "pl_123",
  "name": "Midnight Drives",
  "description": "For late nights",
  "coverUrl": "...",
  "ownerId": "u_123",
  "trackCount": 42,
  "duration": 12340,
  "isPublic": false,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### `POST /api/v1/playlists`
Auth: required  
Body:
```json
{ "name": "New Mix", "description": "optional", "isPublic": false }
```
Response 201: created `Playlist`

### `GET /api/v1/playlists/:id`
Auth: required  
Response 200: `Playlist` detail + tracks preview

### `GET /api/v1/playlists/:id/tracks`
Auth: required  
Query: `page, limit`
Response 200: paginated `Song[]` with `sortOrder` / `addedAt`

Alternative unified: `GET /playlists/:id` returns `{ playlist, tracks: [...] }` — client supports both.

### `PUT /api/v1/playlists/:id`
Auth: required  
Body: `{ "name": "...", "description": "..." }`
Response 200: updated `Playlist`

### `DELETE /api/v1/playlists/:id`
Auth: required  
Response 204 or 200.

### `POST /api/v1/playlists/:id/tracks`
Auth: required  
Body:
```json
{ "songId": "s_abc123" }
// or batch
{ "songIds": ["s_1", "s_2"] }
```
Response 200/201

Legacy path (already used in `sync_manager`): `POST /api/playlists/:id/tracks` — client normalizes `/api` → `/api/v1` if needed.

### `DELETE /api/v1/playlists/:id/tracks/:songId`
Auth: required  
Response 200.

### `PUT /api/v1/playlists/:id/reorder`
Auth: required  
Body:
```json
{ "orderedIds": ["s_3", "s_1", "s_2"] }
// or
{ "fromIndex": 0, "toIndex": 2 }
```
Response 200

### `POST /api/v1/playlists/:id/reorder` (alias)

---

## 8. Favorites / Likes

### `GET /api/v1/favorites`
Auth: required  
Query: `page, limit`
Response 200: paginated `Song[]` (favorited)

Alternative: `GET /api/v1/songs?filter=favorites`

### `POST /api/v1/favorites/:songId`
Auth: required  
Response 200/201: `{ "favorited": true }` or the `Song` with `isFavorite: true`

### `DELETE /api/v1/favorites/:songId`
Auth: required  
Response 200.

### Aliases (for compatibility):
- `POST /api/v1/songs/:id/favorite`
- `POST /api/v1/liked/:id`

Client tries `favorites` first.

---

## 9. Playback History

### `GET /api/v1/history`
Auth: required  
Query: `page, limit`
Response 200: paginated `PlaybackHistoryItem[]`
```json
{
  "songId": "s_abc",
  "song": { ...Song },
  "playedAt": "2026-08-30T22:10:00Z",
  "playDuration": 200,
  "completion": 0.8
}
```

Alternative: `GET /api/v1/recently-played`

### `POST /api/v1/history`
Auth: required  
Body:
```json
{
  "songId": "s_abc123",
  "playedAt": "2026-08-30T22:10:00Z",
  "duration": 414,
  "completed": true
}
```
Response 201

Batching strategy (client):
- fire on `track started`, `track 50%`, `track completed`
- debounce, do not POST every second
- queue offline and flush on reconnect

### `DELETE /api/v1/history` (optional)
Clear history

---

## 10. Search

### `GET /api/v1/search`
Auth: required  
Query: `q` (required, min 1-2 chars), `type=songs|albums|artists|playlists|all`, `limit`
Response 200:
```json
{
  "query": "pink",
  "results": {
    "songs": [ ...Song ],
    "albums": [ ...Album ],
    "artists": [ ...Artist ],
    "playlists": [ ...Playlist ]
  }
}
```
Alternative separate endpoints:
- `GET /api/v1/search/songs?q=...`
- `GET /api/v1/search/albums?q=...`

Client implements debounced (300ms) + cancellation of stale requests via Dio `CancelToken`.

Empty query → return recent searches locally, no request.

### `GET /api/v1/songs/search?q=...` (fallback)

---

## 11. User / Settings

### `GET /api/v1/user`
Auth: required  
Response 200: `User`

### `PUT /api/v1/user`
Auth: required  
Body: `{ "displayName": "...", "avatarUrl": "..." }`

### `GET /api/v1/settings`
Auth: required  
Response 200: user settings JSON (theme, quality, etc.)

### `PUT /api/v1/settings`
Auth: required

---

## 12. Artwork & Media

All artwork URLs may be absolute or relative. Client resolves relative against `baseUrl`.

Cache policy:
- `Cache-Control: public, max-age=86400`
- Mobile uses `cached_network_image` + `sqflite` metadata cache
- Broken image → fallback icon

Placeholders:
- Album: `assets/icon.png`
- Song fallback: music note icon
- Artist fallback: person icon

---

## 13. Upload (if supported)

### `POST /api/v1/upload`
Auth: required  
Content-Type: `multipart/form-data`
Field: `file`
Response 201: created `Song`

Client: `multipart/form-data` via Dio.

---

## 14. Realtime (optional)

If server exposes:
- `GET /api/v1/events` — Server-Sent Events
- `WS /api/v1/ws` — WebSocket

Events:
```
event: playlist.updated
data: { "playlistId": "pl_123" }

event: library.updated
event: favorite.updated
```

Client: `RealtimeService` that invalidates Riverpod providers, does not mutate widgets directly.

If not available, client falls back to pull-to-refresh + polling on resume.

---

## 15. Error Examples

```json
// 401
{ "success": false, "error": { "code": "TOKEN_EXPIRED", "message": "Token expired" } }

// 404
{ "success": false, "error": { "code": "NOT_FOUND", "message": "Playlist not found" } }

// 422
{ "success": false, "error": { "code": "VALIDATION_ERROR", "message": "Name is required", "details": {"name": ["required"]} } }
```

---

## 16. Caching Strategy (Client)

| Data | Cache | TTL | Offline |
|------|-------|-----|---------|
| Server info | memory + prefs | 5 min | yes (last known) |
| Songs | sqflite `tracks` | 2 min | yes |
| Albums | sqflite `albums` | 5 min | yes |
| Artists | sqflite `artists` | 5 min | yes |
| Playlists | sqflite `playlists` + `playlist_items` | 1 min | yes (optimistic) |
| Favorites | sqflite + memory | 1 min | pending sync |
| History | sqflite | 1 min | queued |
| Search | memory only | 0 | no (cached recent) |
| Artwork | disk cache (cached_network_image) | 7 days | yes |

---

## 17. Examples

### Login + fetch songs
```http
POST /api/v1/auth/login
{ "username": "alex", "password": "secret" }
→ 200 { accessToken, user }

GET /api/v1/songs?page=1&limit=20
Authorization: Bearer <token>
→ 200 { data: [...], pagination: {...} }

GET /api/v1/songs/s_abc123/stream
Authorization: Bearer <token>
→ 200 audio/mpeg (binary)
```

### Playlist creation (offline queue)
```http
POST /api/v1/playlists
{ "name": "Roadtrip" }
→ 201 { id: "pl_999", ... }

POST /api/v1/playlists/pl_999/tracks
{ "songId": "s_123" }
→ 201
```

---

## 18. Missing Endpoints — Graceful Degradation

If an endpoint is not implemented on the server:
1. Documented here with expected contract
2. Repository abstracts it behind an interface
3. UI checks `serverInfo.features` / catches `404` and hides/disables feature
4. Offline fallback or placeholder displayed

Example: if `GET /api/v1/lyrics/:songId` 404 → UI shows “Lyrics not available”.

---

## 19. Security Assumptions

- HTTPS enforced in production (client warns on http in release)
- No token logging
- `flutter_secure_storage` with `AndroidOptions(encryptedSharedPreferences: true)` and `IOSOptions(accessibility: firstUnlock)`
- TLS verification not disabled in production
- No secrets committed to Git

---

## 19b. Lyrics sync (verified against Go backend)

Sibling `.lrc` files are the source of truth (`internal/api/handlers_lyrics.go`).

- `GET /audio/lyrics?root=<id>&path=<rel>` → `{has_lyrics, raw, format:lrc|plain, source, synced, meta, cues:[{time,text}]}`
- `POST /audio/lyrics?root=&path=` `{raw, format}` (2 MiB cap) → writes sibling `.lrc`, clears DB shadow row
- `DELETE /audio/lyrics?root=&path=` → removes `.lrc` + shadow row → `{ok:true}`
- `time<0` cues are unsynced plain lines (render, never highlight)
- `[offset:ms]` shifts every cue; multi-tag lines fan out
- Flutter: `LyricsApi.get/save/deleteLyrics` + `lyricsProvider` family + `_LyricsEditorSheet` with SYNCED/PLAIN/MISSING pill

## 19c. Transcoding — analyzed, deferred

## 19d. Discovery + server stats (wired)

- `GET /playlists/public` → `{items:[Playlist]}` (same shape as `/playlists`,
  plus `owner_username`). App: Discover scope in the Playlists tab, dedicated
  cards show `by <owner>`, detail/reorder/remove degrade to server permission
  errors for non-owners. Own playlists are filtered out of Discover.
- `GET /stats?root=` → `{total_files,total_size,breakdown:{audio:{count,size}}}`.
  App: gradient Server Library card on the stats screen (tracks, audio size,
  quota bar from `/home/usage`). Null-safe: hides on error/offline/empty.
- `GET /home/usage` → `{total,available,used,file_count,breakdown}`.
  App: quota bar only; breakdown unused (audio stats come from `/stats`).

`GET /files/transcode` needs a server **session** (`session` + `start` offset
params, `quality=lossless|high|medium`) with server-side seeking. That model
is incompatible with `just_audio`'s byte-range seeking/background pipeline
without a custom `AudioSource` + session lifecycle. Deferred until a native
transcode-source is built; the app always streams `/files/raw` originals.

## 20. Changelog

- 2026-09-03: Lyrics sync verified (GET/POST/DELETE /audio/lyrics), background-audio config, bottom-dock (volume/speed/fav/sleep/lyrics)
- 2026-08-31: Initial contract — covers auth, library, streaming, playlists, favorites, history, search, artwork, realtime, settings.

