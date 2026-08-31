/**
 * Playback context — the app-facing audio queue state machine.
 *
 * In upstream Nexora this lives in `AudioContext.tsx` (2465 LOC MiniPlayer +
 * AudioContext coupling). Here we keep the queue state decoupled from the
 * visual layer so it survives navigation/restart, and we add shuffle/repeat,
 * queue persistence, and seek-on-waveform hooks the audiophile UX needs.
 *
 * The controller underneath is `src/audio/player.ts` (react-native-track-player).
 * This context does not reimplement audio — it orchestrates queue intent.
 */
import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { Image } from "expo-image";
import { Platform } from "react-native";
import { useSession } from "./SessionContext";
import type { MusicTrack } from "@/library/types";
import { player } from "@/audio/player";
import { resolveStreamUrl } from "@/audio/streamRouter";
import { Toast } from "@/ui/Toast";

export type RepeatMode = "off" | "one" | "all";
export type ShuffleMode = boolean;

type PlaybackState = {
  current: MusicTrack | null;
  queue: MusicTrack[];
  index: number;
  playing: boolean;
  currentTime: number;
  duration: number;
  shuffle: ShuffleMode;
  repeat: RepeatMode;
  showPlayer: boolean;
  setShowPlayer: (v: boolean) => void;
  setShuffle: (v: boolean) => void;
  setRepeat: (v: RepeatMode) => void;

  play: (track: MusicTrack, queue?: MusicTrack[]) => Promise<void>;
  pause: () => Promise<void>;
  resume: () => Promise<void>;
  toggle: () => Promise<void>;
  next: () => Promise<void>;
  prev: () => Promise<void>;
  seekTo: (sec: number) => Promise<void>;
  seekBy: (deltaSec: number) => Promise<void>;

  addToQueue: (track: MusicTrack) => Promise<void>;
  playNext: (track: MusicTrack) => Promise<boolean>;
  removeFromQueue: (trackId: string) => Promise<void>;
  clearQueue: () => Promise<void>;
  close: () => Promise<void>;
};

const PlaybackContext = createContext<PlaybackState | null>(null);

