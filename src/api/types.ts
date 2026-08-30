/**
 * API DTOs that mirror the upstream Nexora server. Kept as a separate file so
 * we can add audiophile-specific extensions without breaking the upstream
 * `Playlist`/`FileItem` shapes.
 */

export interface Tag {
  id: string;
  name: string;
  color: string;
}

export interface FileItem {
  name: string;
  path: string;
  size: number;
  is_dir: boolean;
  modified: string;
  mime: string;
  root_id: string;
  extension: string;
  tags?: Tag[];
}

export interface Root {
  id: string;
  name: string;
  icon?: string;
  path: string;
  type: string;
  read_only: boolean;
  enabled: boolean;
  permission: string;
}

export interface User {
  id: string;
  username: string;
  email?: string;
  role: string;
  display_name?: string;
  totp_enabled?: boolean;
  created_at?: string;
}

export interface SearchResult {
  id: string;
  name: string;
  path: string;
  size: number;
  is_dir: boolean;
  modified: string;
  mime: string;
  root_id: string;
  extension: string;
  score?: number;
}

export interface SearchResponse {
  items: SearchResult[];
  has_more: boolean;
}

export interface PlaylistItem {
  id: string;
  playlist_id: string;
  root_id: string;
  path: string;
  created_at: string;
  position?: number;
  name: string;
  extension: string;
  mime: string;
  size: number;
  modified: string;
}

export interface Playlist {
  id: string;
  name: string;
  description?: string;
  cover_root_id: string;
  cover_path: string;
  is_public: boolean;
  created_at: string;
  updated_at: string;
  items: PlaylistItem[];
}

export interface PlaylistMutationResponse {
  ok: boolean;
  added?: number;
  skipped?: number;
}

export interface AudioInfo {
  codec: string;
  codec_long: string;
  sample_rate: number;
  bit_depth: number;
  channels: number;
  channel_layout: string;
  bit_rate: number;
  duration: number;
  format: string;
  tags: Record<string, string>;
  lossless: boolean;
}

export interface LyricCue {
  time: number;
  text: string;
}

export interface LyricsResponse {
  has_lyrics: boolean;
  raw: string;
  format: "lrc" | "plain";
  source: "auto" | "user" | "";
  synced: boolean;
  meta: {
    title?: string;
    artist?: string;
    album?: string;
    offset?: number;
  };
  cues: LyricCue[];
}

export interface ApiError {
  error: string;
  message: string;
}