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
  static const int databaseVersion = 9;

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

    _db = await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
      onConfigure: _onConfigure,
    );
    return _db!;
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

  /// Handles schema migrations across versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE songs ADD COLUMN album_artist TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_songs_album_artist ON songs (album_artist COLLATE NOCASE)',
        );
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_metadata (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recent_searches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_key TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            representative_song_id INTEGER NOT NULL,
            album_id INTEGER,
            searched_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_recent_searches_searched_at ON recent_searches (searched_at DESC)',
        );
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS playback_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            song_media_store_id INTEGER,
            song_id INTEGER,
            position_ms INTEGER NOT NULL DEFAULT 0,
            queue_media_store_ids TEXT,
            current_index INTEGER NOT NULL DEFAULT 0,
            shuffle_enabled INTEGER NOT NULL DEFAULT 0,
            loop_mode TEXT NOT NULL DEFAULT 'off',
            updated_at INTEGER NOT NULL
          )
        ''');
      } catch (_) {}
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE songs ADD COLUMN track_number INTEGER');
      } catch (_) {}
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_songs_album_track ON songs (album COLLATE NOCASE, track_number ASC)',
        );
      } catch (_) {}
    }

    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            cover_path TEXT,
            font_family TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS playlist_songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER NOT NULL,
            song_id INTEGER,
            media_store_id INTEGER NOT NULL,
            track_order INTEGER NOT NULL,
            added_at INTEGER NOT NULL,
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
            FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE SET NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_playlist_songs_order ON playlist_songs (playlist_id, track_order ASC)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_playlists_updated ON playlists (updated_at DESC)',
        );
      } catch (_) {}
    }

    if (oldVersion < 7) {
      try {
        final playlistCols = await db.rawQuery('PRAGMA table_info(playlists)');
        final hasFontFamily = playlistCols.any((col) => col['name'] == 'font_family');
        if (!hasFontFamily) {
          await db.execute('ALTER TABLE playlists ADD COLUMN font_family TEXT');
        }
      } catch (_) {}
    }

    if (oldVersion < 8) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS pinned_favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_type TEXT NOT NULL,
            item_key TEXT UNIQUE NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT,
            representative_song_id INTEGER,
            album_id INTEGER,
            playlist_id INTEGER,
            cover_path TEXT,
            font_family TEXT,
            pinned_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_pinned_favorites_pinned_at ON pinned_favorites (pinned_at DESC)',
        );
      } catch (_) {}
    }

    if (oldVersion < 9) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS favorite_songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            media_store_id INTEGER UNIQUE NOT NULL,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            album_artist TEXT,
            album_id INTEGER,
            duration INTEGER NOT NULL,
            path TEXT NOT NULL,
            date_modified INTEGER,
            track_number INTEGER,
            favorited_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite_songs_at ON favorite_songs (favorited_at DESC)',
        );
      } catch (_) {}
    }
  }

  /// Verifies schema integrity on database opening.
  Future<void> _onOpen(Database db) async {
    // Defensive check to ensure all columns and tables exist on pre-existing databases
    try {
      final columns = await db.rawQuery('PRAGMA table_info(songs)');
      final hasAlbumArtist = columns.any((col) => col['name'] == 'album_artist');
      if (!hasAlbumArtist) {
        await db.execute('ALTER TABLE songs ADD COLUMN album_artist TEXT');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_songs_album_artist ON songs (album_artist COLLATE NOCASE)',
        );
      }
      final hasTrackNumber = columns.any((col) => col['name'] == 'track_number');
      if (!hasTrackNumber) {
        await db.execute('ALTER TABLE songs ADD COLUMN track_number INTEGER');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_songs_album_track ON songs (album COLLATE NOCASE, track_number ASC)',
        );
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recent_searches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT NOT NULL,
          entity_key TEXT UNIQUE NOT NULL,
          title TEXT NOT NULL,
          subtitle TEXT NOT NULL,
          representative_song_id INTEGER NOT NULL,
          album_id INTEGER,
          searched_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_recent_searches_searched_at ON recent_searches (searched_at DESC)',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS playback_session (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          song_media_store_id INTEGER,
          song_id INTEGER,
          position_ms INTEGER NOT NULL DEFAULT 0,
          queue_media_store_ids TEXT,
          current_index INTEGER NOT NULL DEFAULT 0,
          shuffle_enabled INTEGER NOT NULL DEFAULT 0,
          loop_mode TEXT NOT NULL DEFAULT 'off',
          updated_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS playlists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          cover_path TEXT,
          font_family TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      final playlistCols = await db.rawQuery('PRAGMA table_info(playlists)');
      final hasFontFamily = playlistCols.any((col) => col['name'] == 'font_family');
      if (!hasFontFamily) {
        await db.execute('ALTER TABLE playlists ADD COLUMN font_family TEXT');
      }
      await db.execute('''
        CREATE TABLE IF NOT EXISTS playlist_songs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlist_id INTEGER NOT NULL,
          song_id INTEGER,
          media_store_id INTEGER NOT NULL,
          track_order INTEGER NOT NULL,
          added_at INTEGER NOT NULL,
          FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
          FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE SET NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_playlist_songs_order ON playlist_songs (playlist_id, track_order ASC)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_playlists_updated ON playlists (updated_at DESC)',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pinned_favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_type TEXT NOT NULL,
          item_key TEXT UNIQUE NOT NULL,
          title TEXT NOT NULL,
          subtitle TEXT,
          representative_song_id INTEGER,
          album_id INTEGER,
          playlist_id INTEGER,
          cover_path TEXT,
          font_family TEXT,
          pinned_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pinned_favorites_pinned_at ON pinned_favorites (pinned_at DESC)',
      );
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_songs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          media_store_id INTEGER UNIQUE NOT NULL,
          title TEXT NOT NULL,
          artist TEXT,
          album TEXT,
          album_artist TEXT,
          album_id INTEGER,
          duration INTEGER NOT NULL,
          path TEXT NOT NULL,
          date_modified INTEGER,
          track_number INTEGER,
          favorited_at INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_favorite_songs_at ON favorite_songs (favorited_at DESC)',
      );
    } catch (_) {}
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
        album_artist TEXT,
        album_id INTEGER,
        duration INTEGER,
        path TEXT NOT NULL,
        track_number INTEGER,
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

    // 3. Table: app_metadata
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 4. Table: recent_searches (max 20 entries)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recent_searches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_key TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        representative_song_id INTEGER NOT NULL,
        album_id INTEGER,
        searched_at INTEGER NOT NULL
      )
    ''');

    // 5. Table: playback_session (singleton row with id = 1 for persistent playback session)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playback_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        song_media_store_id INTEGER,
        song_id INTEGER,
        position_ms INTEGER NOT NULL DEFAULT 0,
        queue_media_store_ids TEXT,
        current_index INTEGER NOT NULL DEFAULT 0,
        shuffle_enabled INTEGER NOT NULL DEFAULT 0,
        loop_mode TEXT NOT NULL DEFAULT 'off',
        updated_at INTEGER NOT NULL
      )
    ''');

    // 6. Table: playlists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cover_path TEXT,
        font_family TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // 7. Table: playlist_songs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        song_id INTEGER,
        media_store_id INTEGER NOT NULL,
        track_order INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE SET NULL
      )
    ''');

    // Mandatory B-Tree Indices for zero-jank retrieval
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_artist ON songs (artist COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_album ON songs (album COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_album_artist ON songs (album_artist COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_songs_album_track ON songs (album COLLATE NOCASE, track_number ASC)',
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_history_played_at ON playback_history (played_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_history_artist ON playback_history (artist COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recent_searches_searched_at ON recent_searches (searched_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_playlist_songs_order ON playlist_songs (playlist_id, track_order ASC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_playlists_updated ON playlists (updated_at DESC)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pinned_favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_type TEXT NOT NULL,
        item_key TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT,
        representative_song_id INTEGER,
        album_id INTEGER,
        playlist_id INTEGER,
        cover_path TEXT,
        font_family TEXT,
        pinned_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_pinned_favorites_pinned_at ON pinned_favorites (pinned_at DESC)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorite_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        media_store_id INTEGER UNIQUE NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        album_artist TEXT,
        album_id INTEGER,
        duration INTEGER NOT NULL,
        path TEXT NOT NULL,
        date_modified INTEGER,
        track_number INTEGER,
        favorited_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_favorite_songs_at ON favorite_songs (favorited_at DESC)',
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
