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

## M3 — Playlist sync  ⬜
- `SyncManager`: queue + push/pull + retry + backoff
- Local SQLite cache of playlists (mirror of server schema + `client_revision`)
- Conflict detection: compare `updated_at`, prompt user (keep-mine / keep-server / merge) when both sides moved
- UI states: Synced / Syncing / Offline / Conflict

## M4 — Offline downloads  ⬜
- `DownloadManager`: state machine {REMOTE, DOWNLOADING, AVAILABLE_OFFLINE, FAILED}
- `expo-file-system` chunked download with resume
- "Downloaded" tab + per-playlist "Download playlist" action
- Storage quota + Wi-Fi-only setting

## M5 — Real DSP engine  ⬜
- `AudioDSP` abstraction + platform impls
  - Android: `android.media.audiofx.Equalizer` + custom biquad chain
  - iOS: `AVAudioUnitEQ` + custom AVAudioUnit biquad chain
- 10-band graphic EQ (31 Hz → 16 kHz), preamp (-12..+12 dB), balance, limiter
- ReplayGain (track + album) from `/audio/info` tags
- 12 stock presets + custom user presets persisted in SQLite
- See `docs/DSP.md`

## M6 — Analyzer  ⬜
- `react-native-audio-api` PCM tap from RNTP playback
- FFT (size 2048), log frequency, peak-hold, decay
- Waveform: pre-computed for downloaded files, on-the-fly for streaming
- Spectrogram: scrolling frequency-time heatmap
- Live meters: peak (dBFS), RMS, short-term K-weighted LUFS approximation
- All labels explicitly mark "estimated" when not from a calibrated chain

## M7 — Now Playing redesign  ⬜
- New `track/[id].tsx` screen with distinct Nexora design language
- Reuse `NowPlayingArtwork` for zero-blank-frame swipes
- Mini ↔ Full animated transition (spring)
- Glass surfaces, soft gradients driven by artwork average colour

## M8 — Studio DSP / Spatial  ⬜
- `dsp/index.tsx` route: Spatial / Equalizer / Preamp / Crossfeed / Stereo Width / Loudness / ReplayGain / Limiter / Analyzer
- Radial visual labelled "DSP-derived" for synthesised positions
- Three modes: Off / Classic / Modern (crossfeed + slight widening only)

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