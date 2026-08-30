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
import { useSession } from "./SessionContext";
import type { MusicTrack } from "@/library/types";
import { player } from "@/audio/player";
import { resolveStreamUrl } from "@/audio/streamRouter";

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

  // Keep player.controller wired (idempotent).
  useEffect(() => {
    player.ensureInit();
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

  // Keep notification buttons routing through this context (honouring shuffle).
  const stepRef = useRef<(dir: 1 | -1) => MusicTrack | null>(() => null);
  const stateRef = useRef({ current, queue, shuffle });
  useEffect(() => { stateRef.current = { current, queue, shuffle }; }, [current, queue, shuffle]);
  useEffect(() => {
    stepRef.current = (dir: 1 | -1): MusicTrack | null => {
      const { current: c, queue: q, shuffle: sh } = stateRef.current;
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
      return dir > 0 ? q[0] : q[q.length - 1];
    };
  }, []);

  const setRepeat = useCallback((v: RepeatMode) => setRepeatState(v), []);

  const resolveUrl = useCallback(async (t: MusicTrack, sessionId: string): Promise<string | null> => {
    // Prefer any available download (even for REMOTE tracks that have been cached)
    const offlineUri = (t.download?.localUri || t.localUri) ?? null;
    if (offlineUri) return offlineUri;
    // For cached NEXORA_OFFLINE tracks the above already returns.
    if (t.localUri && t.source !== "NEXORA_REMOTE") return t.localUri;
    if (!api || !t.serverId) return t.localUri ?? null;
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
    const resolved: Array<{ track: MusicTrack; url: string }> = [];
    for (let i = 0; i < items.length; i += BATCH) {
      const batch = items.slice(i, i + BATCH);
      const results = await Promise.all(batch.map(async (t) => {
        const url = await resolveUrl(t, sessionId);
        return url ? { track: t, url } : null;
      }));
      for (const r of results) if (r) resolved.push(r);
    }
    return resolved;
  }, [resolveUrl]);

  const play = useCallback(async (track: MusicTrack, nextQueue?: MusicTrack[]) => {
    const q = nextQueue ?? [track];
    const sessionId = newSessionId();
    setQueue(q);
    setCurrent(track);

    if (!api) return;
    const resolved = await buildNativeQueue(q, sessionId);
    if (!resolved.length) return;
    await player.replaceQueue(resolved.map((r) => ({
      id: r.track.id,
      url: r.url,
      title: r.track.title,
      artist: r.track.artist ?? "Unknown",
      artwork: r.track.artwork.url ?? undefined,
      duration: r.track.metadata.durationSec ?? undefined,
    })));
    const idx = resolved.findIndex((r) => r.track.id === track.id);
    if (idx >= 0) await player.skipToIndex(idx, true);
    setShowPlayer(true);
    // Warm image cache so artwork swipes don't flash to blank (see NowPlayingArtwork).
    for (const r of resolved) {
      if (r.track.artwork.url) {
        try { await Image.prefetch(r.track.artwork.url); } catch {}
      }
    }
  }, [api, buildNativeQueue]);

  const pause = useCallback(async () => { await player.pause(); }, []);
  const resume = useCallback(async () => { await player.play(); }, []);
  const toggle = useCallback(async () => { if (playing) await player.pause(); else await player.play(); }, [playing]);
  const seekTo = useCallback(async (sec: number) => { await player.seekTo(sec); }, []);
  const seekBy = useCallback(async (d: number) => { await player.seekBy(d); }, []);

  const next = useCallback(async () => {
    const t = stepRef.current(1);
    if (!t) return;
    setCurrent(t);
  }, []);

  const prev = useCallback(async () => {
    const t = stepRef.current(-1);
    if (!t) return;
    setCurrent(t);
  }, []);

  const addToQueue = useCallback(async (track: MusicTrack) => {
    setQueue((prev) => [...prev, track]);
    // Also push to native queue
    const url = await resolveUrl(track, newSessionId());
    if (!url) return hasFailed();
    await player.addToQueue([{ id: track.id, url, title: track.title, artist: track.artist ?? "Unknown", artwork: track.artwork.url ?? undefined }]);
    // Warm art for the new item
    if (track.artwork.url) { try { await Image.prefetch(track.artwork.url); } catch {} }
    function hasFailed() { setQueue((prev) => prev.filter((x) => x.id !== track.id)); }
  }, [resolveUrl]);

  const playNext = useCallback(async (track: MusicTrack): Promise<boolean> => {
    if (!current) return false;
    const idx = queue.findIndex((x) => x.id === current.id);
    const at = idx >= 0 ? idx + 1 : queue.length;
    const nextQueue = [...queue];
    nextQueue.splice(at, 0, track);
    setQueue(nextQueue);
    // Native splice happens after local splice so indices line up
    const url = await resolveUrl(track, newSessionId());
    if (!url) { setQueue((p) => p.filter((x) => x.id !== track.id)); return false; }
    await player.addToQueue([{ id: track.id, url, title: track.title, artist: track.artist ?? "Unknown", artwork: track.artwork.url ?? undefined }]);
    return true;
  }, [current, queue, resolveUrl]);

  const removeFromQueue = useCallback(async (trackId: string) => {
    const idx = queue.findIndex((x) => x.id === trackId);
    if (idx < 0) return;
    const nextQueue = queue.filter((x) => x.id !== trackId);
    const wasPlaying = current?.id === trackId;
    setQueue(nextQueue);
    if (wasPlaying) {
      if (!nextQueue.length) {
        await player.reset();
        setCurrent(null);
        setShowPlayer(false);
        return;
      }
      setCurrent(nextQueue[Math.min(idx, nextQueue.length - 1)]);
    }
    try { await player.removeTrack(idx); } catch {}
  }, [queue, current]);

  const clearQueue = useCallback(async () => {
    await player.reset();
    setQueue([]);
    setCurrent(null);
    setShowPlayer(false);
  }, []);

  const close = useCallback(async () => {
    await player.reset();
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