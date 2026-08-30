/**
 * FileItem / SearchResult → MusicTrack mapper.
 *
 * Keeps the mapping pure so it can be unit-tested without touching the network
 * or the device library. Audio-quality detection is heuristic until
 * `/audio/info` returns real ffprobe data (enriched later via `enrichWithInfo`).
 */
import type { FileItem, SearchResult, AudioInfo } from "@/api/types";
import type { MusicTrack } from "./types";
import { serverTrackId, localTrackId } from "./types";
import { detectAudioQuality } from "@/audio/audioQuality";
import { cleanTrackTitle, parseArtistTitle } from "@/lib/cleanTitle";
import { mediaThumbnailUrl } from "@/api/client";

function pickTitle(name: string, tags?: Record<string, string>): string {
  // Prefer embedded title tag when present and non-empty
  const t = tags?.title || tags?.TITLE || tags?.Title;
  if (t && t.trim()) return t.trim();
  return cleanTrackTitle(name);
}

function pickArtist(name: string, tags?: Record<string, string>): string | null {
  const a = tags?.artist || tags?.ARTIST || tags?.album_artist || tags?.AlbumArtist;
  if (a && a.trim()) return a.trim();
  return parseArtistTitle(name).artist;
}

/** Map a server file (FileItem or SearchResult) to a unified MusicTrack. */
export function mapServerItemToTrack(
  item: FileItem | SearchResult & Partial<FileItem>,
  opts?: { favorite?: boolean },
): MusicTrack {
  const name = (item as any).name as string;
  const path = (item as any).path as string;
  const rootId = (item as any).root_id as string;
  const ext = ((item as any).extension as string | undefined) || path.split(".").pop() || "";
  const mime = (item as any).mime as string | undefined;
  const size = (item as any).size as number | undefined;
  const modified = (item as any).modified as string | undefined;

  const q = detectAudioQuality(ext, mime, size ?? undefined);

  // Tags will be filled later after /audio/info enrichment; for now empty.
  const title = pickTitle(name, undefined);
  const artist = pickArtist(name, undefined);

  return {
    id: serverTrackId(rootId, path),
    source: "NEXORA_REMOTE",
    serverId: { rootId, path },
    localId: null,
    title,
    artist,
    album: null,
    albumArtist: null,
    genre: null,
    year: null,
    trackNumber: null,
    discNumber: null,
    metadata: {
      codec: q.codec,
      bitDepth: q.bitDepth,
      sampleRateHz: q.sampleRateKHz != null ? Math.round(q.sampleRateKHz * 1000) : null,
      channels: q.channels,
      bitrateKbps: q.bitrateKbps,
      durationSec: null,
      quality: q,
      replayGainTrackDb: null,
      replayGainAlbumDb: null,
      tags: {},
    },
    fileSize: size ?? null,
    localUri: null,
    streamUrl: null,
    artwork: {
      url: mediaThumbnailUrl(rootId, path, 512),
      dominantColor: null,
    },
    download: { state: "REMOTE", progress: 0, errorMessage: null, localUri: null },
    favorite: !!opts?.favorite,
    lastPlayedAt: null,
    playCount: 0,
    modifiedAt: modified ?? null,
  };
}

