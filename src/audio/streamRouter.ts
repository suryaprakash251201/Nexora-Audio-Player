/**
 * Stream router.
 *
 * Decides whether a track should be streamed raw or transcoded server-side,
 * using the same rules upstream Nexora uses:
 *   - Server-supplied codec (from `/audio/info`) is authoritative.
 *   - ALAC, WMA, DSD, APE, WV, TTA, OGG, OPUS must transcode.
 *   - Lossless sources → lossless FLAC transcode (so hi-res is preserved).
 *   - Lossy sources → high-quality AAC.
 *   - On Android < 11, fall back to AAC because the platform FLAC decoder
 *     isn't guaranteed.
 *
 * The decision is pure and synchronous once the `info` is available; the only
 * async work is the server-side ffprobe call, which the caller can debounce
 * via the cache in `audioInfoCache.ts`.
 */
import { Api } from "@/api/client";
import {
  androidBelow11,
  detectAudioQuality,
  needsAudioTranscode,
} from "./audioQuality";

const LOSSY_NATIVE_CODECS = new Set([
  "aac", "mp3", "vorbis", "opus", "mp2", "ac3", "eac3",
]);

export type StreamQualityPref = "auto" | "lossless" | "high";

export interface ResolveOpts {
  extension?: string;
  mime?: string;
  size?: number;
  session?: string;
  quality?: StreamQualityPref;
  realCodec?: string | null;
  serverSupportsTranscode?: boolean;
}

/**
 * Pick the stream URL for a (rootId, path) audio file.
 *
 * Returns the URL string. Callers are expected to cache by the same identity
 * (rootId+path+session).
 */
export async function resolveStreamUrl(
  api: Api,
  rootId: string,
  path: string,
  opts: ResolveOpts = {},
): Promise<string> {
  const ext = opts.extension;
  const mime = opts.mime;

  // Ambiguous container probe only when we don't already have a codec.
  let realCodec = opts.realCodec ?? undefined;
  if (!realCodec && isAmbiguousContainer(ext, mime)) {
    try {
      const info = await api.audioInfo(rootId, path);
      realCodec = info?.codec;
    } catch {
      realCodec = undefined;
    }
  }

  const sizeForDetection = androidBelow11() ? opts.size : undefined;
  const quality = detectAudioQuality(ext || "", mime || "", sizeForDetection);
  const needs = needsAudioTranscode(ext, mime, sizeForDetection, realCodec);

  if (!needs) return api.rawFileUrl(rootId, path);

  const supports = opts.serverSupportsTranscode ?? (await api.serverSupportsTranscode());
  if (!supports) return api.rawFileUrl(rootId, path); // onError will surface it

  const session = opts.session || makeSessionId();
  const pref = opts.quality || "auto";
  const losslessSource =
    quality.isLossless || (realCodec ? !LOSSY_NATIVE_CODECS.has(realCodec.toLowerCase()) : false);

  if (losslessSource || pref === "lossless") {
    if (androidBelow11()) {
      return api.transcodeUrl(rootId, path, { session, quality: "high" });
    }
    return api.transcodeUrl(rootId, path, { session, format: "flac" });
  }
  return api.transcodeUrl(rootId, path, { session, quality: "high" });
}

function isAmbiguousContainer(extension?: string, mime?: string): boolean {
  const ext = (extension || "").toLowerCase().replace(/^\./, "");
  if (ext === "m4a" || ext === "m4b" || ext === "m4p") return true;
  const m = (mime || "").toLowerCase();
  return m === "audio/mp4" || m === "audio/x-m4a" || m === "audio/m4a";
}

function makeSessionId(): string {
  const g: any = (globalThis as any)?.crypto;
  if (g?.randomUUID) return g.randomUUID();
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}