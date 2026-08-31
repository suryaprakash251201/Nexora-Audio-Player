/**
 * Nexora remote library resolver.
 *
 * Fetches the server's audio catalog via the existing paginated
 * `GET /search?kind=audio` endpoint (no new server routes required for M2).
 * The search index already covers local + S3 roots.
 *
 * Contract (verified in audit):
 *  - `GET /api/v1/search?q=&kind=audio&sort=newest&limit&offset`
 *    returns `{ items: SearchResult[], has_more }`.
 *  - Each `SearchResult` is a file entry with `root_id`, `path`, `name`,
 *    `size`, `modified`, `mime`, `extension`.
 *  - There is no `/albums` or `/artists` index — we derive those client-side
 *    by grouping the flat list (good enough for 10k tracks; cursor paginates).
 */
import type { Api } from "@/api/client";
import type { SearchResult } from "@/api/types";
import { mapServerItemToTrack } from "./mapper";
import type { MusicTrack } from "./types";

/**
 * Returns true if the path/name lives inside a trash / hidden system folder.
 * Covers: `.trash`, `.Trash`, `.Trash-1000`, `__trash`, `$RECYCLE.BIN`, hidden dot-files.
 * Used to hide files that Nexora's search index may still return.
 */
export function isTrashOrHiddenPath(path: string, name?: string): boolean {
  const lower = path.toLowerCase();
  const segs = lower.split("/").filter(Boolean);
  // any segment is trash / recycle
  if (
    segs.some(
      (s) =>
        s === ".trash" ||
        s.startsWith(".trash-") ||
        s.startsWith(".trash_") ||
        s === "__trash" ||
        s === ".recycle" ||
        s === "$recycle.bin" ||
        s === "recycler",
    )
  )
    return true;
  if (lower.includes("/.trash/") || lower.startsWith(".trash/") || lower === ".trash" || lower.startsWith(".trash-")) return true;
  // hidden dot-file or dot-folder anywhere in the path (skip "." / ".." segments)
  if (segs.some((s) => s !== "." && s !== ".." && s.startsWith("."))) return true;
  if (name && name.startsWith(".")) return true;
  return false;
}

export interface FetchNexoraOptions {
  /** Max items to fetch. Default 2000 (safe for 10k collections; we paginate 200 at a time). */
  limit?: number;
  /** Filter by substring (server-side q). Applied to name/path. */
  query?: string;
  /** When set, only fetch this page. Otherwise auto-paginate until limit. */
  offset?: number;
  /** AbortSignal for cancellation (e.g. pull-to-refresh). */
  signal?: AbortSignal;
}

const PAGE_SIZE = 200;

export async function fetchNexoraTracks(
  api: Api,
  opts: FetchNexoraOptions = {},
): Promise<MusicTrack[]> {
  const limit = Math.min(opts.limit ?? 2000, 10000);
  const query = opts.query ?? "";
  const tracks: MusicTrack[] = [];
  let offset = opts.offset ?? 0;
  let hasMore = true;

  while (hasMore && tracks.length < limit) {
    if (opts.signal?.aborted) {
      const err = new Error("Aborted");
      err.name = "AbortError";
      throw err;
    }
    const pageLimit = Math.min(PAGE_SIZE, limit - tracks.length);
    const res = await api.search(query, {
      kind: "audio",
      sort: "newest",
      limit: pageLimit,
      offset,
    });
    const items: SearchResult[] = (res as any)?.items ?? [];
    for (const it of items) {
      if ((it as any).is_dir) continue;
      const p = (it as any).path as string | undefined;
      const n = (it as any).name as string | undefined;
      if (p && isTrashOrHiddenPath(p, n)) continue;
      if (!p && n && isTrashOrHiddenPath(n, n)) continue;
      tracks.push(mapServerItemToTrack(it as any));
    }
    hasMore = !!(res as any)?.has_more && items.length === pageLimit;
    offset += items.length;
    if (opts.offset !== undefined) break; // single page requested
    if (items.length === 0) break;
  }

  return tracks;
}

/** Search within the already-fetched Nexora track list (client-side). */
export function filterTracksByQuery(tracks: MusicTrack[], query: string): MusicTrack[] {
  const q = query.trim().toLowerCase();
  if (!q) return tracks;
  return tracks.filter((t) => {
    const hay = [t.title, t.artist ?? "", t.album ?? "", t.albumArtist ?? "", t.genre ?? ""]
      .join(" ")
      .toLowerCase();
    return hay.includes(q) || t.serverId?.path.toLowerCase().includes(q);
  });
}

/** Derive virtual albums/artists/genres from a flat track list. */
export function groupByAlbum(tracks: MusicTrack[]): Map<string, MusicTrack[]> {
  const m = new Map<string, MusicTrack[]>();
  for (const t of tracks) {
    const key = t.album?.trim() ? `${t.album} — ${t.albumArtist || t.artist || "Unknown"}` : "__singles__";
    const a = m.get(key);
    if (a) a.push(t);
    else m.set(key, [t]);
  }
  return m;
}

export function groupByArtist(tracks: MusicTrack[]): Map<string, MusicTrack[]> {
  const m = new Map<string, MusicTrack[]>();
  for (const t of tracks) {
    const key = (t.artist || t.albumArtist || "Unknown Artist").trim() || "Unknown Artist";
    const a = m.get(key);
    if (a) a.push(t);
    else m.set(key, [t]);
  }
  return m;
}

export function groupByGenre(tracks: MusicTrack[]): Map<string, MusicTrack[]> {
  const m = new Map<string, MusicTrack[]>();
  for (const t of tracks) {
    const key = (t.genre || "Unknown").trim() || "Unknown";
    const a = m.get(key);
    if (a) a.push(t);
    else m.set(key, [t]);
  }
  return m;
}

/** Folder helpers for home & library folder view. */
export function getFolderPath(path: string): string {
  const idx = path.lastIndexOf("/");
  if (idx <= 0) return "/";
  return path.slice(0, idx);
}
export function getFolderName(path: string): string {
  const folder = getFolderPath(path);
  if (folder === "/") return "Root";
  const segs = folder.split("/").filter(Boolean);
  return segs[segs.length - 1] || folder;
}
export function groupByFolder(tracks: MusicTrack[]): Map<string, MusicTrack[]> {
  const m = new Map<string, MusicTrack[]>();
  for (const t of tracks) {
    if (!t.serverId) continue;
    const filename = t.serverId.path.split("/").pop() ?? t.title;
    if (isTrashOrHiddenPath(t.serverId.path, filename)) continue;
    const folder = getFolderPath(t.serverId.path);
    const key = `${t.serverId.rootId}:${folder}`;
    const a = m.get(key);
    if (a) a.push(t);
    else m.set(key, [t]);
  }
  return m;
}