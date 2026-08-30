/**
 * Local SQLite mirror for playlists (M3).
 *
 * The server is the source of truth, but we keep a local copy so the UI can
 * render instantly while offline and so mutations can be applied optimistically.
 * Each row tracks `server_updated_at` (last seen from server) and
 * `client_revision` (incremented on every local mutation). A mismatch between
 * `server_updated_at` and the server's current `updated_at` while we have
 * pending ops signals a conflict.
 */
import { openDb } from "@/storage/db";
import type { Playlist } from "@/api/types";

function nowIso(): string {
  return new Date().toISOString();
}

export async function upsertPlaylistsFromServer(playlists: Playlist[]): Promise<void> {
  const db = await openDb();
  await db.execAsync("BEGIN");
  try {
    for (const pl of playlists) {
      await db.runAsync(
        `INSERT INTO playlists (id, name, description, cover_root_id, cover_path, is_public, server_updated_at, client_revision, last_synced_at, is_local_only)
         VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, 0)
         ON CONFLICT(id) DO UPDATE SET
           name = excluded.name,
           description = excluded.description,
           cover_root_id = excluded.cover_root_id,
           cover_path = excluded.cover_path,
           is_public = excluded.is_public,
           server_updated_at = excluded.server_updated_at,
           last_synced_at = excluded.last_synced_at
           -- do NOT overwrite client_revision`,
        pl.id,
        pl.name,
        pl.description ?? "",
        pl.cover_root_id ?? "",
        pl.cover_path ?? "",
        pl.is_public ? 1 : 0,
        pl.updated_at,
        nowIso(),
      );

      // Replace items (server list is authoritative when we just pulled)
      await db.runAsync(`DELETE FROM playlist_items WHERE playlist_id = ?`, pl.id);
      let pos = 0;
      for (const it of pl.items || []) {
        await db.runAsync(
          `INSERT INTO playlist_items (id, playlist_id, track_id, position, added_at)
           VALUES (?, ?, ?, ?, ?)`,
          it.id,
          pl.id,
          `${it.root_id}:${it.path}`,
          pos++,
          it.created_at ?? nowIso(),
        );
      }
    }
    await db.execAsync("COMMIT");
  } catch (e) {
    await db.execAsync("ROLLBACK");
    throw e;
  }
}

export async function getLocalPlaylists(): Promise<(Playlist & { client_revision: number; server_updated_at: string | null; is_local_only: number })[]> {
  const db = await openDb();
  const pls = await db.getAllAsync<any>(`SELECT * FROM playlists ORDER BY name COLLATE NOCASE`);
  const out: any[] = [];
  for (const row of pls) {
    const items = await db.getAllAsync<any>(
      `SELECT pi.*, t.title, t.artist FROM playlist_items pi LEFT JOIN tracks t ON t.id = pi.track_id WHERE pi.playlist_id = ? ORDER BY pi.position`,
      row.id,
    );
    // Re-materialise as Playlist shape (items carry track metadata from `tracks` if cached)
    out.push({
      id: row.id,
      name: row.name,
      description: row.description,
      cover_root_id: row.cover_root_id,
      cover_path: row.cover_path,
      is_public: !!row.is_public,
      created_at: row.created_at,
      updated_at: row.server_updated_at || row.created_at,
      items: items.map((it: any) => ({
        id: it.id,
        playlist_id: it.playlist_id,
        root_id: it.track_id.split(":")[0],
        path: it.track_id.split(":").slice(1).join(":"),
        created_at: it.added_at,
        position: it.position,
        name: it.title || it.track_id,
        extension: it.track_id.split(".").pop() || "",
        mime: "",
        size: 0,
        modified: it.added_at,
      })),
      client_revision: row.client_revision,
      server_updated_at: row.server_updated_at,
      is_local_only: row.is_local_only,
      last_synced_at: row.last_synced_at,
    });
  }
  return out;
}

export async function createLocalPlaylist(name: string, description = ""): Promise<string> {
  const db = await openDb();
  const id = `local_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`;
  await db.runAsync(
    `INSERT INTO playlists (id, name, description, cover_root_id, cover_path, is_public, server_updated_at, client_revision, last_synced_at, is_local_only, created_at)
     VALUES (?, ?, ?, '', '', 0, NULL, 1, NULL, 1, ?)`,
    id,
    name,
    description,
    nowIso(),
  );
  return id;
}

export async function renameLocalPlaylist(id: string, name: string): Promise<void> {
  const db = await openDb();
  await db.runAsync(`UPDATE playlists SET name = ?, client_revision = client_revision + 1 WHERE id = ?`, name, id);
}

export async function deleteLocalPlaylist(id: string): Promise<void> {
  const db = await openDb();
  await db.runAsync(`DELETE FROM playlists WHERE id = ?`, id);
}

export async function addLocalPlaylistItems(id: string, trackIds: string[]): Promise<void> {
  const db = await openDb();
  const maxRow = await db.getFirstAsync<{ m: number | null }>(`SELECT MAX(position) as m FROM playlist_items WHERE playlist_id = ?`, id);
  let pos = (maxRow?.m ?? -1) + 1;
  await db.execAsync("BEGIN");
  try {
    for (const tid of trackIds) {
      const itemId = `${id}_${tid}_${Date.now().toString(36)}`;
      await db.runAsync(
        `INSERT INTO playlist_items (id, playlist_id, track_id, position, added_at) VALUES (?, ?, ?, ?, ?)`,
        itemId,
        id,
        tid,
        pos++,
        nowIso(),
      );
    }
    await db.runAsync(`UPDATE playlists SET client_revision = client_revision + 1 WHERE id = ?`, id);
    await db.execAsync("COMMIT");
  } catch (e) {
    await db.execAsync("ROLLBACK");
    throw e;
  }
}

export async function removeLocalPlaylistItem(playlistId: string, itemId: string): Promise<void> {
  const db = await openDb();
  await db.runAsync(`DELETE FROM playlist_items WHERE id = ? AND playlist_id = ?`, itemId, playlistId);
  await db.runAsync(`UPDATE playlists SET client_revision = client_revision + 1 WHERE id = ?`, playlistId);
}

export async function reorderLocalPlaylistItems(playlistId: string, orderedItemIds: string[]): Promise<void> {
  const db = await openDb();
  await db.execAsync("BEGIN");
  try {
    for (let i = 0; i < orderedItemIds.length; i++) {
      await db.runAsync(`UPDATE playlist_items SET position = ? WHERE id = ? AND playlist_id = ?`, i, orderedItemIds[i], playlistId);
    }
    await db.runAsync(`UPDATE playlists SET client_revision = client_revision + 1 WHERE id = ?`, playlistId);
    await db.execAsync("COMMIT");
  } catch (e) {
    await db.execAsync("ROLLBACK");
    throw e;
  }
}
