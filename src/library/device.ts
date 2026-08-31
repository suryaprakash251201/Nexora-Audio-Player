/**
 * Device-local library resolver (iOS + Android).
 *
 * Uses `expo-media-library`. The OS permission model differs:
 *  - iOS: one `mediaLibrary` permission gates all audio.
 *  - Android 13+: `READ_MEDIA_AUDIO`; Android 12 and below: `READ_EXTERNAL_STORAGE`
 *    (both mapped to the same MediaLibrary permission by Expo).
 *
 * We never attempt to bypass permissions. If denied, we return an empty list
 * and the UI shows the system settings prompt.
 */
import * as MediaLibrary from "expo-media-library";
import { Platform } from "react-native";
import type { MusicTrack } from "./types";
import { mapDeviceAssetToTrack } from "./mapper";

export type DevicePermissionState = "undetermined" | "granted" | "denied" | "blocked";

export async function getDevicePermission(): Promise<DevicePermissionState> {
  const { status, canAskAgain } = await MediaLibrary.getPermissionsAsync();
  if (status === "granted") return "granted";
  if (status === "denied" && !canAskAgain) return "blocked";
  if (status === "denied") return "denied";
  return "undetermined";
}

export async function requestDevicePermission(): Promise<DevicePermissionState> {
  const { status, canAskAgain } = await MediaLibrary.requestPermissionsAsync();
  if (status === "granted") return "granted";
  if (status === "denied" && !canAskAgain) return "blocked";
  if (status === "denied") return "denied";
  return "undetermined";
}

const AUDIO_EXTS = new Set(["mp3", "m4a", "m4b", "aac", "flac", "wav", "aiff", "aif", "ogg", "oga", "opus", "wma", "alac", "ape", "wv", "dsf", "dff"]);
function isAudioFilename(name: string): boolean {
  const ext = name.split(".").pop()?.toLowerCase() ?? "";
  return AUDIO_EXTS.has(ext);
}

export interface FetchDeviceOptions {
  limit?: number;
  signal?: AbortSignal;
}

/**
 * Scan on-device audio. Returns an empty list when:
 *  - permission is not granted,
 *  - the platform is web (MediaLibrary is native-only), or
 *  - the scan was aborted.
 */
export async function fetchDeviceTracks(opts: FetchDeviceOptions = {}): Promise<MusicTrack[]> {
  if (Platform.OS === "web") return [];
  const perm = await getDevicePermission();
  if (perm !== "granted") return [];

  const limit = Math.min(opts.limit ?? 4000, 10000);
  const out: MusicTrack[] = [];
  let after: string | undefined;
  let hasNextPage = true;

  while (hasNextPage && out.length < limit) {
    if (opts.signal?.aborted) {
      const err = new Error("Aborted");
      err.name = "AbortError";
      throw err;
    }
    const pageSize = Math.min(200, limit - out.length);
    const page = await MediaLibrary.getAssetsAsync({
      mediaType: ["audio"],
      first: pageSize,
      after,
      sortBy: ["creationTime"],
    });

    const BATCH_SIZE = 12;
    for (let i = 0; i < page.assets.length; i += BATCH_SIZE) {
      if (opts.signal?.aborted) {
      const err = new Error("Aborted");
      err.name = "AbortError";
      throw err;
    }
      const batch = page.assets.slice(i, i + BATCH_SIZE);
      
      const processedBatch = await Promise.all(batch.map(async (a) => {
        if (!isAudioFilename(a.filename)) return null;
        let fileUri: string = a.uri;
        if (Platform.OS === "ios" && a.uri.startsWith("ph://")) {
          try {
            const info = await MediaLibrary.getAssetInfoAsync(a as any);
            const local = (info as any)?.localUri as string | undefined;
            if (local && local.startsWith("file://")) fileUri = local;
            else if ((info as any)?.uri && String((info as any).uri).startsWith("file://")) fileUri = (info as any).uri;
          } catch {
            return null;
          }
          if (fileUri.startsWith("ph://")) return null;
        }
        return mapDeviceAssetToTrack({
          id: a.id,
          filename: a.filename,
          uri: fileUri,
          duration: (a as any).duration ?? 0,
          creationTime: a.creationTime,
          modificationTime: a.modificationTime,
          mediaType: "audio",
          albumId: (a as any).albumId,
        });
      }));
      
      for (const track of processedBatch) {
        if (track) out.push(track);
        if (out.length >= limit) break;
      }
      if (out.length >= limit) break;
    }

    hasNextPage = page.hasNextPage;
    after = page.endCursor;
    if (!hasNextPage) break;
    if (!page.assets.length) break;
    if (hasNextPage && !after) break;
  }

  return out;
}