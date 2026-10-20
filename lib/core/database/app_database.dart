/// File: app_database.dart
/// Description: Central SQLite database manager for Project Anima. Configures schemas,
/// B-Tree indices for zero-jank queries, and provides cross-platform initialization (Android & Linux).
///
/// Components / Classes / Functions:
/// - AppDatabase: Singleton database manager maintaining connection lifecycle and migrations.
library;

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Central database provider and schema manager for Project Anima.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();

  AppDatabase._internal();

  factory AppDatabase() => instance;

  static const String databaseName = 'anima_music.db';
  static const int databaseVersion = 1;

  Database? _db;

  /// Retrieves the active SQLite database connection, opening it if necessary.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await initDatabase();
    return _db!;
  }

  /// Ensures FFI bindings are active when running on desktop or test environments.
  static void initializeFfiIfNeeded() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Initializes the SQLite database file and executes table/index creation.
  Future<Database> initDatabase({String? customPath}) async {
    initializeFfiIfNeeded();

    final String path;
    if (customPath != null) {
      path = customPath;
    } else {
      final dbFolder = await getDatabasesPath();
      path = join(dbFolder, databaseName);
    }

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Enables foreign key constraints and WAL mode where supported.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
    } catch (_) {
      // In-memory or specific platforms may ignore WAL
    }
  }

  /// Creates tables and mandatory B-Tree indices according to architectural specs.
  Future<void> _onCreate(Database db, int version) async {
    // 1. Table: songs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_store_id INTEGER UNIQUE,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        album_id INTEGER,
        duration INTEGER,
        path TEXT NOT NULL,
        date_modified INTEGER,
        date_added INTEGER,
        size INTEGER
      )
    ''');

    // 2. Table: playback_history
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playback_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER,
        artist TEXT,
        played_at INTEGER NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
      )
    ''');

    // 3. Mandatory B-Tree Indices for zero-jank retrieval
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_artist ON songs (artist COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_album ON songs (album COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_title ON songs (title COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_date_modified ON songs (date_modified DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_media_store_id ON songs (media_store_id)',
    );

    // Indices for playback history
    // Indices for playback history
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_history_played_at ON playback_history (played_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_history_artist ON playback_history (artist COLLATE NOCASE)',
    );
  }

  /// Closes the database connection if open.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
