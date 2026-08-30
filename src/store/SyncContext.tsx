/**
 * Sync provider — reconciles playlists/favorites/recents between the server
 * and the local SQLite cache. M1 stub; the real SyncManager lands in M3.
 */
import React, { createContext, useContext, useMemo } from "react";

type SyncStatus = "idle" | "syncing" | "offline" | "conflict";

type SyncState = {
  status: SyncStatus;
  pendingOps: number;
  lastSyncAt: string | null;
  sync: () => Promise<void>;
};

const SyncContext = createContext<SyncState | null>(null);

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const value = useMemo<SyncState>(() => ({
    status: "idle",
    pendingOps: 0,
    lastSyncAt: null,
    sync: async () => { /* M3 — queue replay */ },
  }), []);
  return <SyncContext.Provider value={value}>{children}</SyncContext.Provider>;
}

export function useSync(): SyncState {
  const v = useContext(SyncContext);
  if (!v) throw new Error("useSync must be used within SyncProvider");
  return v;
}