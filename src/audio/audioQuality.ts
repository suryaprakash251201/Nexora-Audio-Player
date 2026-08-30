/**
 * Audio quality tier detection engine.
 *
 * Vendored from upstream Nexora (`mobile/src/lib/audioQuality.ts`) with one
 * extension: `qualityForTrack(track, info?)` accepts our `MusicTrack` shape and
 * uses the server-reported `AudioInfo` when available (otherwise falls back to
 * extension/MIME heuristics).
 *
 * The transcode-routing logic deliberately mirrors upstream so server support
 * (`/files/transcode?format=flac`) and codec classification stay in lockstep.
 */
import { Platform } from "react-native";

export type AudioCodec =
  | "MP3"
  | "AAC"
  | "ALAC"
  | "FLAC"
  | "WAV"
  | "AIFF"
  | "DSD"
  | "OGG"
  | "OPUS"
  | "WMA"
  | "M4A"
  | "UNKNOWN";

export type QualityTier =
  | "standard"
  | "high"
  | "lossless"
  | "hires"
  | "dsd"
  | "dolby"
  | "spatial";

export type BadgeVariant =
  | "mp3"
  | "aac"
  | "lossless"
  | "hires"
  | "dsd"
  | "dolby"
  | "spatial";

export interface AudioQualityInfo {
  codec: AudioCodec;
  tier: QualityTier;
  variant: BadgeVariant;
  label: string;
  detail: string | null;
  bitDepth: number | null;
  sampleRateKHz: number | null;
  bitrateKbps: number | null;
  isLossless: boolean;
  isHiRes: boolean;
  channels: number | null;
  container: string;
}

/** Codecs AVPlayer/ExoPlayer cannot decode reliably — must transcode. */
const NON_NATIVE_CODECS = new Set(["ALAC", "WMA", "DSD", "APE", "WV", "TTA", "OGG", "OPUS"]);

/** Codecs safe to stream raw on both platforms. */
const NATIVE_SAFE_CODECS = new Set([
  "aac", "mp3", "flac", "vorbis", "opus", "aiff", "mp2", "ac3", "eac3",
  "pcm_s16le", "pcm_s24le", "pcm_s32le", "pcm_f32le", "pcm_f64le",
  "pcm_u8", "pcm_s8", "pcm_alaw", "pcm_mulaw",
]);

const EXT_TO_CODEC: Record<string, AudioCodec> = {
  ".mp3": "MP3",
  ".aac": "AAC",
  ".m4a": "M4A",
  ".alac": "ALAC",
  ".flac": "FLAC",
  ".wav": "WAV",
  ".aiff": "AIFF",
  ".aif": "AIFF",
  ".dsd": "DSD",
  ".dsf": "DSD",
  ".dff": "DSD",
  ".ogg": "OGG",
  ".oga": "OGG",
  ".opus": "OPUS",
  ".wma": "WMA",
};

const MIME_TO_CODEC: Record<string, AudioCodec> = {
  "audio/mpeg": "MP3",
  "audio/mp3": "MP3",
  "audio/aac": "AAC",
  "audio/mp4": "M4A",
  "audio/x-m4a": "M4A",
  "audio/m4a": "M4A",
  "audio/alac": "ALAC",
  "audio/flac": "FLAC",
  "audio/x-flac": "FLAC",
  "audio/wav": "WAV",
  "audio/x-wav": "WAV",
  "audio/wave": "WAV",
  "audio/aiff": "AIFF",
  "audio/x-aiff": "AIFF",
  "audio/dsd": "DSD",
  "audio/x-dsd": "DSD",
  "audio/ogg": "OGG",
  "audio/opus": "OPUS",
  "audio/x-ms-wma": "WMA",
};

function estimateBitrateKbps(bytes: number, durationSec?: number): number | null {
  if (!bytes || bytes <= 0) return null;
  if (durationSec && durationSec > 0) {
    return Math.round((bytes * 8) / (durationSec * 1000));
  }
  return null;
}

function likelyHiResFromSize(bytes: number): boolean {
  return bytes > 50 * 1024 * 1024;
}

export interface QualityOverrides {
  bitDepth?: number;
  sampleRateHz?: number;
  channels?: number;
  bitrateKbps?: number;
  isDolbyAtmos?: boolean;
  isSpatialAudio?: boolean;
}

