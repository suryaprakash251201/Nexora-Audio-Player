/**
 * Downloads provider — offline cache state machine (M4).
 * M1 stub so the rest of the app tree compiles.
 */
import React, { createContext, useContext, useMemo } from "react";
import type { DownloadState } from "@/library/types";

type DownloadsState = {
  stateByTrackId: Record<string, DownloadState>;
  download: (trackId: string) => Promise<void>;
  remove: (trackId: string) => Promise<void>;
};

const DownloadsContext = createContext<DownloadsState | null>(null);

export function DownloadsProvider({ children }: { children: React.ReactNode }) {
  const value = useMemo<DownloadsState>(() => ({
    stateByTrackId: {},
    download: async () => { /* M4 */ },
    remove: async () => { /* M4 */ },
  }), []);
  return <DownloadsContext.Provider value={value}>{children}</DownloadsContext.Provider>;
}

export function useDownloads(): DownloadsState {
  const v = useContext(DownloadsContext);
  if (!v) throw new Error("useDownloads must be used within DownloadsProvider");
  return v;
}