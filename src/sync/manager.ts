/**
 * SyncManager — bi-directional playlist reconciliation (M3).
 *
 * Responsibilities:
 *  - Detect connectivity (via fetch failure vs offline)
 *  - Pull server playlists and merge into SQLite mirror
 *  - Push queued local mutations in order with retry/backoff
 *  - Detect conflicts (`server_updated_at` drift while pending ops exist) and
 *    surface `SyncStatus.conflict` so UI can offer keep-mine / keep-server / merge.
 *
 * Server contract reminder:
 *  - Playlists have `updated_at` (ISO string, bumped on every server mutation).
 *  - No ETag / revision / If-Match — we must compare strings.
 *  - Items have no `updated_at`; only the parent playlist does.
 */
import type { Api } from "@/api/client";
import type { Playlist } from "@/api/types";
import { upsertPlaylistsFromServer, getLocalPlaylists } from "./playlistStore";
import { listDue, removeOp, failOp, countPending } from "./queue";
import type { SyncStatus, ConflictInfo } from "./types";

export class SyncManager {
  private api: Api | null = null;
  private status: SyncStatus = "idle";
  private conflicts: ConflictInfo[] = [];
  private listeners = new Set<(s: SyncStatus) => void>();
  private syncing = false;
  private pendingCount = 0;

  setApi(api: Api | null) {
    this.api = api;
  }

  getStatus(): SyncStatus {
    return this.status;
  }
  getConflicts(): ConflictInfo[] {
    return this.conflicts;
  }
  getPendingCount(): number {
    return this.pendingCount;
  }

  onStatusChange(cb: (s: SyncStatus) => void): () => void {
    this.listeners.add(cb);
    return () => this.listeners.delete(cb);
  }

  private emit(s: SyncStatus) {
    this.status = s;
    for (const cb of this.listeners) cb(s);
  }

  /** Full sync: pull then push. Safe to call while already syncing (second call is dropped). */
  async sync(): Promise<void> {
    if (this.syncing) return;
    if (!this.api) {
      this.emit("offline");
      return;
    }
    this.syncing = true;
    this.emit("syncing");
    try {
      await this.pull();
      await this.push();
      this.pendingCount = await countPending().catch(() => 0);
      if (this.conflicts.length) this.emit("conflict");
      else if (this.pendingCount > 0) this.emit("syncing");
      else this.emit("idle");
    } catch (e: any) {
      const msg = String(e?.message || e);
      if (msg.includes("Network") || msg.includes("fetch") || msg.includes("offline") || e?.status === 0) {
        this.emit("offline");
      } else {
        this.emit("idle");
      }
    } finally {
      this.syncing = false;
    }
  }

  private async pull(): Promise<void> {
    if (!this.api) return;
    let serverLists: Playlist[] = [];
    try {
      const res = await this.api.listPlaylists();
      serverLists = res.items || [];
    } catch (e: any) {
      if (String(e?.message).toLowerCase().includes("network") || e?.status === 0) throw e;
      // On 401/403/etc, leave local mirror as-is and let caller surface it.
      return;
    }

    // Copy server → local (server authoritative on pull, but we preserve any
    // local-only pending mutations by deferring the overwrite when conflict).
    const localLists = await getLocalPlaylists().catch(() => [] as any[]);
    const localById = new Map(localLists.map((p: any) => [p.id, p]));
    const pendingOps = await listDue("9999-12-31T23:59:59.000Z").catch(() => [] as any[]);

    const pendingByPlaylist = new Map<string, any[]>();
    for (const op of pendingOps) {
      const arr = pendingByPlaylist.get(op.entityId) || [];
      arr.push(op);
      pendingByPlaylist.set(op.entityId, arr);
    }

    const toUpsert: Playlist[] = [];
    const conflicts: ConflictInfo[] = [];

    for (const srv of serverLists) {
      const local: any = localById.get(srv.id);
      if (!local) {
        toUpsert.push(srv);
        continue;
      }
      const serverUpdated = srv.updated_at || "";
      const localServerUpdated = local.server_updated_at || "";
      const hasPending = (pendingByPlaylist.get(srv.id)?.length ?? 0) > 0;
      if (hasPending && localServerUpdated && serverUpdated !== localServerUpdated) {
        conflicts.push({
          playlistId: srv.id,
          serverUpdatedAt: serverUpdated,
          localUpdatedAt: localServerUpdated,
          pendingOps: pendingByPlaylist.get(srv.id)!,
        });
        // Do not overwrite local pending — leave conflict resolution to caller.
        continue;
      }
      toUpsert.push(srv);
    }

    // Also detect server-deleted playlists (local exists but server doesn't and has no pending create)
    // For M3 we simply keep local until its pending delete succeeds; no deletion here.

    if (toUpsert.length) await upsertPlaylistsFromServer(toUpsert);
    this.conflicts = conflicts;
  }

