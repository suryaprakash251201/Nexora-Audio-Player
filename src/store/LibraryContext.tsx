/**
 * Library context — unified view of all music sources (M2).
 *
 * Pipeline on `refresh()`:
 *   1. Fetch Nexora remote tracks (if logged in) via `fetchNexoraTracks`
 *   2. Fetch device-local tracks via `fetchDeviceTracks`
 *   3. Fetch offline-cached tracks via `fetchOfflineTracks` (M4 stub for M2)
 *   4. Deduplicate (offline > device > remote)
 *   5. Publish `tracks` + raw `bySource` for the tab views
 *
 * The context is deliberately not paginated — it holds up to `limit` items
 * (default 4000) in memory. Virtualised lists handle the 10k case the brief
 * calls out. A single `refresh()` is ~2–3 batched `/search` round-trips.
 */
import React, { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import type { MusicTrack } from "@/library/types";
import { dedupeTracks } from "@/library/dedupe";
import { fetchNexoraTracks, isTrashOrHiddenPath } from "@/library/nexora";
import { fetchDeviceTracks, getDevicePermission } from "@/library/device";
import { fetchOfflineTracks } from "@/library/offline";
import { useSession } from "./SessionContext";

export type LibrarySourceFilter = "all" | MusicTrack["source"];

type LibraryState = {
  /** Deduped unified list (primary source per group). */
  tracks: MusicTrack[];
  /** Raw per-source lists (pre-dedupe). */
  bySource: {
    nexora: MusicTrack[];
    device: MusicTrack[];
    offline: MusicTrack[];
  };
  counts: { nexora: number; device: number; offline: number; unified: number };
  loading: boolean;
  error: string | null;
  filter: { source: LibrarySourceFilter; query: string };
  setFilter: (patch: Partial<LibraryState["filter"]>) => void;
  refresh: () => Promise<void>;
  /** Permission status for the On Device tab (so UI can prompt). */
  devicePermission: "unknown" | "granted" | "denied" | "blocked" | "undetermined";
  refreshDevicePermission: () => Promise<void>;
  toggleFavorite: (track: MusicTrack) => Promise<void>;
};

const LibraryContext = createContext<LibraryState | null>(null);

export function LibraryProvider({ children }: { children: React.ReactNode }) {
  const { api } = useSession();
  const [nexora, setNexora] = useState<MusicTrack[]>([]);
  const [device, setDevice] = useState<MusicTrack[]>([]);
  const [offline, setOffline] = useState<MusicTrack[]>([]);
  const [unified, setUnified] = useState<MusicTrack[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilterRaw] = useState<LibraryState["filter"]>({ source: "all", query: "" });
  const [devicePermission, setDevicePermission] = useState<LibraryState["devicePermission"]>("unknown");

  const abortRef = useRef<AbortController | null>(null);

  const refreshDevicePermission = useCallback(async () => {
    try {
      const p = await getDevicePermission();
      setDevicePermission(p as LibraryState["devicePermission"]);
    } catch {
      setDevicePermission("unknown");
    }
  }, []);

  useEffect(() => { void refreshDevicePermission(); }, [refreshDevicePermission]);

  const setFilter = useCallback((patch: Partial<LibraryState["filter"]>) => {
    setFilterRaw((prev) => ({ ...prev, ...patch }));
  }, []);

  const refresh = useCallback(async () => {
    abortRef.current?.abort();
    const ac = new AbortController();
    abortRef.current = ac;
    setLoading(true);
    setError(null);
    try {
      const [nx, dev, off, favs] = await Promise.all([
        api ? fetchNexoraTracks(api, { limit: 4000, signal: ac.signal }).catch((e) => { if ((e as any)?.name === "AbortError") throw e; return [] as MusicTrack[]; }) : Promise.resolve([] as MusicTrack[]),
        fetchDeviceTracks({ limit: 4000, signal: ac.signal }).catch((e) => { if ((e as any)?.name === "AbortError") throw e; return [] as MusicTrack[]; }),
        fetchOfflineTracks().catch(() => [] as MusicTrack[]),
        api ? api.listFavorites().catch(() => ({ items: [] })) : Promise.resolve({ items: [] }),
      ]);
      if (ac.signal.aborted || abortRef.current !== ac) return;
      const favPaths = new Set(favs.items.map((f: any) => `${f.root_id}:${f.path}`));
      const markedNx = nx.map((t) => (t.serverId && favPaths.has(`${t.serverId.rootId}:${t.serverId.path}`) ? { ...t, favorite: true } : t));
      // Re-apply favorites to offline tracks that may be dedup primary (offline > remote)
      const markedOff = off.map((t) => (t.serverId && favPaths.has(`${t.serverId.rootId}:${t.serverId.path}`) ? { ...t, favorite: true } : t));
      if (abortRef.current !== ac) return;
      setNexora(markedNx);
      setDevice(dev);
      setOffline(markedOff);
      const { tracks: deduped } = dedupeTracks([...markedNx, ...dev, ...markedOff]);
      if (abortRef.current !== ac) return;
      setUnified(deduped);
      // keep permission in sync after a device scan
      void refreshDevicePermission();
    } catch (e: any) {
      if (e?.name === "AbortError") return;
      if (abortRef.current !== ac) return;
      setError(e?.message || String(e));
    } finally {
      if (abortRef.current === ac && !ac.signal.aborted) setLoading(false);
    }
  }, [api, refreshDevicePermission]);

  const toggleFavorite = useCallback(async (track: MusicTrack) => {
    const nextFav = !track.favorite;
    const key = track.serverId ? `${track.serverId.rootId}:${track.serverId.path}` : null;
    const match = (t: MusicTrack) => t.id === track.id || (key && t.serverId ? `${t.serverId.rootId}:${t.serverId.path}` === key : false);
    setUnified((prev) => prev.map((t) => (match(t) ? { ...t, favorite: nextFav } : t)));
    setNexora((prev) => prev.map((t) => (match(t) ? { ...t, favorite: nextFav } : t)));
    setOffline((prev) => prev.map((t) => (match(t) ? { ...t, favorite: nextFav } : t)));
    if (api && track.serverId) {
      try {
        if (nextFav) {
          await api.addFavorite(track.serverId.rootId, track.serverId.path);
        } else {
          await api.removeFavorite(track.serverId.rootId, track.serverId.path);
        }
      } catch {
        // Revert on network failure
        setUnified((prev) => prev.map((t) => (match(t) ? { ...t, favorite: !nextFav } : t)));
        setNexora((prev) => prev.map((t) => (match(t) ? { ...t, favorite: !nextFav } : t)));
        setOffline((prev) => prev.map((t) => (match(t) ? { ...t, favorite: !nextFav } : t)));
      }
    }
  }, [api]);

  // Auto-refresh when the session becomes available (login) or on mount.
  const apiRef = useRef(api);
  useEffect(() => { apiRef.current = api; }, [api]);
  const didInit = useRef(false);
  useEffect(() => {
    if (didInit.current) return;
    didInit.current = true;
    void refresh();
  }, [refresh]);

  // Also refresh when api changes from null → non-null (login).
  const prevApiNull = useRef(api === null);
  useEffect(() => {
    const wasNull = prevApiNull.current;
    prevApiNull.current = api === null;
    if (wasNull && api !== null) void refresh();
  }, [api, refresh]);

  const filtered = useMemo(() => {
    let base = unified.filter((t) => {
      if (!t.serverId) return true;
      const filename = t.serverId.path.split("/").pop() ?? t.title;
      return !isTrashOrHiddenPath(t.serverId.path, filename);
    });
    if (filter.source !== "all") base = base.filter((t) => t.source === filter.source);
    const q = filter.query.trim().toLowerCase();
    if (!q) return base;
    return base.filter((t) => {
      const hay = `${t.title} ${t.artist ?? ""} ${t.album ?? ""} ${t.albumArtist ?? ""} ${t.genre ?? ""}`.toLowerCase();
      return hay.includes(q) || (t.serverId?.path.toLowerCase().includes(q) ?? false);
    });
  }, [unified, filter]);

  const value = useMemo<LibraryState>(() => ({
    tracks: filtered,
    bySource: { nexora, device, offline },
    counts: { nexora: nexora.length, device: device.length, offline: offline.length, unified: unified.length },
    loading,
    error,
    filter,
    setFilter,
    refresh,
    devicePermission,
    refreshDevicePermission,
    toggleFavorite,
  }), [filtered, nexora, device, offline, unified.length, loading, error, filter, setFilter, refresh, devicePermission, refreshDevicePermission, toggleFavorite]);

  return <LibraryContext.Provider value={value}>{children}</LibraryContext.Provider>;
}

export function useLibrary(): LibraryState {
  const v = useContext(LibraryContext);
  if (!v) throw new Error("useLibrary must be used within LibraryProvider");
  return v;
}