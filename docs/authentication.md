# Authentication

## Overview
Nexora uses Bearer JWT. Mobile stores `accessToken` (+ optional `refreshToken`) in `flutter_secure_storage` with platform-secure options.

## Flow
```
App launch → restoreSession()
  → read token from SecureStorage
  → GET /auth/me
    → success → show Home
    → 401 → clear token → show Login
    → network error → use cached User JSON → show Home offline (banner)

Login screen → user enters server URL + username/password
  → save serverUrl (normalized) → POST /auth/login
    → 200 → save tokens + user JSON → navigate Home
    → 401 → show “Invalid credentials”
    → other → Failure mapping
```

## Token Storage
- `AndroidOptions(encryptedSharedPreferences: true)`
- `IOSOptions(accessibility: first_unlock)`
- Never in SharedPreferences or logs.

## Interceptor
`ApiClient` attaches `Authorization: Bearer …` per request. On 401:
- if endpoint is `/auth/login` or `/auth/refresh` → clear token, surface error
- else try `POST /auth/refresh` with `refreshToken` once (queued, single retry)
  - success → retry original request
  - fail → clear token → redirect to /login

No infinite loop; single retry per request via `_isRefreshing` completer.

## Server URL
User-configurable via `ServerConfigScreen`. Priority:
1. SecureStorage `nexora_server_url`
2. `--dart-define=NEXORA_API_BASE_URL`
3. `localhost:3000/api/v1` (debug only)

Normalized via `AppConfig.normalizeUrl`:
- bare IP → `http://`
- domain → `https://`
- ensure `/api/v1` suffix

Health check via `GET /health` / `GET /api/v1/server/info` for diagnostics.

## Logout
`POST /auth/logout` (best-effort) then `SecureStorage.clearAll()` + state → `/login`.

## Security Notes
- HTTPS enforced in production (warning if http in release)
- No TLS bypass
- Sanitized logs (`Bearer ***`)
