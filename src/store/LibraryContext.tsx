/**
 * Library context — unified view of all music sources.
 *
 * M1: compiles with empty states and a tiny loading scaffold. The real
 * resolvers (Nexora search, on-device media library, offline downloads) land
 * in M2.
 */
import React, { createContext, useCallback, useContext, useMemo, useState } from "react";
import type { MusicTrack } from "@/library/types";

type LibraryState = {
  tracks: MusicTrack[];
  loading: boolean;
  error: string | null;
  refresh: () => Promise<void>;
  filter: { source: "all" | MusicTrack["source"]; query: string };
  setFilter: (f: Partial<LibraryState["filter"]>) => void;
};

const LibraryContext = createContext<LibraryState | null>(null);

export function LibraryProvider({ children }: { children: React.ReactNode }) {
  const [tracks, setTracks] = useState<MusicTrack[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilterRaw] = useState<LibraryState["filter"]>({ source: "all", query: "" });

  const setFilter = useCallback((patch: Partial<LibraryState["filter"]>) => {
    setFilterRaw((prev) => ({ ...prev, ...patch }));
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    // M2: will query api.search({ kind:"audio" }), device media-library,
    // and the local offline table, then run the dedup pass.
    // For M1, just return an empty library so the rest of the app can boot.
    setTracks([]);
    setLoading(false);
  }, []);

  const value = useMemo<LibraryState>(() => ({
    tracks, loading, error, refresh, filter, setFilter,
  }), [tracks, loading, error, refresh, filter, setFilter]);

  return <LibraryContext.Provider value={value}>{children}</LibraryContext.Provider>;
}

export function useLibrary(): LibraryState {
  const v = useContext(LibraryContext);
  if (!v) throw new Error("useLibrary must be used within LibraryProvider");
  return v;
}