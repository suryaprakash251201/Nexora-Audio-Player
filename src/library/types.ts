/**
 * Unified music model.
 *
 * The brief is explicit: a single `MusicTrack` shape that represents any track
 * from any source (Nexora remote, device-local, or Nexora cached-for-offline),
 * deduplicated visually across sources.
 *
 * Source-distinguishing fields:
 *   - `source: "NEXORA_REMOTE" | "DEVICE_LOCAL" | "NEXORA_OFFLINE"`
 *   - `serverId: { rootId, path } | null` — only for Nexora-sourced tracks
 *   - `localId: string | null` — only for on-device tracks (expo-media-library
 *     asset id or our own download id)
 *   - `fingerprint` — stable hash used by the dedup pass (see
 *     `src/library/dedupe.ts`)
 */
import type { AudioCodec, AudioQualityInfo } from "@/audio/audioQuality";

export type MusicSource = "NEXORA_REMOTE" | "DEVICE_LOCAL" | "NEXORA_OFFLINE";

export type DownloadState = "REMOTE" | "DOWNLOADING" | "AVAILABLE_OFFLINE" | "FAILED";

export interface ServerId {
  rootId: string;
  path: string;
}

export interface LocalId {
  /** expo-media-library asset id, or `download:<uuid>` for cached tracks. */
  value: string;
}

export interface AudioMetadata {
  /** All values may be `null` when we haven't run ffprobe yet. */
  codec: AudioCodec | string | null;
  bitDepth: number | null;
  sampleRateHz: number | null;
  channels: number | null;
  bitrateKbps: number | null;
  durationSec: number | null;
  /** Calculated display quality (may be heuristic). */
  quality: AudioQualityInfo | null;
  /** ReplayGain tags read from /audio/info when available. */
  replayGainTrackDb: number | null;
  replayGainAlbumDb: number | null;
  /** ID3 tags when the server returned them. */
  tags: Record<string, string>;
}

export interface MusicTrack {
  /** Stable hash used for dedup across sources (see `fingerprint.ts`). */
  id: string;
  source: MusicSource;

  serverId: ServerId | null;
  localId: LocalId | null;

  title: string;
  artist: string | null;
  album: string | null;
  albumArtist: string | null;
  genre: string | null;
  year: number | null;
  trackNumber: number | null;
  discNumber: number | null;

  metadata: AudioMetadata;

  /** Bytes. Always present for server tracks; may be null for device assets. */
  fileSize: number | null;

  /** For on-device tracks: the local file URI (`file://...`). */
  localUri: string | null;

  /** For server tracks: the resolved stream URL (raw or transcode). */
  streamUrl: string | null;

  artwork: { url: string | null; dominantColor: string | null };

  /** Filled by the Downloads module for tracks cached on the device. */
  download: {
    state: DownloadState;
    progress: number;
    errorMessage: string | null;
    localUri: string | null;
  };

  favorite: boolean;
  /** Last time the track was played (ISO). Null = never. */
  lastPlayedAt: string | null;
  /** How many times the track has completed playback locally. */
  playCount: number;

  /** Modified timestamp from the server, or device file mtime as ISO. */
  modifiedAt: string | null;
}

/** Build the MusicTrack.id from a server reference. */
export function serverTrackId(rootId: string, path: string): string {
  return `srv:${rootId}:${path}`;
}

/** Build the MusicTrack.id from a local device reference. */
export function localTrackId(localIdValue: string): string {
  return `loc:${localIdValue}`;
}

/** Stable identity used to compare two tracks across the dedup pass. */
export function trackServerKey(t: Pick<MusicTrack, "source" | "serverId">): string | null {
  if (t.source === "DEVICE_LOCAL" || !t.serverId) return null;
  return `${t.serverId.rootId}:${t.serverId.path}`;
}