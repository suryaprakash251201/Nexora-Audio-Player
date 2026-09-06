import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';

final databaseProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  /// Best-effort SQLite pragmas. Extracted for testability — see
  /// `test/unit/database_service_test.dart` (iOS `journal_mode` regression).
  static Future<void> configureDb(Database db) async {
    // PRAGMAs must never brick the database. On Apple platforms
    // (sqflite_darwin) a row-returning PRAGMA run via execute()
    // throws DatabaseException Code=0 "not an error", which used to
    // fail openDatabase entirely — breaking downloads, cache,
    // history, queue restore, favorites and the sync queue on
    // iOS/macOS. So every pragma here is best-effort with a logged
    // fallback to platform defaults.
    try {
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      AppLogger.cache('PRAGMA foreign_keys failed (non-fatal): $e');
    }
    try {
      // journal_mode RETURNS a row (wal/delete/memory), so it must be
      // queried, not executed — execute() throws on iOS/macOS.
      final mode = await db.rawQuery('PRAGMA journal_mode = WAL');
      final applied = mode.isNotEmpty
          ? mode.first.values.first.toString()
          : 'unknown';
      AppLogger.cache('SQLite journal mode: $applied');
    } catch (e) {
      AppLogger.cache(
        'WAL journal mode unavailable, using default (non-fatal): $e',
      );
    }
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nexora_audio.db');

    return await openDatabase(
      path,
      version: 2,
      onConfigure: configureDb,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tracks table (local cache)
    await db.execute('''
      CREATE TABLE tracks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration INTEGER,
        coverUrl TEXT,
        streamUrl TEXT,
        codec TEXT,
        bitrate INTEGER,
        sampleRate INTEGER,
        isDownloaded INTEGER DEFAULT 0,
        localPath TEXT,
        updatedAt INTEGER
      )
    ''');

    // Albums
    await db.execute('''
      CREATE TABLE albums (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT,
        coverUrl TEXT,
        year INTEGER,
        updatedAt INTEGER
      )
    ''');

    // Artists
    await db.execute('''
      CREATE TABLE artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        artworkUrl TEXT,
        updatedAt INTEGER
      )
    ''');

    // Playlists table
    await db.execute('''
      CREATE TABLE playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        coverUrl TEXT,
        updatedAt INTEGER
      )
    ''');

    // Playlist Items (Join table)
    await db.execute('''
      CREATE TABLE playlist_items (
        id TEXT PRIMARY KEY,
        playlistId TEXT NOT NULL,
        trackId TEXT NOT NULL,
        sortOrder INTEGER NOT NULL,
        FOREIGN KEY (playlistId) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (trackId) REFERENCES tracks (id) ON DELETE CASCADE
      )
    ''');

    // History
    await db.execute('''
      CREATE TABLE history (
        id TEXT PRIMARY KEY,
        songId TEXT NOT NULL,
        playedAt INTEGER NOT NULL,
        duration INTEGER,
        completion REAL
      )
    ''');

    // Favorites
    await db.execute('''
      CREATE TABLE favorites (
        songId TEXT PRIMARY KEY,
        addedAt INTEGER NOT NULL
      )
    ''');

    // Sync Operations Queue (Offline mutations)
    await db.execute('''
      CREATE TABLE sync_ops (
        id TEXT PRIMARY KEY,
        operationType TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT DEFAULT 'PENDING',
        createdAt INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');

    // Queue persistence
    await db.execute('''
      CREATE TABLE queue_state (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns/tables for v2
      try {
        await db.execute('ALTER TABLE tracks ADD COLUMN codec TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tracks ADD COLUMN bitrate INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE tracks ADD COLUMN sampleRate INTEGER');
      } catch (_) {}
      await db.execute('''
        CREATE TABLE IF NOT EXISTS albums (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          artist TEXT,
          coverUrl TEXT,
          year INTEGER,
          updatedAt INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS artists (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          artworkUrl TEXT,
          updatedAt INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS history (
          id TEXT PRIMARY KEY,
          songId TEXT NOT NULL,
          playedAt INTEGER NOT NULL,
          duration INTEGER,
          completion REAL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites (
          songId TEXT PRIMARY KEY,
          addedAt INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS queue_state (
          id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('tracks');
    await db.delete('albums');
    await db.delete('artists');
    await db.delete('playlists');
    await db.delete('playlist_items');
    await db.delete('history');
    await db.delete('favorites');
    await db.delete('sync_ops');
    await db.delete('queue_state');
  }
}