/** Enrich a mapped track with real ffprobe `AudioInfo` when available. */
export function enrichWithAudioInfo(track: MusicTrack, info: AudioInfo): MusicTrack {
  const tags = info.tags || {};
  const q = detectAudioQuality(track.serverId?.path.split(".").pop() || "", undefined, track.fileSize ?? undefined, info.duration || undefined, {
    bitDepth: info.bit_depth || undefined,
    sampleRateHz: info.sample_rate || undefined,
    channels: info.channels || undefined,
    bitrateKbps: info.bit_rate ? Math.round(info.bit_rate / 1000) : undefined,
  });

  // Try to read textual metadata from tags
  const titleFromTag = tags.title || tags.TITLE || tags.Title;
  const artistFromTag = tags.artist || tags.ARTIST || tags.Artist;
  const albumFromTag = tags.album || tags.ALBUM || tags.Album;
  const albumArtistFromTag = tags.album_artist || tags.ALBUMARTIST || tags.AlbumArtist;
  const genreFromTag = tags.genre || tags.GENRE || tags.Genre;
  const yearRaw = tags.date || tags.DATE || tags.year || tags.YEAR;
  const trackRaw = tags.track || tags.TRACK || tags.tracknumber || tags.TRACKNUMBER;
  const discRaw = tags.disc || tags.DISC || tags.discnumber || tags.DISCNUMBER;

  const rgTrack = tags.REPLAYGAIN_TRACK_GAIN || tags.replaygain_track_gain;
  const rgAlbum = tags.REPLAYGAIN_ALBUM_GAIN || tags.replaygain_album_gain;

  return {
    ...track,
    title: titleFromTag?.trim() ? titleFromTag.trim() : track.title,
    artist: artistFromTag?.trim() ? artistFromTag.trim() : track.artist,
    album: albumFromTag?.trim() ? albumFromTag.trim() : null,
    albumArtist: albumArtistFromTag?.trim() ? albumArtistFromTag.trim() : null,
    genre: genreFromTag?.trim() ? genreFromTag.trim() : null,
    year: yearRaw ? parseInt(String(yearRaw).slice(0, 4), 10) || null : null,
    trackNumber: trackRaw ? parseInt(String(trackRaw).split("/")[0], 10) || null : null,
    discNumber: discRaw ? parseInt(String(discRaw).split("/")[0], 10) || null : null,
    metadata: {
      codec: info.codec || track.metadata.codec,
      bitDepth: info.bit_depth || track.metadata.bitDepth,
      sampleRateHz: info.sample_rate || track.metadata.sampleRateHz,
      channels: info.channels || track.metadata.channels,
      bitrateKbps: info.bit_rate ? Math.round(info.bit_rate / 1000) : track.metadata.bitrateKbps,
      durationSec: info.duration || track.metadata.durationSec,
      quality: q,
      replayGainTrackDb: rgTrack ? parseFloat(String(rgTrack).replace(" dB", "")) || null : null,
      replayGainAlbumDb: rgAlbum ? parseFloat(String(rgAlbum).replace(" dB", "")) || null : null,
      tags,
    },
  };
}

/** Map a device MediaLibrary asset to a unified MusicTrack. */
export function mapDeviceAssetToTrack(asset: {
  id: string;
  filename: string;
  uri: string;
  duration: number;
  creationTime: number;
  modificationTime?: number;
  mediaType?: string;
  albumId?: string;
}): MusicTrack {
  const ext = asset.filename.split(".").pop() || "";
  const q = detectAudioQuality(ext, undefined, undefined, asset.duration || undefined);
  const { artist, title } = parseArtistTitle(asset.filename);
  return {
    id: localTrackId(asset.id),
    source: "DEVICE_LOCAL",
    serverId: null,
    localId: { value: asset.id },
    title,
    artist,
    album: null,
    albumArtist: null,
    genre: null,
    year: null,
    trackNumber: null,
    discNumber: null,
    metadata: {
      codec: q.codec,
      bitDepth: q.bitDepth,
      sampleRateHz: q.sampleRateKHz != null ? Math.round(q.sampleRateKHz * 1000) : null,
      channels: q.channels,
      bitrateKbps: q.bitrateKbps,
      durationSec: asset.duration || null,
      quality: q,
      replayGainTrackDb: null,
      replayGainAlbumDb: null,
      tags: {},
    },
    fileSize: null,
    localUri: asset.uri,
    streamUrl: asset.uri,
    artwork: { url: null, dominantColor: null },
    download: { state: "AVAILABLE_OFFLINE", progress: 1, errorMessage: null, localUri: asset.uri },
    favorite: false,
    lastPlayedAt: null,
    playCount: 0,
    modifiedAt: asset.modificationTime ? new Date(asset.modificationTime).toISOString() : new Date(asset.creationTime).toISOString(),
  };
}