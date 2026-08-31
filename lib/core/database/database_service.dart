import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nexora_audio.db');

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
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
