/// File: pinned_favorites_dao.dart
/// Description: Data Access Object managing user-pinned favorites (albums, artists, and playlists)
/// stored in SQLite. Emits reactive updates via ValueNotifier revision for Frame 0 zero-jank UI updates.
///
/// Components / Classes / Functions:
/// - PinnedFavoritesDao: Singleton DAO managing CRUD for pinned favorites.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object for managing pinned favorites in SQLite.
class PinnedFavoritesDao {
  static final PinnedFavoritesDao instance = PinnedFavoritesDao._internal();

  PinnedFavoritesDao._internal();

  factory PinnedFavoritesDao() => instance;

  /// Global reactive revision counter notified whenever pinned favorites change.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Helper to generate a deterministic unique key for albums.
  static String albumKey(String album, String? artist) {
    final cleanAlb = album.trim().toLowerCase();
    final cleanArt = (artist ?? '').trim().toLowerCase();
    return 'album::$cleanAlb::$cleanArt';
  }

  /// Helper to generate a deterministic unique key for artists.
  static String artistKey(String artist) {
    return 'artist::${artist.trim().toLowerCase()}';
  }

  /// Helper to generate a deterministic unique key for playlists.
  static String playlistKey(int playlistId) {
    return 'playlist::$playlistId';
  }

  Future<Database> get _db async => AppDatabase.instance.database;

  List<PinnedFavorite>? _cachedPinned;

  /// Synchronous snapshot of pinned items populated during startup or latest query.
  List<PinnedFavorite>? get cachedPinned => _cachedPinned;

  /// Retrieves all pinned favorites sorted by pin date descending.
  Future<List<PinnedFavorite>> getAllPinned() async {
    final db = await _db;
    final rows = await db.query(
      'pinned_favorites',
      orderBy: 'pinned_at DESC',
    );
    final items = rows.map((r) => PinnedFavorite.fromMap(r)).toList();
    _cachedPinned = items;
    return items;
  }

  /// Checks whether an entity with the given [itemKey] is currently pinned.
  Future<bool> isPinned(String itemKey) async {
    final db = await _db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM pinned_favorites WHERE item_key = ?',
        [itemKey],
      ),
    );
    return (count ?? 0) > 0;
  }

  /// Toggles the pinned status of [item].
  /// Returns `true` if the item is now pinned, or `false` if it was unpinned.
  Future<bool> togglePin(PinnedFavorite item) async {
    final db = await _db;
    final currentlyPinned = await isPinned(item.itemKey);

    if (currentlyPinned) {
      await db.delete(
        'pinned_favorites',
        where: 'item_key = ?',
        whereArgs: [item.itemKey],
      );
      _cachedPinned = null;
      revision.value++;
      return false;
    } else {
      await db.insert(
        'pinned_favorites',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _cachedPinned = null;
      revision.value++;
      return true;
    }
  }

  /// Removes an item by [itemKey].
  Future<int> deletePinned(String itemKey) async {
    final db = await _db;
    final deleted = await db.delete(
      'pinned_favorites',
      where: 'item_key = ?',
      whereArgs: [itemKey],
    );
    if (deleted > 0) {
      _cachedPinned = null;
      revision.value++;
    }
    return deleted;
  }

  /// Removes pinned albums, artists, and playlists whose underlying media no longer exists.
  /// Returns total deleted count and increments [revision] when [notify] is true.
  Future<int> pruneOrphanedPins({
    DatabaseExecutor? executor,
    bool notify = true,
  }) async {
    final db = executor ?? await _db;
    int totalDeleted = 0;

    // 1. Prune pinned albums with zero matching songs left in `songs`
    totalDeleted += await db.rawDelete('''
      DELETE FROM pinned_favorites
      WHERE item_type = 'album'
        AND NOT EXISTS (
          SELECT 1 FROM songs s
          WHERE LOWER(TRIM(s.album)) = LOWER(TRIM(pinned_favorites.title))
            AND (
              pinned_favorites.subtitle IS NULL
              OR TRIM(pinned_favorites.subtitle) = ''
              OR LOWER(TRIM(pinned_favorites.subtitle)) IN ('<desconocido>', 'unknown artist')
              OR LOWER(TRIM(COALESCE(NULLIF(TRIM(s.album_artist), ''), NULLIF(TRIM(s.artist), ''), ''))) = LOWER(TRIM(pinned_favorites.subtitle))
              OR LOWER(TRIM(s.artist)) LIKE LOWER(TRIM(pinned_favorites.subtitle)) || '%'
              OR EXISTS (
                SELECT 1 FROM song_artists sa
                WHERE sa.song_id = s.id AND LOWER(TRIM(sa.artist)) = LOWER(TRIM(pinned_favorites.subtitle))
              )
            )
        )
    ''');

    // 2. Prune pinned artists with zero matching tracks left in `songs` or `song_artists`
    totalDeleted += await db.rawDelete('''
      DELETE FROM pinned_favorites
      WHERE item_type = 'artist'
        AND NOT EXISTS (
          SELECT 1 FROM songs s
          WHERE LOWER(TRIM(s.artist)) = LOWER(TRIM(pinned_favorites.title))
             OR LOWER(TRIM(s.album_artist)) = LOWER(TRIM(pinned_favorites.title))
        )
        AND NOT EXISTS (
          SELECT 1 FROM song_artists sa
          WHERE LOWER(TRIM(sa.artist)) = LOWER(TRIM(pinned_favorites.title))
        )
    ''');

    // 3. Prune pinned playlists whose playlist row was deleted
    totalDeleted += await db.rawDelete('''
      DELETE FROM pinned_favorites
      WHERE item_type = 'playlist'
        AND playlist_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM playlists p WHERE p.id = pinned_favorites.playlist_id
        )
    ''');

    if (totalDeleted > 0) {
      _cachedPinned = null;
      if (notify) {
        revision.value++;
      }
    }
    return totalDeleted;
  }

  /// Clears all pinned favorites (useful for tests).
  @visibleForTesting
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('pinned_favorites');
    _cachedPinned = null;
    revision.value++;
  }
}
