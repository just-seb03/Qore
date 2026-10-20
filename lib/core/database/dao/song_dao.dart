/// File: song_dao.dart
/// Description: Data Access Object for the 'songs' table in SQLite.
/// Implements atomic batch synchronization and high-speed projection queries.
///
/// Components / Classes / Functions:
/// - SongDao: Data access class managing queries and atomic transactions for songs.
library;

import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object for managing track persistence and querying in SQLite.
class SongDao {
  final AppDatabase _appDatabase;

  SongDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  /// Retrieves a lightweight in-memory mapping of {mediaStoreId: dateModified}.
  /// Used in Phase 2 for algebraic set diffing without loading full Song objects.
  Future<Map<int, int>> getCachedMediaStoreIdsAndModified() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT media_store_id, date_modified FROM songs WHERE media_store_id IS NOT NULL',
    );

    final Map<int, int> map = {};
    for (final row in results) {
      final id = row['media_store_id'] as int?;
      final dateModified = row['date_modified'] as int?;
      if (id != null) {
        map[id] = dateModified ?? 0;
      }
    }
    return map;
  }

  /// Retrieves all songs sorted alphabetically by title.
  Future<List<Song>> getAllSongs() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      'songs',
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Returns the total count of indexed songs.
  Future<int> getSongCount() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    if (result.isNotEmpty) {
      return (result.first['count'] as int?) ?? 0;
    }
    return 0;
  }

  /// Executes atomic batch delta synchronization (Phase 4).
  ///
  /// Performs all deletions and insertions/updates inside a single ACID transaction
  /// using `batch.commit(noResult: true)` for maximum performance.
  Future<void> syncDelta({
    required List<Song> toInsertOrUpdate,
    required List<int> toDelete,
  }) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      // 1. Delete removed tracks
      for (final mediaStoreId in toDelete) {
        batch.delete(
          'songs',
          where: 'media_store_id = ?',
          whereArgs: [mediaStoreId],
        );
      }

      // 2. Insert or replace new/updated tracks
      for (final song in toInsertOrUpdate) {
        batch.insert(
          'songs',
          song.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  /// Wipes all songs from the table (primarily used for unit testing).
  Future<void> clearAll() async {
    final db = await _appDatabase.database;
    await db.delete('songs');
  }
}
