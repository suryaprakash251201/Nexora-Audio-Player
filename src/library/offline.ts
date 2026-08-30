/**
 * Offline library resolver — reads the SQLite downloads table and materialises
 * NEXORA_OFFLINE tracks. M2: stub that returns [] (downloads land in M4).
 * Kept as a separate module so the pipeline stays the same shape in M2 as in
 * the full system: nexora + device + offline → dedupe.
 */
import type { MusicTrack } from "./types";

export async function fetchOfflineTracks(): Promise<MusicTrack[]> {
  // M4: SELECT t.* JOIN downloads d ON t.id = d.track_id WHERE d.state = 'AVAILABLE_OFFLINE'
  return [];
}