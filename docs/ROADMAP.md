# Milestone Roadmap

Status legend: ⬜ not started · 🚧 in progress · ✅ done · ⛔ blocked

## M1 — Foundation + builds pass  ✅ (in this commit)
- Repo skeleton (app/, src/, docs/, assets/, app.json, package.json)
- Vendored building blocks from upstream `mobile/`: api client, theme, audio-quality tier engine, RNTP controller wrapper, NowPlayingArtwork
- `npm install` succeeds
- `npm run lint:hooks` passes (or skips cleanly)
- Web export builds (`expo export --platform web`)
- Android debug APK builds (`expo prebuild --platform android && cd android && ./gradlew assembleDebug`)
- iOS bundle prebuild (`expo prebuild --platform ios`)

## M2 — Unified library model  ✅ (this commit)
- `MusicTrack` unified model with source discrimination (NEXORA_REMOTE / DEVICE_LOCAL / NEXORA_OFFLINE)
- `src/library/mapper.ts` (FileItem/SearchResult → MusicTrack, AudioInfo enrichment, device asset mapper)
- `src/library/nexora.ts` (paginated `/search?kind=audio` fetcher, album/artist/genre groupers)
- `src/library/device.ts` (expo-media-library resolver, permission-aware, platform-guarded)
- `src/library/offline.ts` (SQLite stub wired into pipeline for M4)
- `src/library/dedupe.ts` (priority offline>device>remote, fuzzy textual key, stable display sort)
- `src/lib/cleanTitle.ts` (track-title normaliser)
- Real screens: Home (stats, recents, albums, artists), Library (All/Nexora/On Device/Downloads/Favorites/Recent with permission prompt), Search (debounced global), Playlists (read-only mirror), Login modal (server URL + user + TOTP), Settings (server + sign-out)

## M3 — Playlist sync  ✅ (this commit)
- `src/sync/types.ts` + `queue.ts` (durable `sync_ops` queue with exponential backoff, survives restart)
- `src/sync/playlistStore.ts` (SQLite mirror: `playlists` + `playlist_items`, `server_updated_at` vs `client_revision`)
- `src/sync/manager.ts` (SyncManager: pull→merge, push in order, `updated_at`-based conflict detection, three resolution strategies: keep_mine/keep_server/merge)
- `src/store/PlaylistContext.tsx` (optimistic local apply + enqueue + fire-and-forget sync, live `playlists` from SQLite, `syncStatus` + `pendingOps` + conflicts)
- Playlists screens rewritten: create modal, rename/delete overflow, `SyncPill` (Synced/Syncing/Offline/Conflict), conflict banner with three buttons, add-tracks picker, remove/move-to-top, pull-to-sync, offline-queue banner

## M4 — Offline downloads  ✅ (this commit)
- `src/downloads/manager.ts` (FileSystem.documentDirectory/nexora_offline, safe filename, DownloadResumable with progress, list/remove, batch with concurrency 2)
- `src/library/offline.ts` now reads SQLite downloads+tracks → NEXORA_OFFLINE MusicTracks (joins thumbnail URL)
- `src/store/DownloadsContext.tsx` (stateByTrackId/progressByTrackId/totalOffline, download/downloadMany/remove/refresh backed by manager + SQLite snapshot)
- Library Downloads tab now real (renders offline list with download/remove context menu, progress %), Playlist detail “Download” for whole playlist, TrackRow shows offline/downloading/failed badges
- Playback prefers offline localUri for any track (even REMOTE with cached download) so downloaded files play from disk without range/streaming

## M5 — Real DSP engine  ✅ (this commit)
- `src/dsp/constants.ts` (10 bands 31→16k, -12..+12 dB, 12 built-in presets + headroom helper)
- `src/store/DspContext.tsx` now durable (SQLite `dsp_state`, enabled/gains/preamp/balance/crossfeed/width/limiter/ReplayGain/preset, requiredHeadroom, reset)
- `src/ui/Slider.tsx` (pure-JS slider so DSP works without a native community slider)
- `app/dsp.tsx` Studio DSP: Spatial visual (labeled DSP-derived), Preamp/Balance/Limiter/ReplayGain, 10-band EQ grid with clamping, preset chips, clipping headroom warning, OFF/CLASSIC/MODERN width/crossfeed description

## M6 — Analyzer  🚧 (waveform foundation in this commit, FFT/spectrogram next)
- `src/ui/Waveform.tsx` deterministic seekable bar (real Float32Array when available, pseudo-bars otherwise — no fake analyzer values, tap-to-seek + active progress)
- Now Playing uses the waveform as its seek bar (progress from PlaybackContext, tap ratio → seek)
- Full FFT 20 Hz→20 kHz (log), peak-hold, spectrogram and LUFS meters still to land via `react-native-audio-api` PCM tap

## M7 — Now Playing redesign  ✅ (this commit)
- `app/track/[id].tsx` immersive dark player: blurred artwork background, double-buffered `NowPlayingArtwork` (no blank frame), lossless/hi-res badge, favorite, title/artist/album, `WaveformSeekBar` (tap-to-seek) + time + `24BIT | 192kHz | FLAC` technical badge, shuffle/prev/play-pause/next/repeat (one/all/off) with active states, bottom actions (Studio DSP · Audio Info · Queue), Now Playing source label
- Persistent `MiniPlayerBar` → tap expands to Now Playing (gesture nav covers swipe next/prev in next iteration)

## M8 — Studio DSP / Spatial  ✅ (included with M5 — spatial controls, crossfeed + stereo width sliders, radial visual labeled DSP-derived, Classic/Modern via width+crossfeed presets, detailed in `app/dsp.tsx`)

## M9 — Lyrics screen  ⬜
- Pull from upstream `/audio/lyrics`
- Synced playback with active-line highlight
- Edit + save (POST upstream)

## M10 — Search + Cache + Perf  ⬜
- Debounced global search across Nexora / device / offline
- SQLite cache for metadata + waveforms (not audio)
- FlashList virtualisation for 10k+ tracks

## M11 — Sleep timer / Favorites / Recents  ⬜
- Sleep timer with fade-out
- Favorites sync (optimistic + reconcile)
- Recents sync (batched)

## M12 — Tests, CI, docs  ⬜
- Jest tests for sync logic, library dedup, EQ/DSP state machine, queue ops
- CI workflow mirroring upstream `.github/workflows/mobile-build.yml`
- Release docs + sideload instructions