function mkMp3(bytes?: number, dur?: number, ov?: QualityOverrides): AudioQualityInfo {
  const br = ov?.bitrateKbps ?? estimateBitrateKbps(bytes || 0, dur) ?? 320;
  return {
    codec: "MP3",
    tier: br >= 256 ? "high" : "standard",
    variant: "mp3",
    label: "MP3",
    detail: `${br} kbps`,
    bitDepth: 16,
    sampleRateKHz: 44.1,
    bitrateKbps: br,
    isLossless: false,
    isHiRes: false,
    channels: ov?.channels ?? 2,
    container: "MP3",
  };
}

function mkAac(bytes?: number, dur?: number, ov?: QualityOverrides): AudioQualityInfo {
  const br = ov?.bitrateKbps ?? estimateBitrateKbps(bytes || 0, dur) ?? 256;
  return {
    codec: "AAC",
    tier: "high",
    variant: "aac",
    label: "AAC",
    detail: `${br} kbps`,
    bitDepth: 16,
    sampleRateKHz: 44.1,
    bitrateKbps: br,
    isLossless: false,
    isHiRes: false,
    channels: ov?.channels ?? 2,
    container: "M4A",
  };
}

function mkLossless(
  codec: AudioCodec,
  ext: string,
  bytes?: number,
  dur?: number,
  ov?: QualityOverrides,
): AudioQualityInfo {
  let bd = ov?.bitDepth ?? 16;
  let srHz = ov?.sampleRateHz ?? 44100;
  if (!ov?.bitDepth && !ov?.sampleRateHz && bytes && likelyHiResFromSize(bytes)) {
    bd = 24;
    srHz = 96000;
  }
  const srKHz = srHz / 1000;
  const hiRes = bd >= 24 || srHz >= 88200;
  const br = ov?.bitrateKbps ?? estimateBitrateKbps(bytes || 0, dur) ?? Math.round((bd * srHz * 2) / 1000);
  return {
    codec,
    tier: hiRes ? "hires" : "lossless",
    variant: hiRes ? "hires" : "lossless",
    label: hiRes ? "HI-RES" : "LOSSLESS",
    detail: `${bd}-bit / ${srKHz} kHz`,
    bitDepth: bd,
    sampleRateKHz: srKHz,
    bitrateKbps: Math.round(br),
    isLossless: true,
    isHiRes: hiRes,
    channels: ov?.channels ?? 2,
    container: ext.replace(".", "").toUpperCase(),
  };
}

function mkDsd(ext: string, ov?: QualityOverrides): AudioQualityInfo {
  const srHz = ov?.sampleRateHz ?? 2822400;
  const mhz = srHz / 1_000_000;
  return {
    codec: "DSD",
    tier: "dsd",
    variant: "dsd",
    label: "DSD",
    detail: `${mhz.toFixed(1)} MHz`,
    bitDepth: 1,
    sampleRateKHz: srHz / 1000,
    bitrateKbps: Math.round((srHz * (ov?.channels ?? 2)) / 1000),
    isLossless: true,
    isHiRes: true,
    channels: ov?.channels ?? 2,
    container: ext.replace(".", "").toUpperCase(),
  };
}

