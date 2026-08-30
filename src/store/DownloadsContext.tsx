/**
 * Downloads provider — offline cache state machine (M4).
 *
 * Real implementation backed by `src/downloads/manager.ts` + SQLite.
 * UI reads `stateByTrackId` to show per-track badges and progress.
 */
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { DownloadState } from "@/library/types";
import type { MusicTrack } from "@/library/types";
import { useSession } from "./SessionContext";
import * as DownloadManager from "@/downloads/manager";
import { openDb } from "@/storage/db";

type DownloadsState = {
  stateByTrackId: Record<string, DownloadState>;
  progressByTrackId: Record<string, number>;
  download: (track: MusicTrack) => Promise<void>;
  downloadMany: (tracks: MusicTrack[]) => Promise<{ ok: number; failed: number }>;
  remove: (trackId: string) => Promise<void>;
  refresh: () => Promise<void>;
  totalOffline: number;
};

const DownloadsContext = createContext<DownloadsState | null>(null);

async function loadSnapshot(): Promise<{ byId: Record<string, DownloadState>; prog: Record<string, number>; totalOffline: number }> {
  const db = await openDb();
  const rows = await db.getAllAsync<any>(`SELECT track_id, state, progress FROM downloads`);
  const byId: Record<string, DownloadState> = {};
  const prog: Record<string, number> = {};
  let totalOffline = 0;
  for (const r of rows) {
    byId[r.track_id] = r.state as DownloadState;
    prog[r.track_id] = r.progress ?? 0;
    if (r.state === "AVAILABLE_OFFLINE") totalOffline++;
  }
  return { byId, prog, totalOffline };
}

export function DownloadsProvider({ children }: { children: React.ReactNode }) {
  const { api } = useSession();
  const [stateByTrackId, setStateByTrackId] = useState<Record<string, DownloadState>>({});
  const [progressByTrackId, setProgressByTrackId] = useState<Record<string, number>>({});
  const [totalOffline, setTotalOffline] = useState(0);

  const refresh = useCallback(async () => {
    const snap = await loadSnapshot().catch(() => ({ byId: {}, prog: {}, totalOffline: 0 } as any));
    setStateByTrackId(snap.byId);
    setProgressByTrackId(snap.prog);
    setTotalOffline(snap.totalOffline);
  }, []);

  useEffect(() => { void refresh(); }, [refresh]);

  const download = useCallback(async (track: MusicTrack) => {
    if (!api) throw new Error("Not connected");
    setStateByTrackId((p) => ({ ...p, [track.id]: "DOWNLOADING" }));
    setProgressByTrackId((p) => ({ ...p, [track.id]: 0 }));
    try {
      await DownloadManager.downloadTrack(api, track, (prog) => {
        setProgressByTrackId((prev) => ({ ...prev, [track.id]: prog }));
      });
      setStateByTrackId((p) => ({ ...p, [track.id]: "AVAILABLE_OFFLINE" }));
      setProgressByTrackId((p) => ({ ...p, [track.id]: 1 }));
      setTotalOffline((n) => n + 1);
    } catch (e: any) {
      setStateByTrackId((p) => ({ ...p, [track.id]: "FAILED" }));
      throw e;
    }
  }, [api]);

  const downloadMany = useCallback(async (tracks: MusicTrack[]) => {
    if (!api) throw new Error("Not connected");
    // optimistic: mark all as DOWNLOADING
    setStateByTrackId((prev) => {
      const next = { ...prev };
      for (const t of tracks) next[t.id] = "DOWNLOADING";
      return next;
    });
    const res = await DownloadManager.downloadTracks(api, tracks, {
      concurrency: 2,
      onProgress: () => { void refresh(); },
    });
    await refresh();
    return res;
  }, [api, refresh]);

  const remove = useCallback(async (trackId: string) => {
    await DownloadManager.removeDownload(trackId);
    setStateByTrackId((p) => { const n = { ...p }; delete n[trackId]; return n; });
    setProgressByTrackId((p) => { const n = { ...p }; delete n[trackId]; return n; });
    setTotalOffline((n) => Math.max(0, n - 1));
  }, []);

  const value = useMemo<DownloadsState>(() => ({
    stateByTrackId, progressByTrackId, download, downloadMany, remove, refresh, totalOffline,
  }), [stateByTrackId, progressByTrackId, download, downloadMany, remove, refresh, totalOffline]);

  return <DownloadsContext.Provider value={value}>{children}</DownloadsContext.Provider>;
}

export function useDownloads(): DownloadsState {
  const v = useContext(DownloadsContext);
  if (!v) throw new Error("useDownloads must be used within DownloadsProvider");
  return v;
}