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
      version: 1,
      onConfigure: (db) async {
        // Essential for offline durability and performance
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
      onCreate: _onCreate,
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
        isDownloaded INTEGER DEFAULT 0,
        localPath TEXT,
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

    // Sync Operations Queue (Offline mutations)
    await db.execute('''
      CREATE TABLE sync_ops (
        id TEXT PRIMARY KEY,
        operationType TEXT NOT NULL, -- e.g., 'ADD_TO_PLAYLIST', 'CREATE_PLAYLIST'
        payload TEXT NOT NULL,       -- JSON string of the operation data
        status TEXT DEFAULT 'PENDING',
        createdAt INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');
  }
}
