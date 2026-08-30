/**
 * Playlist store — optimistic local mirror + SyncManager queue (M3).
 *
 * UI components read `playlists` (SQLite mirror) and call `create/rename/etc`
 * which:
 *  1. Apply optimistically to SQLite so the UI updates instantly,
 *  2. Enqueue a durable `sync_ops` row,
 *  3. Trigger `syncManager.sync()` (fire-and-forget).
 *
 * On `refresh()`, we pull from server then drain the queue.
 */
import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { Playlist } from "@/api/types";
import { useSession } from "./SessionContext";
import { syncManager } from "@/sync/manager";
import { enqueue, countPending } from "@/sync/queue";
import {
  getLocalPlaylists,
  createLocalPlaylist,
  renameLocalPlaylist,
  deleteLocalPlaylist,
  addLocalPlaylistItems,
  removeLocalPlaylistItem,
  reorderLocalPlaylistItems,
  upsertPlaylistsFromServer,
} from "@/sync/playlistStore";
import type { SyncStatus } from "@/sync/types";

type PlaylistState = {
  playlists: Playlist[];
  loading: boolean;
  error: string | null;
  syncStatus: SyncStatus;
  pendingOps: number;
  refresh: () => Promise<void>;
  create: (name: string, description?: string) => Promise<string>;
  rename: (id: string, name: string) => Promise<void>;
  deletePlaylist: (id: string) => Promise<void>;
  addItems: (id: string, items: { root_id: string; path: string }[]) => Promise<void>;
  removeItem: (playlistId: string, itemId: string) => Promise<void>;
  reorder: (playlistId: string, itemIds: string[]) => Promise<void>;
  resolveConflict: (playlistId: string, strategy: "keep_mine" | "keep_server" | "merge") => Promise<void>;
  conflicts: { playlistId: string; serverUpdatedAt: string; localUpdatedAt: string }[];
};

const Ctx = createContext<PlaylistState | null>(null);

export function PlaylistProvider({ children }: { children: React.ReactNode }) {
  const { api } = useSession();
  const [playlists, setPlaylists] = useState<Playlist[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>("idle");
  const [pendingOps, setPendingOps] = useState(0);
  const [conflicts, setConflicts] = useState<PlaylistState["conflicts"]>([]);

  const reloadLocal = useCallback(async () => {
    const local = await getLocalPlaylists().catch(() => [] as any);
    setPlaylists(local as Playlist[]);
  }, []);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      // Pull server → local if we have an api
      if (api) {
        try {
          const res = await api.listPlaylists();
          if (res.items) await upsertPlaylistsFromServer(res.items);
        } catch (e: any) {
          if (e?.status === 401) throw e;
          // Network failures: keep local mirror and surface offline
        }
      }
      await reloadLocal();
      if (api) {
        syncManager.setApi(api);
        await syncManager.sync();
        setSyncStatus(syncManager.getStatus());
        setConflicts(syncManager.getConflicts().map((c) => ({ playlistId: c.playlistId, serverUpdatedAt: c.serverUpdatedAt, localUpdatedAt: c.localUpdatedAt })));
        setPendingOps(syncManager.getPendingCount());
        await reloadLocal();
      } else {
        setSyncStatus("offline");
      }
      setPendingOps(await countPending().catch(() => 0));
    } catch (e: any) {
      setError(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }, [api, reloadLocal]);

  useEffect(() => {
    syncManager.setApi(api);
    void reloadLocal();
    if (api) void refresh();
    const off = syncManager.onStatusChange((s) => setSyncStatus(s));
    return () => off();
  }, [api, refresh, reloadLocal]);

  const create = useCallback(async (name: string, description = ""): Promise<string> => {
    const trimmed = name.trim();
    if (!trimmed) throw new Error("Name required");
    const localId = await createLocalPlaylist(trimmed, description);
    await enqueue("playlist", localId, "create_playlist", { name: trimmed, description, items: [] });
    void reloadLocal();
    if (api) { syncManager.setApi(api); void syncManager.sync().then(() => void reloadLocal()); }
    return localId;
  }, [api, reloadLocal]);

  const rename = useCallback(async (id: string, name: string) => {
    const trimmed = name.trim();
    if (!trimmed) throw new Error("Name required");
    await renameLocalPlaylist(id, trimmed);
    await enqueue("playlist", id, "rename_playlist", { name: trimmed });
    void reloadLocal();
    if (api) { syncManager.setApi(api); void syncManager.sync().then(() => void reloadLocal()); }
  }, [api, reloadLocal]);

  const deletePlaylist = useCallback(async (id: string) => {
    await deleteLocalPlaylist(id);
    await enqueue("playlist", id, "delete_playlist", {});
    void reloadLocal();
    if (api) { syncManager.setApi(api); void syncManager.sync().then(() => void reloadLocal()); }
  }, [api, reloadLocal]);

  const addItems = useCallback(async (id: string, items: { root_id: string; path: string }[]) => {
    const tids = items.map((it) => `${it.root_id}:${it.path}`);
    await addLocalPlaylistItems(id, tids);
    await enqueue("playlist", id, "add_playlist_items", { items });
    void reloadLocal();
    if (api) { syncManager.setApi(api); void syncManager.sync().then(() => void reloadLocal()); }
  }, [api, reloadLocal]);

  const removeItem = useCallback(async (playlistId: string, itemId: string) => {
    await removeLocalPlaylistItem(playlistId, itemId);
    await enqueue("playlist", playlistId, "remove_playlist_item", { itemId });
    void reloadLocal();
    if (api) { syncManager.setApi(api); void syncManager.sync().then(() => void reloadLocal()); }
  }, [api, reloadLocal]);

  const reorder = useCallback(async (playlistId: string, itemIds: string[]) => {
    await reorderLocalPlaylistItems(playlistId, itemIds);
    await enqueue("playlist", playlistId, "reorder_playlist_items", { itemIds });
    void reloadLocal();
    if (api) { syncManager.setApi(api); void syncManager.sync().then(() => void reloadLocal()); }
  }, [api, reloadLocal]);

  const resolveConflict = useCallback(async (playlistId: string, strategy: "keep_mine" | "keep_server" | "merge") => {
    await syncManager.resolveConflict(playlistId, strategy);
    setConflicts(syncManager.getConflicts().map((c) => ({ playlistId: c.playlistId, serverUpdatedAt: c.serverUpdatedAt, localUpdatedAt: c.localUpdatedAt })));
    setSyncStatus(syncManager.getStatus());
    await reloadLocal();
  }, [reloadLocal]);

  const value = useMemo<PlaylistState>(() => ({
    playlists, loading, error, syncStatus, pendingOps, refresh, create, rename, deletePlaylist, addItems, removeItem, reorder, resolveConflict, conflicts,
  }), [playlists, loading, error, syncStatus, pendingOps, refresh, create, rename, deletePlaylist, addItems, removeItem, reorder, resolveConflict, conflicts]);

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function usePlaylists(): PlaylistState {
  const v = useContext(Ctx);
  if (!v) throw new Error("usePlaylists must be used within PlaylistProvider");
  return v;
}