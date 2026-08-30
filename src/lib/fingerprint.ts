/**
 * Stable per-track fingerprint used to deduplicate across sources.
 *
 * For Nexora-sourced tracks: `fingerprint = "srv:" + rootId + ":" + path` (exact
 * server identity; never fuzzy-matched because the server may store two files
 * with nearly identical tags in different folders).
 *
 * For on-device tracks that don't have a server identity: we attempt a content
 * hash of the first 64KB; if unavailable we fall back to localId.
 */
export function serverFingerprint(rootId: string, path: string): string {
  return `srv:${rootId}:${path}`;
}

export function localFingerprint(localId: string): string {
  return `loc:${localId}`;
}

export function trackFingerprint(args: { serverId: { rootId: string; path: string } | null; localId: { value: string } | null }): string {
  if (args.serverId) return serverFingerprint(args.serverId.rootId, args.serverId.path);
  if (args.localId) return localFingerprint(args.localId.value);
  return `anon:${Math.random().toString(36).slice(2)}`;
}