function newSessionId(): string {
  const g: any = (globalThis as any)?.crypto;
  if (g?.randomUUID) return g.randomUUID();
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

export function PlaybackProvider({ children }: { children: React.ReactNode }) {
  const { api } = useSession();
  const [current, setCurrent] = useState<MusicTrack | null>(null);
  const [queue, setQueue] = useState<MusicTrack[]>([]);
  const [playing, setPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [shuffle, setShuffle] = useState(false);
  const [repeat, setRepeatState] = useState<RepeatMode>("off");
  const [showPlayer, setShowPlayer] = useState(false);

  // Keep player.controller wired (idempotent). Fire-and-forget but catch to avoid unhandled rejection on iOS.
  useEffect(() => {
    void player.ensureInit().catch((e) => console.warn("[Playback] ensureInit failed", e));
  }, []);

  // Mirror controller → context playback time.
  useEffect(() => {
    const off1 = player.on("playingChange", (p: any) => setPlaying(!!p.playing));
    const off2 = player.on("timeUpdate", (p: any) => {
      setCurrentTime(p.currentTime ?? 0);
      setDuration(p.duration ?? 0);
    });
    return () => { off1(); off2(); };
  }, []);

  // Keep controller in sync with `repeat`.
  useEffect(() => {
    player.setRepeat(repeat === "one" ? "track" : "off" as any);
  }, [repeat]);

  // Keep notification buttons routing through this context (honouring shuffle/repeat).
  const stepRef = useRef<(dir: 1 | -1) => MusicTrack | null>(() => null);
  const stateRef = useRef({ current, queue, shuffle, repeat });
  useEffect(() => { stateRef.current = { current, queue, shuffle, repeat }; }, [current, queue, shuffle, repeat]);
  useEffect(() => {
    stepRef.current = (dir: 1 | -1): MusicTrack | null => {
      const { current: c, queue: q, shuffle: sh, repeat: rp } = stateRef.current as { current: MusicTrack | null; queue: MusicTrack[]; shuffle: boolean; repeat: RepeatMode };
      if (!q.length) return null;
      if (q.length === 1) return c ?? q[0];
      if (sh) {
        const idx = c ? q.findIndex((x) => x.id === c.id) : -1;
        let ri = Math.floor(Math.random() * q.length);
        if (q.length > 1 && ri === idx) ri = (ri + 1) % q.length;
        return q[ri];
      }
      const idx = c ? q.findIndex((x) => x.id === c.id) : -1;
      if (idx >= 0 && idx + dir >= 0 && idx + dir < q.length) return q[idx + dir];
      // Respect repeat mode: only wrap when repeat is "all"
      if (rp === "all") return dir > 0 ? q[0] : q[q.length - 1];
      return null;
    };
  }, []);

  const setRepeat = useCallback((v: RepeatMode) => setRepeatState(v), []);

  const resolveUrl = useCallback(async (t: MusicTrack, sessionId: string): Promise<string | null> => {
    // Prefer any available download (even for REMOTE tracks that have been cached)
    // On iOS, ph:// URIs are not playable by AVPlayer — treat them as missing so we fall back or skip.
    const offlineUri = (t.download?.localUri || t.localUri) ?? null;
    if (offlineUri) {
      if (Platform.OS === "ios" && offlineUri.startsWith("ph://")) return null;
      return offlineUri;
    }
    // For cached NEXORA_OFFLINE tracks the above already returns.
    if (t.localUri && t.source !== "NEXORA_REMOTE") {
      if (Platform.OS === "ios" && t.localUri.startsWith("ph://")) return null;
      return t.localUri;
    }
    if (!t.serverId) return t.localUri ?? null;
    // If track is remote but we have no API (offline/not logged in) we cannot resolve a stream URL.
    // Return null so caller can skip it and surface a friendly error instead of crashing.
    if (!api) return null;
    try {
      return await resolveStreamUrl(api, t.serverId.rootId, t.serverId.path, {
        extension: t.serverId.path.split(".").pop(),
        size: t.fileSize ?? undefined,
        session: sessionId,
        realCodec: t.metadata.codec as string | null,
      });
    } catch { return null; }
  }, [api]);

  const buildNativeQueue = useCallback(async (items: MusicTrack[], sessionId: string) => {
    const BATCH = 6;
    const resolved: Array<{ track: MusicTrack; url: string; headers?: Record<string,string> }> = [];
    const token = (api as any)?.token as string | null | undefined;
    const authHeaders = token ? { Authorization: `Bearer ${token}` } : undefined;
    for (let i = 0; i < items.length; i += BATCH) {
      const batch = items.slice(i, i + BATCH);
      const results = await Promise.all(batch.map(async (t) => {
        try {
          const url = await resolveUrl(t, sessionId);
          if (!url) return null;
          // Extra guard: skip unplayable ph:// on iOS (should already be filtered)
          if (Platform.OS === "ios" && url.startsWith("ph://")) return null;
          // For http(s) remote URLs, attach Authorization header as well — AVPlayer on iOS
          // can use the track.headers field (RNTP passes via AVURLAsset options). Query token
          // already present, but header is belt-and-suspenders for servers that check header.
          const needsHeader = url.startsWith("http") && !!authHeaders;
          return needsHeader ? { track: t, url, headers: authHeaders } : { track: t, url };
        } catch {
          return null;
        }
      }));
      for (const r of results) if (r) resolved.push(r);
    }
    return resolved;
  }, [resolveUrl, api]);

  const play = useCallback(async (track: MusicTrack, nextQueue?: MusicTrack[]) => {
    const q = nextQueue ?? [track];
    const sessionId = newSessionId();
    // Optimistically set queue/current so UI reflects intent immediately
    setQueue(q);
    setCurrent(track);

    try {
      await player.ensureInit();

      const resolved = await buildNativeQueue(q, sessionId);
      if (!resolved.length) {
        // Check why we have no URL: iOS ph:// handling or not logged in for remote files
        const isRemoteNeedingAuth = track.source === "NEXORA_REMOTE" && !api && !track.localUri && !track.download?.localUri;
        if (Platform.OS === "ios" && (track.localUri?.startsWith("ph://") || track.download?.localUri?.startsWith("ph://"))) {
          Toast.error("iOS: this file needs file access — please allow media library and re-sync.");
        } else if (isRemoteNeedingAuth) {
          Toast.error("Connect to Nexora to stream this track, or download it for offline playback.");
        } else {
          Toast.error("No playable URL — check network, login, or try a downloaded/local file.");
        }
        console.warn("[Playback] No resolved URLs for queue", { trackId: track.id, queueLen: q.length });
        return;
      }

      // Guard: on iOS, ensure we don't pass ph:// which crashes AVPlayer
      const safeResolved = resolved.filter(r => !(Platform.OS === "ios" && r.url.startsWith("ph://")));
      if (!safeResolved.length) {
        Toast.error("This audio file cannot be played on iOS (unsupported URI).");
        return;
      }

      await player.replaceQueue(safeResolved.map((r) => ({
        id: r.track.id,
        url: r.url,
        title: r.track.title,
        artist: r.track.artist ?? "Unknown",
        artwork: r.track.artwork.url ?? undefined,
        duration: r.track.metadata.durationSec ?? undefined,
        headers: r.headers,
      } as any)));

      const idx = safeResolved.findIndex((r) => r.track.id === track.id);
      // If the chosen track was filtered out (unplayable), play first playable
      const targetIdx = idx >= 0 ? idx : 0;
      await player.skipToIndex(targetIdx, true);
      // Actually start playback — skip alone leaves state Paused/Stopped on iOS
      await player.play();
      setShowPlayer(true);

      // If we fell back to a different track, sync current
      if (targetIdx !== idx && safeResolved[targetIdx]) {
        setCurrent(safeResolved[targetIdx].track);
      }

      // Warm image cache so artwork swipes don't flash to blank (see NowPlayingArtwork).
      for (const r of safeResolved) {
        if (r.track.artwork.url) {
          try { await Image.prefetch(r.track.artwork.url); } catch {}
        }
      }
    } catch (e: any) {
      const msg = e?.message || String(e);
      console.warn("[Playback] play failed:", msg, e);
      // Don't leave UI stuck on a non-playable current — keep queue but hide player if nothing can play
      if (msg.includes("No playable URLs") || msg.includes("ph://") || msg.includes("player has not been initialized")) {
        Toast.error(`Playback failed: ${msg}`);
      } else {
        Toast.error(`Playback failed: ${msg.slice(0, 120)}`);
      }
      // On hard failure, re-throw as handled so callers with `void` don't trigger unhandled rejection crash on iOS
    }
  }, [api, buildNativeQueue]);

  const pause = useCallback(async () => {
    try { await player.ensureInit(); await player.pause(); } catch (e) { console.warn("[Playback] pause failed", e); }
  }, []);
  const resume = useCallback(async () => {
    try { await player.ensureInit(); await player.play(); } catch (e) { console.warn("[Playback] resume failed", e); Toast.error("Cannot resume playback"); }
  }, []);
  const toggle = useCallback(async () => {
    try { await player.ensureInit(); if (playing) await player.pause(); else await player.play(); } catch (e) { console.warn("[Playback] toggle failed", e); }
  }, [playing]);
  const seekTo = useCallback(async (sec: number) => {
    try { await player.ensureInit(); await player.seekTo(sec); } catch (e) { console.warn("[Playback] seekTo failed", e); }
  }, []);
  const seekBy = useCallback(async (d: number) => {
    try { await player.ensureInit(); await player.seekBy(d); } catch (e) { console.warn("[Playback] seekBy failed", e); }
  }, []);

  const next = useCallback(async () => {
    const t = stepRef.current(1);
    if (!t) return;
    const q = stateRef.current.queue;
    const idx = q.findIndex((x) => x.id === t.id);
    setCurrent(t);
    if (idx >= 0) {
      try {
        await player.ensureInit();
        await player.skipToIndex(idx);
        await player.play();
      } catch (e) { console.warn("[Playback] next skip failed", e); }
    }
  }, []);

  const prev = useCallback(async () => {
    const t = stepRef.current(-1);
    if (!t) return;
    const q = stateRef.current.queue;
    const idx = q.findIndex((x) => x.id === t.id);
    setCurrent(t);
    if (idx >= 0) {
      try {
        await player.ensureInit();
        await player.skipToIndex(idx);
        await player.play();
      } catch (e) { console.warn("[Playback] prev skip failed", e); }
    }
  }, []);

  // Wire OS media controls (lock screen / BT) to our next/prev that honour shuffle
  useEffect(() => {
    player.remoteHandlers.next = () => { void next(); };
    player.remoteHandlers.previous = () => { void prev(); };
  }, [next, prev]);

  // Auto-advance when the native queue ends (respect repeat)
  useEffect(() => {
    const off = player.on("ended", () => {
      if (repeat === "one") {
        void player.seekTo(0).then(() => void player.play());
        return;
      }
      void next();
    });
    return off;
  }, [next, repeat]);

  const addToQueue = useCallback(async (track: MusicTrack) => {
    setQueue((prev) => [...prev, track]);
    try {
      await player.ensureInit();
      const url = await resolveUrl(track, newSessionId());
      if (!url || (Platform.OS === "ios" && url.startsWith("ph://"))) {
        Toast.error("Cannot add to queue — no playable URL");
        setQueue((prev) => prev.filter((x) => x.id !== track.id));
        return;
      }
      const token = (api as any)?.token as string | null | undefined;
      const headers = token && url.startsWith("http") ? { Authorization: `Bearer ${token}` } : undefined;
      await player.addToQueue([{ id: track.id, url, title: track.title, artist: track.artist ?? "Unknown", artwork: track.artwork.url ?? undefined, headers } as any]);
      if (track.artwork.url) { try { await Image.prefetch(track.artwork.url); } catch {} }
    } catch (e: any) {
      console.warn("[Playback] addToQueue failed", e);
      Toast.error(`Add to queue failed: ${e?.message || e}`);
      setQueue((prev) => prev.filter((x) => x.id !== track.id));
    }
  }, [resolveUrl, api]);

  const playNext = useCallback(async (track: MusicTrack): Promise<boolean> => {
    if (!current) return false;
    const idx = queue.findIndex((x) => x.id === current.id);
    const at = idx >= 0 ? idx + 1 : queue.length;
    const nextQueue = [...queue];
    nextQueue.splice(at, 0, track);
    setQueue(nextQueue);
    try {
      await player.ensureInit();
      const url = await resolveUrl(track, newSessionId());
      if (!url || (Platform.OS === "ios" && url.startsWith("ph://"))) {
        Toast.error("Cannot play next — no playable URL");
        setQueue((p) => p.filter((x) => x.id !== track.id));
        return false;
      }
      const token = (api as any)?.token as string | null | undefined;
      const headers = token && url.startsWith("http") ? { Authorization: `Bearer ${token}` } : undefined;
      await player.addToQueue([{ id: track.id, url, title: track.title, artist: track.artist ?? "Unknown", artwork: track.artwork.url ?? undefined, headers } as any]);
      return true;
    } catch (e: any) {
      console.warn("[Playback] playNext failed", e);
      Toast.error(`Play next failed: ${e?.message || e}`);
      setQueue((p) => p.filter((x) => x.id !== track.id));
      return false;
    }
  }, [current, queue, resolveUrl, api]);

  const removeFromQueue = useCallback(async (trackId: string) => {
    const idx = queue.findIndex((x) => x.id === trackId);
    if (idx < 0) return;
    const nextQueue = queue.filter((x) => x.id !== trackId);
    const wasPlaying = current?.id === trackId;
    setQueue(nextQueue);
    if (wasPlaying) {
      if (!nextQueue.length) {
        try { await player.ensureInit(); await player.reset(); } catch {}
        setCurrent(null);
        setShowPlayer(false);
        return;
      }
      const nextTrack = nextQueue[Math.min(idx, nextQueue.length - 1)];
      setCurrent(nextTrack);
      try { await player.ensureInit(); await player.removeTrack(idx); } catch {}
      const nextIdx = nextQueue.findIndex((x) => x.id === nextTrack.id);
      if (nextIdx >= 0) {
        try { await player.ensureInit(); await player.skipToIndex(nextIdx); await player.play(); } catch (e) { console.warn("[Playback] remove skip failed", e); }
      }
      return;
    }
    try { await player.ensureInit(); await player.removeTrack(idx); } catch {}
  }, [queue, current]);

  const clearQueue = useCallback(async () => {
    try { await player.ensureInit(); await player.reset(); } catch {}
    setQueue([]);
    setCurrent(null);
    setShowPlayer(false);
  }, []);

  const close = useCallback(async () => {
    try { await player.ensureInit(); await player.reset(); } catch {}
    setCurrent(null);
    setShowPlayer(false);
  }, []);

  const idx = current ? queue.findIndex((x) => x.id === current.id) : -1;

  const value = useMemo<PlaybackState>(() => ({
    current, queue, index: idx, playing, currentTime, duration,
    shuffle, repeat, showPlayer, setShowPlayer, setShuffle, setRepeat,
    play, pause, resume, toggle, next, prev, seekTo, seekBy,
    addToQueue, playNext, removeFromQueue, clearQueue, close,
  }), [current, queue, idx, playing, currentTime, duration, shuffle, repeat, showPlayer, play, pause, resume, toggle, next, prev, seekTo, seekBy, addToQueue, playNext, removeFromQueue, clearQueue, close]);

  return <PlaybackContext.Provider value={value}>{children}</PlaybackContext.Provider>;
}

export function usePlayback(): PlaybackState {
  const v = useContext(PlaybackContext);
  if (!v) throw new Error("usePlayback must be used within PlaybackProvider");
  return v;
}