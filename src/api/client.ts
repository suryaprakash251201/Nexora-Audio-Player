/**
 * Nexora API client for the audiophile mobile client.
 *
 * Vendored from upstream `mobile/src/api/client.ts` (which itself documents the
 * Bearer header + `?token=` media auth model) and re-typed against our
 * `MusicTrack` / `Playlist` shapes.
 *
 * The auth contract:
 *   POST /auth/login        → { user, token? , totp_required?, user_id? }
 *   POST /auth/totp/verify-login → { user, token }
 *   GET  /auth/session      → { user | null }
 * Media URLs accept `?token=` as a fallback when Bearer headers can't be set
 * (e.g. <img src=...> inside a WebView).
 */
import { Platform } from "react-native";
import type {
  AudioInfo,
  FileItem,
  Playlist,
  PlaylistMutationResponse,
  Root,
  SearchResponse,
  User,
  LyricsResponse,
} from "./types";

export class NexoraError extends Error {
  code: string;
  status: number;
  constructor(code: string, message: string, status = 0) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

interface RequestOptions {
  method?: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined>;
  isForm?: boolean;
  headers?: Record<string, string>;
}

function buildQuery(q?: RequestOptions["query"]): string {
  if (!q) return "";
  const out: string[] = [];
  for (const [k, v] of Object.entries(q)) {
    if (v !== undefined && v !== "" && v !== null) {
      out.push(`${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`);
    }
  }
  return out.length ? `?${out.join("&")}` : "";
}

let mediaBaseUrl = "";
let mediaToken: string | null = null;

export function syncMediaAuth(baseUrl: string, token: string | null) {
  const newBaseUrl = baseUrl.replace(/\/+$/, "");
  if (mediaBaseUrl && mediaBaseUrl !== newBaseUrl) {
    mediaToken = null;
  }
  mediaBaseUrl = newBaseUrl;
  if (token !== undefined) mediaToken = token;
}

export function mediaThumbnailUrl(rootId: string, path: string, size = 512): string {
  const q: Record<string, string | number | undefined> = { root: rootId, path, size };
  if (mediaToken) q.token = mediaToken;
  return `${mediaBaseUrl}/api/v1/files/thumbnail${buildQuery(q as Record<string, string | number | undefined>)}`;
}

export class Api {
  baseUrl: string;
  token: string | null;
  onUnauthorized?: () => void;

  constructor(baseUrl: string, token: string | null) {
    this.baseUrl = baseUrl.replace(/\/+$/, "");
    this.token = token;
    syncMediaAuth(baseUrl, token);
  }

  setToken(token: string | null) {
    this.token = token;
    syncMediaAuth(this.baseUrl, token);
  }

  setUnauthorizedHandler(handler: () => void) {
    this.onUnauthorized = handler;
  }

  mediaUrl(path: string, query?: Record<string, string | number | undefined>): string {
    const q: Record<string, string | number | undefined> = { ...query };
    if (this.token) q.token = this.token;
    return `${this.baseUrl}/api/v1${path}${buildQuery(q as Record<string, string | number | undefined>)}`;
  }

  rawFileUrl(rootId: string, path: string): string {
    return this.mediaUrl("/files/raw", { root: rootId, path });
  }

  transcodeUrl(
    rootId: string,
    path: string,
    opts?: { start?: number; session?: string; quality?: string; format?: string },
  ): string {
    return this.mediaUrl("/files/transcode", {
      root: rootId,
      path,
      start: opts?.start && opts.start > 0 ? opts.start : undefined,
      session: opts?.session,
      quality: opts?.quality || "medium",
      format: opts?.format,
    });
  }

  audioStreamUrl(
    rootId: string,
    path: string,
    opts?: { extension?: string; mime?: string; session?: string },
  ): Promise<string> {
    // Simple default: stream raw. The quality-detection + transcode routing
    // lives in `src/audio/streamRouter.ts` (it has more context than the
    // generic client should).
    return Promise.resolve(this.rawFileUrl(rootId, path));
  }

  thumbnailUrl(rootId: string, path: string, size = 512): string {
    return this.mediaUrl("/files/thumbnail", { root: rootId, path, size });
  }

  async request<T>(path: string, opts: RequestOptions = {}): Promise<T> {
    const method = opts.method || "GET";
    const headers: Record<string, string> = { ...opts.headers };
    let body: BodyInit | undefined;

    if (opts.isForm) {
      body = opts.body as FormData;
    } else if (opts.body !== undefined) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(opts.body);
    }
    if (this.token) headers["Authorization"] = `Bearer ${this.token}`;

    const res = await fetch(`${this.baseUrl}/api/v1${path}${buildQuery(opts.query)}`, {
      method,
      headers,
      body,
      signal: AbortSignal.timeout(15000),
    });

    if (res.status === 204) return undefined as T;

    const text = await res.text();
    let data: unknown = null;
    if (text) {
      try {
        data = JSON.parse(text);
      } catch {
        data = text;
      }
    }

    if (res.status === 401 && this.onUnauthorized) {
      this.onUnauthorized();
    }

    if (!res.ok) {
      const err = (data ?? {}) as { error?: string; message?: string };
      throw new NexoraError(err.error || "http_error", err.message || res.statusText, res.status);
    }
    return data as T;
  }

  get<T>(p: string, q?: RequestOptions["query"]) {
    return this.request<T>(p, { method: "GET", query: q });
  }
  post<T>(p: string, body?: unknown) {
    return this.request<T>(p, { method: "POST", body });
  }
  put<T>(p: string, body?: unknown) {
    return this.request<T>(p, { method: "PUT", body });
  }
  patch<T>(p: string, body?: unknown) {
    return this.request<T>(p, { method: "PATCH", body });
  }
  del<T>(p: string, q?: RequestOptions["query"]) {
    return this.request<T>(p, { method: "DELETE", query: q });
  }

