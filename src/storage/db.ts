/**
 * Local SQLite cache and offline database.
 *
 * Why SQLite and not AsyncStorage:
 *   - Migrations (brief requires migration handling for schema changes).
 *   - Queryable joins (playlist_items by playlist_id, downloads by track_id).
 *   - Order of magnitude faster for the 10k+ track collections the brief
 *     explicitly calls out as a performance target.
 *
 * Schema is split into independent migrations. Each migration is a SQL
 * string applied inside a transaction; failure aborts the migration and the
 * boot sequence surfaces a recoverable error.
 *
 * IMPORTANT: never edit a migration after it has been applied to a user's
 * device. Add a new numbered file with the change. The schema_migrations table
 * records applied versions.
 */
import * as SQLite from "expo-sqlite";

export type Migration = {
  version: number;
  name: string;
  sql: string;
};

const MIGRATIONS: Migration[] = [
  {
    version: 1,
    name: "init_tracks_playlists_downloads",
    sql: `
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Unified track mirror (Nexora + on-device + offline cached)
      CREATE TABLE IF NOT EXISTS tracks (
        id TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        root_id TEXT,
        path TEXT,
        local_id TEXT,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        album_artist TEXT,
        genre TEXT,
        year INTEGER,
        track_number INTEGER,
        disc_number INTEGER,
        duration_sec REAL,
        codec TEXT,
        bit_depth INTEGER,
        sample_rate_hz INTEGER,
        channels INTEGER,
        bitrate_kbps INTEGER,
        file_size INTEGER,
        local_uri TEXT,
        stream_url TEXT,
        artwork_url TEXT,
        fingerprint TEXT,
        metadata_json TEXT,
        modified_at TEXT,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      CREATE INDEX IF NOT EXISTS idx_tracks_source ON tracks(source);
      CREATE INDEX IF NOT EXISTS idx_tracks_root ON tracks(root_id, path);
      CREATE INDEX IF NOT EXISTS idx_tracks_album ON tracks(album, album_artist);

      -- Playlists (mirror of server schema + client bookkeeping)
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        cover_root_id TEXT,
        cover_path TEXT,
        is_public INTEGER NOT NULL DEFAULT 0,
        server_updated_at TEXT,
        client_revision INTEGER NOT NULL DEFAULT 1,
        last_synced_at TEXT,
        is_local_only INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      CREATE TABLE IF NOT EXISTS playlist_items (
        id TEXT PRIMARY KEY,
        playlist_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        position INTEGER NOT NULL,
        added_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      );
      CREATE INDEX IF NOT EXISTS idx_playlist_items_playlist ON playlist_items(playlist_id, position);

      -- Sync operation log (pending changes)
      CREATE TABLE IF NOT EXISTS sync_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_attempt_at TEXT NOT NULL DEFAULT (datetime('now'))
      );
      CREATE INDEX IF NOT EXISTS idx_sync_ops_next ON sync_ops(next_attempt_at);

      -- Offline downloads
      CREATE TABLE IF NOT EXISTS downloads (
        track_id TEXT PRIMARY KEY,
        state TEXT NOT NULL,
        progress REAL NOT NULL DEFAULT 0,
        local_uri TEXT,
        bytes_total INTEGER,
        bytes_received INTEGER NOT NULL DEFAULT 0,
        error_message TEXT,
        started_at TEXT,
        completed_at TEXT
      );
      CREATE INDEX IF NOT EXISTS idx_downloads_state ON downloads(state);

      -- Favorites (mirror)
      CREATE TABLE IF NOT EXISTS favorites (
        track_id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- ReplayGain / EQ / DSP state
      CREATE TABLE IF NOT EXISTS dsp_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- EQ presets
      CREATE TABLE IF NOT EXISTS eq_presets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        gains_json TEXT NOT NULL,
        preamp REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0,
        crossfeed REAL NOT NULL DEFAULT 0,
        stereo_width REAL NOT NULL DEFAULT 1.0,
        limiter_enabled INTEGER NOT NULL DEFAULT 0,
        replay_gain_mode TEXT NOT NULL DEFAULT 'off',
        is_built_in INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      );

      -- Play history (per-track counts; recents mirror)
      CREATE TABLE IF NOT EXISTS play_history (
        track_id TEXT PRIMARY KEY,
        last_played_at TEXT NOT NULL DEFAULT (datetime('now')),
        play_count INTEGER NOT NULL DEFAULT 1,
        completed_count INTEGER NOT NULL DEFAULT 0
      );
    `,
  },
];

const DB_NAME = "nexora_audio.db";

let dbInstance: SQLite.SQLiteDatabase | null = null;
let initPromise: Promise<SQLite.SQLiteDatabase> | null = null;

export async function openDb(): Promise<SQLite.SQLiteDatabase> {
  if (dbInstance) return dbInstance;
  if (!initPromise) {
    initPromise = (async () => {
      const db = await SQLite.openDatabaseAsync(DB_NAME);
      await applyMigrations(db);
      dbInstance = db;
      return db;
    })();
  }
  return initPromise;
}

async function applyMigrations(db: SQLite.SQLiteDatabase): Promise<void> {
  await db.execAsync(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
  const rows = await db.getAllAsync<{ version: number }>(`SELECT version FROM schema_migrations`);
  const applied = new Set(rows.map((r) => r.version));
  for (const m of MIGRATIONS) {
    if (applied.has(m.version)) continue;
    try {
      await db.execAsync("BEGIN");
      await db.execAsync(m.sql);
      await db.runAsync("INSERT INTO schema_migrations (version) VALUES (?)", m.version);
      await db.execAsync("COMMIT");
    } catch (err) {
      await db.execAsync("ROLLBACK").catch(() => {});
      throw new Error(`Migration ${m.version} (${m.name}) failed: ${err}`);
    }
  }
}

/** Reset the DB connection. Tests use this; production should not need it. */
export async function _resetForTests() {
  if (dbInstance) {
    await dbInstance.closeAsync().catch(() => {});
  }
  dbInstance = null;
  initPromise = null;
}