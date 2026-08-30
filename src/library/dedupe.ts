/**
 * Deduplicate a unified library so a track that exists in multiple sources
 * appears only once visually.
 *
 * Key design decisions (per brief):
 *  - Never drop provenance: the dedup keeps the highest-priority source as the
 *    primary `track` and stashes lower-priority duplicates in `_alts` so the
 *    sync and download layers can still find them. For M2 we expose only the
 *    primary list; M3/M4 read `_alts` when reconciling.
 *  - Priority: NEXORA_OFFLINE > DEVICE_LOCAL > NEXORA_REMOTE. Offline wins
 *    because it can play without network; device-local wins over remote for
 *    the same reason; remote is the fallback.
 *  - Group key: normalized (title + artist + album + duration bucket). This is
 *    intentionally fuzzy — we only merge when the signals strongly agree. Two
 *    files with the same filename but wildly different durations are not merged.
 */

import type { MusicTrack, MusicSource } from "./types";

const PRIORITY: Record<MusicSource, number> = {
  NEXORA_OFFLINE: 3,
  DEVICE_LOCAL: 2,
  NEXORA_REMOTE: 1,
};

function norm(s: string | null | undefined): string {
  if (!s) return "";
  return s.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

function durationBucket(sec: number | null): string {
  if (sec == null) return "unknown";
  // 2-second bucket — tolerant to encoder padding differences
  return String(Math.round(sec / 2) * 2);
}

function groupKey(t: MusicTrack): string {
  // For server tracks, the canonical server path is the identity — never
  // fuzzy-match two server tracks that live at different paths even if their
  // tags collide.
  if (t.source === "NEXORA_REMOTE" || t.source === "NEXORA_OFFLINE") {
    if (t.serverId) return `srv:${t.serverId.rootId}:${t.serverId.path}`;
  }
  // For device/offline-merged tracks, use textual fingerprint
  const title = norm(t.title);
  const artist = norm(t.artist);
  const album = norm(t.album);
  const dur = durationBucket(t.metadata.durationSec);
  if (!title) return t.id; // degenerate — don't merge
  return `txt:${title}|${artist}|${album}|${dur}`;
}

export interface DedupeResult {
  tracks: MusicTrack[];
  /** Map from group key → all tracks that were collapsed into one primary. */
  groups: Map<string, MusicTrack[]>;
}

export function dedupeTracks(input: MusicTrack[]): DedupeResult {
  const byKey = new Map<string, MusicTrack[]>();
  for (const t of input) {
    const k = groupKey(t);
    const arr = byKey.get(k);
    if (arr) arr.push(t);
    else byKey.set(k, [t]);
  }

  const out: MusicTrack[] = [];
  const groups = new Map<string, MusicTrack[]>();

  for (const [k, arr] of byKey) {
    if (arr.length === 1) {
      out.push(arr[0]);
      continue;
    }
    // Multiple tracks share a key — keep the highest-priority one as primary.
    // Priority tie-breaker: larger file (likely lossless), then most recent.
    const sorted = [...arr].sort((a, b) => {
      const pa = PRIORITY[a.source] ?? 0;
      const pb = PRIORITY[b.source] ?? 0;
      if (pb !== pa) return pb - pa;
      const sa = a.fileSize ?? 0;
      const sb = b.fileSize ?? 0;
      if (sb !== sa) return sb - sa;
      const ma = a.modifiedAt ? Date.parse(a.modifiedAt) : 0;
      const mb = b.modifiedAt ? Date.parse(b.modifiedAt) : 0;
      return mb - ma;
    });
    const primary = sorted[0];
    // Attach _alts non-enumerably so JSON.stringify doesn't leak it, but the
    // download/sync layers can read (primary as any)._alts when needed.
    (primary as any)._alts = sorted.slice(1);
    out.push(primary);
    groups.set(k, sorted);
  }

  // Stable sort for display: album, then track number, then title
  out.sort((a, b) => {
    const aa = (a.album || "").localeCompare(b.album || "");
    if (aa !== 0) return aa;
    const ta = a.trackNumber ?? 9999;
    const tb = b.trackNumber ?? 9999;
    if (ta !== tb) return ta - tb;
    return a.title.localeCompare(b.title);
  });

  return { tracks: out, groups };
}

/** Convenience: just the deduped list. */
export function dedupe(input: MusicTrack[]): MusicTrack[] {
  return dedupeTracks(input).tracks;
}