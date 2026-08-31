/**
 * Offline library resolver — reads downloads that completed successfully and
 * materialises NEXORA_OFFLINE MusicTracks. The actual bytes live under
 * `FileSystem.documentDirectory/nexora_offline/`; this resolver only maps the
 * SQLite rows so the Library pipeline can dedupe correctly (offline wins).
 *
 * For M4 we don't yet parse ffprobe for offline files — we reuse the server
 * track's metadata cached in the `tracks` table when available, falling back
 * to a minimal file-based track.
 */
import { openDb } from "@/storage/db";
import type { MusicTrack } from "./types";
import { mediaThumbnailUrl } from "@/api/client";
import * as FileSystem from "expo-file-system";

export async function fetchOfflineTracks(): Promise<MusicTrack[]> {
  const db = await openDb();
  // Join downloads → tracks when the track mirror exists; otherwise synthesize
  const rows = await db.getAllAsync<any>(`
    SELECT d.track_id, d.local_uri, d.state,
           t.title, t.artist, t.album, t.album_artist, t.genre, t.year, t.track_number, t.disc_number,
           t.root_id, t.path, t.file_size, t.duration_sec, t.codec, t.bit_depth, t.sample_rate_hz, t.channels, t.bitrate_kbps, t.modified_at, t.artwork_url
    FROM downloads d
    LEFT JOIN tracks t ON t.id = d.track_id
    WHERE d.state = 'AVAILABLE_OFFLINE'
  `);

  const out: MusicTrack[] = [];
  for (const r of rows) {
    // Parse root_id:path from track_id when the tracks row is missing
    let rootId = r.root_id as string | null;
    let path = r.path as string | null;
    if (!rootId || !path) {
      const raw = String(r.track_id).replace(/^srv:/, "");
      const sep = raw.indexOf(":");
      if (sep >= 0) { rootId = raw.slice(0, sep); path = raw.slice(sep + 1); }
    }
    if (!rootId || !path) continue;

    const title = r.title || path.split("/").pop()?.replace(/\.[a-z0-9]+$/i, "") || "Unknown";
    out.push({
      id: r.track_id,
      source: "NEXORA_OFFLINE",
      serverId: { rootId, path },
      localId: null,
      title,
      artist: r.artist ?? null,
      album: r.album ?? null,
      albumArtist: r.album_artist ?? null,
      genre: r.genre ?? null,
      year: r.year ?? null,
      trackNumber: r.track_number ?? null,
      discNumber: r.disc_number ?? null,
      metadata: {
        codec: r.codec ?? null,
        bitDepth: r.bit_depth ?? null,
        sampleRateHz: r.sample_rate_hz ?? null,
        channels: r.channels ?? null,
        bitrateKbps: r.bitrate_kbps ?? null,
        durationSec: r.duration_sec ?? null,
        quality: null,
        replayGainTrackDb: null,
        replayGainAlbumDb: null,
        tags: {},
      },
      fileSize: r.file_size ?? null,
      localUri: r.local_uri ? (r.local_uri.startsWith("file://") ? r.local_uri : `${(FileSystem as any).documentDirectory}${r.local_uri}`) : null,
      streamUrl: r.local_uri ? (r.local_uri.startsWith("file://") ? r.local_uri : `${(FileSystem as any).documentDirectory}${r.local_uri}`) : null,
      artwork: { url: r.artwork_url || mediaThumbnailUrl(rootId, path, 512), dominantColor: null },
      download: { state: "AVAILABLE_OFFLINE", progress: 1, errorMessage: null, localUri: r.local_uri ? (r.local_uri.startsWith("file://") ? r.local_uri : `${(FileSystem as any).documentDirectory}${r.local_uri}`) : null },
      favorite: false,
      lastPlayedAt: null,
      playCount: 0,
      modifiedAt: r.modified_at ?? null,
    });
  }
  return out;
}
