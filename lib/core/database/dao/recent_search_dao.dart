/// File: recent_search_dao.dart
/// Description: Data Access Object managing the 'recent_searches' table in SQLite.
/// Handles atomic insertion, MRU timestamp refreshes, and automatic trimming (max 20 entries).
///
/// Components / Classes / Functions:
/// - RecentSearchDao: Data access class executing queries and transactions for recent searches.
library;

import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';

/// Data Access Object for persisting and retrieving user recent search selections.
class RecentSearchDao {
  final AppDatabase _appDatabase;

  RecentSearchDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  /// Retrieves up to [limit] most recently clicked search items, ordered chronologically.
  Future<List<RecentSearchItem>> getRecentSearches({int limit = 20}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      'recent_searches',
      orderBy: 'searched_at DESC, id DESC',
      limit: limit,
    );
    return results.map((row) => RecentSearchItem.fromMap(row)).toList();
  }

  /// Atomically inserts or updates a search entity, bumping its timestamp to the top
  /// and pruning any entries beyond the 20 most recent.
  Future<void> saveRecentSearch(RecentSearchItem item) async {
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      // 1. Insert or replace by entity_key to prevent duplicate rows
      await txn.rawInsert(
        '''
        INSERT INTO recent_searches (
          entity_type,
          entity_key,
          title,
          subtitle,
          representative_song_id,
          album_id,
          searched_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(entity_key) DO UPDATE SET
          title = excluded.title,
          subtitle = excluded.subtitle,
          representative_song_id = excluded.representative_song_id,
          album_id = excluded.album_id,
          searched_at = excluded.searched_at;
        ''',
        [
          item.type.name,
          item.entityKey,
          item.title,
          item.subtitle,
          item.representativeSongId,
          item.albumId,
          item.timestampSeconds,
        ],
      );

      // 2. Prune records beyond the 20 most recent
      await txn.execute('''
        DELETE FROM recent_searches 
        WHERE id NOT IN (
          SELECT id FROM recent_searches ORDER BY searched_at DESC, id DESC LIMIT 20
        );
      ''');
    });
  }

  /// Deletes a specific recent search entry by its SQLite row ID.
  Future<void> deleteRecentSearch(int id) async {
    final db = await _appDatabase.database;
    await db.delete(
      'recent_searches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a specific recent search entry by its unique entity key.
  Future<void> deleteRecentSearchByKey(String entityKey) async {
    final db = await _appDatabase.database;
    await db.delete(
      'recent_searches',
      where: 'entity_key = ?',
      whereArgs: [entityKey],
    );
  }

  /// Clears all recent search history.
  Future<void> clearAll() async {
    final db = await _appDatabase.database;
    await db.delete('recent_searches');
  }
}
