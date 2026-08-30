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
    if (opts.signal?.aborted) throw new DOMException("Aborted", "AbortError");
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