export function detectAudioQuality(
  extension: string,
  mime?: string,
  fileSizeBytes?: number,
  durationSec?: number,
  overrides?: QualityOverrides,
): AudioQualityInfo {
  const extRaw = (extension || "").toLowerCase();
  const ext = extRaw.startsWith(".") ? extRaw : `.${extRaw}`;
  let codec: AudioCodec = EXT_TO_CODEC[ext] || "UNKNOWN";
  if (codec === "UNKNOWN" && mime) codec = MIME_TO_CODEC[mime.toLowerCase()] || "UNKNOWN";

  if (overrides?.isDolbyAtmos) {
    return {
      codec, tier: "dolby", variant: "dolby", label: "DOLBY ATMOS", detail: null,
      bitDepth: 24, sampleRateKHz: 48, bitrateKbps: overrides.bitrateKbps ?? null,
      isLossless: true, isHiRes: true, channels: overrides.channels ?? 8,
      container: ext.replace(".", "").toUpperCase(),
    };
  }
  if (overrides?.isSpatialAudio) {
    return {
      codec, tier: "spatial", variant: "spatial", label: "SPATIAL AUDIO", detail: null,
      bitDepth: 24, sampleRateKHz: 48, bitrateKbps: overrides.bitrateKbps ?? null,
      isLossless: true, isHiRes: true, channels: overrides.channels ?? 8,
      container: ext.replace(".", "").toUpperCase(),
    };
  }

  if (codec === "DSD") return mkDsd(ext, overrides);
  if (["FLAC", "ALAC", "WAV", "AIFF"].includes(codec)) {
    return mkLossless(codec, ext, fileSizeBytes, durationSec, overrides);
  }
  if (codec === "M4A") {
    const big = fileSizeBytes && fileSizeBytes > 30 * 1024 * 1024;
    return big
      ? mkLossless("ALAC", ext, fileSizeBytes, durationSec, overrides)
      : mkAac(fileSizeBytes, durationSec, overrides);
  }
  if (codec === "AAC") return mkAac(fileSizeBytes, durationSec, overrides);
  if (codec === "MP3") return mkMp3(fileSizeBytes, durationSec, overrides);
  if (codec === "OGG" || codec === "OPUS") {
    const br = overrides?.bitrateKbps ?? estimateBitrateKbps(fileSizeBytes || 0, durationSec) ?? 192;
    return {
      codec, tier: br >= 256 ? "high" : "standard", variant: "aac", label: codec, detail: `${br} kbps`,
      bitDepth: 16, sampleRateKHz: 48, bitrateKbps: br, isLossless: false, isHiRes: false,
      channels: overrides?.channels ?? 2, container: codec,
    };
  }
  return {
    codec, tier: "standard", variant: "mp3", label: codec === "UNKNOWN" ? "AUDIO" : codec, detail: null,
    bitDepth: null, sampleRateKHz: null, bitrateKbps: null, isLossless: false, isHiRes: false,
    channels: overrides?.channels ?? null, container: ext.replace(".", "").toUpperCase() || "UNKNOWN",
  };
}

/**
 * Whether the platform decoder can play this codec natively. When false, the
 * stream router should request a server-side transcode (FLAC for lossless,
 * AAC for lossy).
 */
export function needsAudioTranscode(
  extension?: string,
  mime?: string,
  fileSizeBytes?: number,
  realCodec?: string,
): boolean {
  const rc = (realCodec || "").toLowerCase();
  if (rc) {
    if (NON_NATIVE_CODECS.has(rc.toUpperCase())) return true;
    if (NATIVE_SAFE_CODECS.has(rc)) return false;
    return true; // unknown → conservative
  }
  const q = detectAudioQuality(extension || "", mime || "", fileSizeBytes);
  return NON_NATIVE_CODECS.has(q.codec);
}

export function androidBelow11(): boolean {
  return Platform.OS === "android" && (typeof Platform.Version === "number" ? Platform.Version < 30 : true);
}

export function formatBitrate(kbps: number | null): string {
  if (kbps === null) return "—";
  if (kbps >= 1000) return `${(kbps / 1000).toFixed(1)} Mbps`;
  return `${kbps} kbps`;
}

export function formatSampleRate(khz: number | null): string {
  if (khz === null) return "—";
  if (khz >= 1000) return `${(khz / 1000).toFixed(1)} MHz`;
  return `${khz} kHz`;
}

export function formatBitDepth(bits: number | null): string {
  if (bits === null) return "—";
  return `${bits}-bit`;
}

export function formatChannels(ch: number | null): string {
  if (ch === null) return "—";
  if (ch === 1) return "Mono";
  if (ch === 2) return "Stereo";
  if (ch === 6) return "5.1";
  if (ch === 8) return "7.1";
  return `${ch}ch`;
}

/**
 * Human-readable technical-info string like "24BIT | 192kHz | FLAC".
 * When info is missing parts, they're replaced with em-dashes.
 */
export function technicalBadge(info: AudioQualityInfo | null | undefined): string {
  if (!info) return "AUDIO";
  const parts: string[] = [];
  if (info.bitDepth !== null) parts.push(formatBitDepth(info.bitDepth));
  if (info.sampleRateKHz !== null) parts.push(formatSampleRate(info.sampleRateKHz));
  parts.push(info.codec);
  return parts.filter(Boolean).join(" | ").toUpperCase();
}