  // ── Auth ────────────────────────────────────────────────────────────
  async checkNeedsSetup(): Promise<boolean> {
    try {
      const res = await this.get<{ configured: boolean }>("/auth/needs-setup");
      return !res.configured;
    } catch {
      return true;
    }
  }

  login(login: string, password: string): Promise<{ user: User; token?: string; totp_required?: boolean; user_id?: string }> {
    return this.post("/auth/login", { login, password });
  }

  verifyTotp(login: string, password: string, code: string): Promise<{ user: User; token: string }> {
    return this.post("/auth/totp/verify-login", { login, password, code });
  }

  session(): Promise<{ user: User | null }> {
    return this.get("/auth/session");
  }

  logout(): Promise<{ ok: boolean }> {
    return this.post("/auth/logout");
  }

  // ── Library ─────────────────────────────────────────────────────────
  listRoots(): Promise<{ roots: Root[] }> {
    return this.get("/roots");
  }

  listFiles(root: string, path: string, offset = 0, limit = 200) {
    return this.get<{ items: FileItem[]; total: number; offset: number; limit: number; has_more: boolean }>(
      "/files",
      { root, path, offset, limit },
    );
  }

  listRecents(limit = 50) {
    return this.get<{ items: FileItem[] }>("/recents", { limit });
  }

  search(q: string, opts?: { root?: string; kind?: string; sort?: string; limit?: number; offset?: number }) {
    return this.get<SearchResponse>("/search", { q, ...opts });
  }

  library(kind: string, limit = 200, offset = 0): Promise<SearchResponse> {
    return this.get("/search", { q: "", kind, sort: "newest", limit, offset });
  }

  stat(root: string, path: string): Promise<FileItem> {
    return this.get("/files/stat", { root, path });
  }

  // ── Audio metadata + lyrics ─────────────────────────────────────────
  audioInfo(root: string, path: string): Promise<AudioInfo> {
    return this.get("/audio/info", { root, path });
  }

  audioFormats(): Promise<{ ffmpeg: boolean; transcode: boolean; formats: string[] }> {
    return this.get("/audio/formats");
  }

  getLyrics(root: string, path: string): Promise<LyricsResponse> {
    return this.get("/audio/lyrics", { root, path });
  }

  async putLyrics(root: string, path: string, body: string): Promise<{ ok: boolean }> {
    const headers: Record<string, string> = { "Content-Type": "text/plain" };
    if (this.token) headers["Authorization"] = `Bearer ${this.token}`;
    const res = await fetch(`${this.baseUrl}/api/v1/audio/lyrics?root=${encodeURIComponent(root)}&path=${encodeURIComponent(path)}`, {
      method: "POST",
      headers,
      body,
    });
    if (!res.ok) {
      const txt = await res.text();
      throw new NexoraError("lyrics_write_failed", txt || res.statusText, res.status);
    }
    return { ok: true };
  }

  deleteLyrics(root: string, path: string): Promise<{ ok: boolean }> {
    return this.del("/audio/lyrics", { root, path });
  }

  // ── Transcode capability ────────────────────────────────────────────
  private transcodeSupport: boolean | null = null;
  async serverSupportsTranscode(): Promise<boolean> {
    if (this.transcodeSupport !== null) return this.transcodeSupport;
    try {
      const v = await this.get<{ transcode?: boolean; ffmpeg?: boolean }>("/version");
      this.transcodeSupport = !!(v.transcode || v.ffmpeg);
    } catch {
      this.transcodeSupport = false;
    }
    return this.transcodeSupport;
  }

  // ── Favorites ───────────────────────────────────────────────────────
  listFavorites(): Promise<{ items: { root_id: string; root_name: string; path: string; name: string; created_at: string }[] }> {
    return this.get("/favorites");
  }
  addFavorite(root: string, path: string): Promise<{ ok: boolean }> {
    return this.post("/favorites", { root, path });
  }
  removeFavorite(root: string, path: string): Promise<{ ok: boolean }> {
    return this.del("/favorites", { root, path });
  }

  // ── Playlists ───────────────────────────────────────────────────────
  listPlaylists(): Promise<{ items: Playlist[] }> {
    return this.get("/playlists");
  }
  createPlaylist(name: string, items?: { root_id: string; path: string }[], description?: string): Promise<Playlist> {
    return this.post("/playlists", { name, description: description || "", items: items || [] });
  }
  renamePlaylist(id: string, name: string): Promise<{ ok: boolean }> {
    return this.put(`/playlists/${id}`, { name });
  }
  patchPlaylist(id: string, body: { description?: string; is_public?: boolean; cover_root_id?: string; cover_path?: string }): Promise<{ ok: boolean }> {
    return this.patch(`/playlists/${id}`, body);
  }
  deletePlaylist(id: string): Promise<{ ok: boolean }> {
    return this.del(`/playlists/${id}`);
  }
  addPlaylistItems(id: string, items: { root_id: string; path: string }[]): Promise<PlaylistMutationResponse> {
    return this.post(`/playlists/${id}/items`, { items });
  }
  removePlaylistItem(id: string, itemId: string): Promise<{ ok: boolean }> {
    return this.del(`/playlists/${id}/items`, { item_id: itemId });
  }
  reorderPlaylistItems(id: string, itemIds: string[]): Promise<{ ok: boolean }> {
    return this.put(`/playlists/${id}/items/order`, { item_ids: itemIds });
  }
}

// Re-export platform info for callers that want it.
export const platformIsAndroid = Platform.OS === "android";
export const platformIsIOS = Platform.OS === "ios";