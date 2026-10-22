/// File: favorite_songs_dao.dart
/// Description: Data Access Object managing user-favorited songs persisted in SQLite.
/// Maintains an in-memory Set of favorite mediaStoreIds for zero-latency synchronous checks
/// and a reactive ValueNotifier revision counter for instant UI reactivity across the application.
///
/// Components / Classes / Functions:
/// - FavoriteSongsDao: Singleton DAO providing CRUD and query operations for favorite songs.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object managing favorite songs persisted in SQLite.
class FavoriteSongsDao {
  static final FavoriteSongsDao instance = FavoriteSongsDao._internal();

  final AppDatabase _dbProvider;
  final Set<int> _cachedFavoriteIds = <int>{};
  bool _isCacheLoaded = false;

  /// Global reactive revision counter notified whenever favorites change.
  final ValueNotifier<int> favoritesRevision = ValueNotifier<int>(0);

  FavoriteSongsDao({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  FavoriteSongsDao._internal() : _dbProvider = AppDatabase.instance;

  factory FavoriteSongsDao.create({AppDatabase? dbProvider}) =>
      FavoriteSongsDao(dbProvider: dbProvider);

  /// Helper to ensure the in-memory cache is populated from SQLite.
  Future<void> ensureLoaded() async {
    if (_isCacheLoaded) return;
    try {
      final db = await _dbProvider.database;
      final rows = await db.query(
        'favorite_songs',
        columns: ['media_store_id'],
      );
      _cachedFavoriteIds.clear();
      for (final row in rows) {
        final id = row['media_store_id'] as int?;
        if (id != null) {
          _cachedFavoriteIds.add(id);
        }
      }
      _isCacheLoaded = true;
    } catch (e) {
      debugPrint('⚠️ [FavoriteSongsDao] Error loading favorites cache: $e');
    }
  }

  /// Fast synchronous check whether a song is currently marked as favorite.
  bool isFavorite(int mediaStoreId) {
    return _cachedFavoriteIds.contains(mediaStoreId);
  }

  /// Sets or seeds the in-memory cache directly (useful for tests and synchronous setups).
  @visibleForTesting
  void setCachedFavorites(Iterable<int> ids) {
    _cachedFavoriteIds.clear();
    _cachedFavoriteIds.addAll(ids);
    _isCacheLoaded = true;
  }

  /// Retrieves all favorited songs sorted by favorite date descending.
  Future<List<Song>> getAllFavorites() async {
    try {
      final db = await _dbProvider.database;
      final rows = await db.query(
        'favorite_songs',
        orderBy: 'favorited_at DESC',
      );

      _cachedFavoriteIds.clear();
      final songs = <Song>[];
      for (final r in rows) {
        final mediaStoreId = r['media_store_id'] as int;
        _cachedFavoriteIds.add(mediaStoreId);
        songs.add(
          Song(
            id: r['id'] as int?,
            mediaStoreId: mediaStoreId,
            title: (r['title'] as String?) ?? 'Unknown Title',
            artist: r['artist'] as String?,
            album: r['album'] as String?,
            albumArtist: r['album_artist'] as String?,
            albumId: r['album_id'] as int?,
            duration: (r['duration'] as int?) ?? 0,
            path: (r['path'] as String?) ?? '',
            trackNumber: r['track_number'] as int?,
            dateModified: (r['date_modified'] as int?) ?? 0,
          ),
        );
      }
      _isCacheLoaded = true;
      return songs;
    } catch (e) {
      debugPrint('⚠️ [FavoriteSongsDao] Error querying favorites: $e');
      return [];
    }
  }

  /// Toggles favorite status for a [song].
  /// Returns `true` if newly favorited, or `false` if un-favorited.
  Future<bool> toggleFavorite(Song song) async {
    try {
      final db = await _dbProvider.database;
      final isCurrentlyFav = _cachedFavoriteIds.contains(song.mediaStoreId);

      if (isCurrentlyFav) {
        await db.delete(
          'favorite_songs',
          where: 'media_store_id = ?',
          whereArgs: [song.mediaStoreId],
        );
        _cachedFavoriteIds.remove(song.mediaStoreId);
        favoritesRevision.value++;
        return false;
      } else {
        await db.insert(
          'favorite_songs',
          {
            'media_store_id': song.mediaStoreId,
            'title': song.title,
            'artist': song.artist,
            'album': song.album,
            'album_artist': song.albumArtist,
            'album_id': song.albumId,
            'duration': song.duration,
            'path': song.path,
            'date_modified': song.dateModified,
            'track_number': song.trackNumber,
            'favorited_at': DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _cachedFavoriteIds.add(song.mediaStoreId);
        favoritesRevision.value++;
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [FavoriteSongsDao] Error toggling favorite: $e');
      return false;
    }
  }

  /// Clears all favorites (useful for tests).
  Future<void> clearAll() async {
    try {
      final db = await _dbProvider.database;
      await db.delete('favorite_songs');
      _cachedFavoriteIds.clear();
      _isCacheLoaded = true;
      favoritesRevision.value++;
    } catch (_) {}
  }
}
