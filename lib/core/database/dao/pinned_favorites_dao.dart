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

  /// Retrieves all pinned favorites sorted by pin date descending.
  Future<List<PinnedFavorite>> getAllPinned() async {
    final db = await _db;
    final rows = await db.query(
      'pinned_favorites',
      orderBy: 'pinned_at DESC',
    );
    return rows.map((r) => PinnedFavorite.fromMap(r)).toList();
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
      revision.value++;
      return false;
    } else {
      await db.insert(
        'pinned_favorites',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
      revision.value++;
    }
    return deleted;
  }

  /// Clears all pinned favorites (useful for tests).
  @visibleForTesting
  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('pinned_favorites');
    revision.value++;
  }
}
