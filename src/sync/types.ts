/**
 * Sync operation model (M3).
 *
 * Each local mutation that needs to reach the server is recorded as a row in
 * `sync_ops` so it survives offline + app restart. The SyncManager replays
 * the queue in insertion order with exponential backoff.
 *
 * Server-side playlist shape has no revision/etag — we use `updated_at`
 * (ISO string) as the version clock. A conflict is detected when the server's
 * `updated_at` has moved since we last pulled (`server_updated_at` in SQLite)
 * and we have pending ops for the same playlist.
 */

export type SyncEntity = "playlist" | "playlist_item" | "favorite";
export type SyncOpKind =
  | "create_playlist"
  | "rename_playlist"
  | "update_playlist" // description / is_public / cover
  | "delete_playlist"
  | "add_playlist_items"
  | "remove_playlist_item"
  | "reorder_playlist_items";

export interface SyncOp {
  id: number;
  entity: SyncEntity;
  entityId: string; // playlist id (or item id)
  op: SyncOpKind;
  payload: string; // JSON
  createdAt: string;
  attemptCount: number;
  lastError: string | null;
  nextAttemptAt: string;
}

export type SyncStatus = "idle" | "syncing" | "offline" | "conflict";

export interface ConflictInfo {
  playlistId: string;
  serverUpdatedAt: string;
  localUpdatedAt: string;
  pendingOps: SyncOp[];
}