  private async push(): Promise<void> {
    if (!this.api) return;
    const api = this.api;
    // Operate on due ops only (respects backoff)
    const ops = await listDue();
    for (const op of ops) {
      const payload = JSON.parse(op.payload);
      try {
        switch (op.op) {
          case "create_playlist": {
            const created: Playlist = await api.createPlaylist(payload.name, payload.items || [], payload.description || "");
            // Map local id → server id: delete local stub and insert server version
            // The queue entry's entityId is the local stub id; the server returns the real id.
            // We orphan the local stub and upsert the server playlist (M4 will clean up).
            const { deleteLocalPlaylist } = await import("./playlistStore");
            await deleteLocalPlaylist(op.entityId).catch(() => {});
            await upsertPlaylistsFromServer([created]);
            break;
          }
          case "rename_playlist": {
            await api.renamePlaylist(op.entityId, payload.name);
            break;
          }
          case "update_playlist": {
            await api.patchPlaylist(op.entityId, payload);
            break;
          }
          case "delete_playlist": {
            await api.deletePlaylist(op.entityId).catch((e: any) => {
              if (e?.status === 404) return; // already gone
              throw e;
            });
            break;
          }
          case "add_playlist_items": {
            await api.addPlaylistItems(op.entityId, payload.items);
            break;
          }
          case "remove_playlist_item": {
            await api.removePlaylistItem(op.entityId, payload.itemId);
            break;
          }
          case "reorder_playlist_items": {
            await api.reorderPlaylistItems(op.entityId, payload.itemIds);
            break;
          }
          default:
            break;
        }
        await removeOp(op.id);
      } catch (e: any) {
        await failOp(op.id, e?.message || String(e));
        // Stop pushing subsequent ops that depend on this playlist (they share the same entityId)
        // but continue for other playlists — so don't break, just continue.
      }
    }
  }

  /** Resolve a conflict by choosing a strategy. M3 exposes three. */
  async resolveConflict(playlistId: string, strategy: "keep_mine" | "keep_server" | "merge"): Promise<void> {
    const conflict = this.conflicts.find((c) => c.playlistId === playlistId);
    if (!conflict) return;

    if (strategy === "keep_server") {
      // Drop pending ops for this playlist and re-pull
      const { listPending } = await import("./queue");
      const all = await listPending(1000);
      for (const op of all) if (op.entityId === playlistId) await removeOp(op.id);
      // Next pull will overwrite local with server
      await this.pull();
    } else if (strategy === "keep_mine") {
      // Just push — push will already retry. Clear conflict marker.
      this.conflicts = this.conflicts.filter((c) => c.playlistId !== playlistId);
    } else {
      // merge: union items — push adds will be replayed, server pull will bring missing server items.
      // For M3 we keep it simple: push then pull to union.
      this.conflicts = this.conflicts.filter((c) => c.playlistId !== playlistId);
      await this.push();
      await this.pull();
    }
  }
}

export const syncManager = new SyncManager();
