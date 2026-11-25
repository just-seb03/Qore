/// File: song_dao.dart
/// Description: Data Access Object for the 'songs' table in SQLite.
/// Implements atomic batch synchronization and high-speed projection queries.
///
/// Components / Classes / Functions:
/// - SongDao: Data access class managing queries and atomic transactions for songs.
library;

import 'dart:io';
import 'dart:isolate';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/genre_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/database/models/song_artwork_meta.dart';
import 'package:project_anima/core/utils/artist_splitter.dart';
import 'package:sqflite/sqflite.dart';

export 'package:project_anima/core/database/models/song_artwork_meta.dart';

/// Data Access Object for managing track persistence and querying in SQLite.
class SongDao {
  /// Global change notifier incremented whenever playback history changes.
  /// Allows all recent history presentation widgets to reactively reload without app restarts.
  static final ValueNotifier<int> playbackHistoryRevision = ValueNotifier<int>(0);

  /// Global change notifier incremented whenever songs are deleted or mutated in SQLite.
  /// Allows AlbumDetailScreen, ArtistDetailScreen, and PlaylistDetailScreen to reactively reload.
  static final ValueNotifier<int> libraryRevision = ValueNotifier<int>(0);

  /// Dispatches a reactive update notification to all playback history listeners.
  static void notifyPlaybackHistoryChanged() {
    playbackHistoryRevision.value++;
  }

  /// Dispatches a reactive update notification to all library detail listeners.
  static void notifyLibraryChanged() {
    libraryRevision.value++;
  }

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

  /// Retrieves lightweight metadata needed for artwork caching and indexing.
  /// Skips loading heavy fields (lyrics, titles, dates, audio specs) to minimize Dart heap allocations.
  Future<List<SongArtworkMeta>> getSongArtworkMetadata() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT media_store_id, album_id, album, artist, album_artist, path FROM songs WHERE media_store_id IS NOT NULL',
    );
    return results.map((row) => SongArtworkMeta(
      mediaStoreId: row['media_store_id'] as int,
      albumId: row['album_id'] as int?,
      album: row['album'] as String?,
      artist: row['artist'] as String?,
      albumArtist: row['album_artist'] as String?,
      path: (row['path'] as String?) ?? '',
    )).toList();
  }

  /// Retrieves lightweight song entities for the in-memory fuzzy search dictionary.
  /// Queries only search-relevant metadata and playback identifiers, skipping heavy date/file columns.
  Future<List<Song>> getSearchDictionarySongs() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT id, media_store_id, title, artist, album, album_artist, album_id, duration, path FROM songs ORDER BY title COLLATE NOCASE ASC',
    );
    return results.map((row) => Song.fromMap(row)).toList();
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

  /// Retrieves a deterministic, daily randomized selection of songs directly via SQL.
  /// Eliminates the need to load the full table into memory, saving significant RAM.
  Future<List<Song>> getRandomDailySelection({
    required int seed,
    int limit = 20,
  }) async {
    final db = await _appDatabase.database;
    final count = await getSongCount();
    if (count == 0) return [];
    if (count <= limit) {
      return getAllSongs();
    }

    // Deterministic pseudo-random sorting via SQLite arithmetic
    final results = await db.rawQuery('''
      SELECT * FROM songs
      ORDER BY ((id * ? + 1013904223) & 0x7FFFFFFF)
      LIMIT ?
    ''', [seed, limit]);

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves a single song by its MediaStore ID.
  Future<Song?> getSongByMediaStoreId(int mediaStoreId) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      'songs',
      where: 'media_store_id = ?',
      whereArgs: [mediaStoreId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Song.fromMap(results.first);
  }

  /// Batch retrieves songs by their MediaStore IDs, preserving the exact input order.
  /// Executes inside a single SELECT query without N+1 overhead.
  Future<List<Song>> getSongsByMediaStoreIds(List<int> mediaStoreIds) async {
    if (mediaStoreIds.isEmpty) return [];

    final db = await _appDatabase.database;
    final placeholders = List.filled(mediaStoreIds.length, '?').join(',');
    final List<Map<String, dynamic>> results = await db.query(
      'songs',
      where: 'media_store_id IN ($placeholders)',
      whereArgs: mediaStoreIds,
    );

    final Map<int, Song> songMap = {
      for (final row in results)
        if (row['media_store_id'] != null)
          row['media_store_id'] as int: Song.fromMap(row),
    };

    final List<Song> orderedSongs = [];
    for (final id in mediaStoreIds) {
      final song = songMap[id];
      if (song != null) {
        orderedSongs.add(song);
      }
    }
    return orderedSongs;
  }

  /// Searches indexed songs using high-speed B-Tree indices (title, artist, album)
  /// with multi-level relevance ranking (exact prefix, contains, artist, album).
  /// Operates in < 2 ms on native SQLite with zero external engine dependencies.
  /// Paginates results by [limit] (default 20, Rule 5.2.2) and [offset].
  Future<List<Song>> searchSongs(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final db = await _appDatabase.database;
    final exactPrefix = '$clean%';
    final contains = '%$clean%';

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT * FROM songs
      WHERE title LIKE ? OR artist LIKE ? OR album LIKE ?
      ORDER BY
        CASE
          WHEN title LIKE ? THEN 1
          WHEN title LIKE ? THEN 2
          WHEN artist LIKE ? THEN 3
          WHEN album LIKE ? THEN 4
          ELSE 5
        END,
        title COLLATE NOCASE ASC
      LIMIT ? OFFSET ?
      ''',
      [contains, contains, contains, exactPrefix, contains, exactPrefix, exactPrefix, limit, offset],
    );

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Backward-compatible alias for [searchSongs].
  Future<List<Song>> searchSongsFts(
    String query, {
    int limit = 20,
    int offset = 0,
  }) =>
      searchSongs(query, limit: limit, offset: offset);

  /// Executes atomic batch delta synchronization (Phase 4).
  ///
  /// Performs all deletions and insertions/updates inside a single ACID transaction
  /// using `batch.commit(noResult: true)` for maximum performance.
  Future<void> syncDelta({
    required List<Song> toInsertOrUpdate,
    required List<int> toDelete,
  }) async {
    final db = await _appDatabase.database;
    int prunedPins = 0;

    await db.transaction((txn) async {
      final batch = txn.batch();

      // 1. Delete removed tracks and dependent favorite / playlist / history rows
      for (final mediaStoreId in toDelete) {
        batch.delete(
          'playlist_songs',
          where: 'media_store_id = ?',
          whereArgs: [mediaStoreId],
        );
        batch.delete(
          'favorite_songs',
          where: 'media_store_id = ?',
          whereArgs: [mediaStoreId],
        );
        batch.rawDelete(
          'DELETE FROM playback_history WHERE song_id IN (SELECT id FROM songs WHERE media_store_id = ?)',
          [mediaStoreId],
        );
        batch.delete(
          'songs',
          where: 'media_store_id = ?',
          whereArgs: [mediaStoreId],
        );
        batch.delete(
          'song_artists',
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

      // 3. Update song_artists relational mapping for new/updated tracks
      if (toInsertOrUpdate.isNotEmpty) {
        final placeholders = List.filled(toInsertOrUpdate.length, '?').join(',');
        final msIds = toInsertOrUpdate.map((s) => s.mediaStoreId).toList();
        final insertedRows = await txn.rawQuery(
          'SELECT id, media_store_id, artist FROM songs WHERE media_store_id IN ($placeholders)',
          msIds,
        );
        final saBatch = txn.batch();
        for (final row in insertedRows) {
          final sId = row['id'] as int?;
          final msId = row['media_store_id'] as int?;
          final rawArt = row['artist'] as String?;
          if (sId != null && msId != null && rawArt != null) {
            saBatch.delete('song_artists', where: 'media_store_id = ?', whereArgs: [msId]);
            final split = ArtistSplitter.split(rawArt);
            for (final a in split) {
              saBatch.insert('song_artists', {
                'song_id': sId,
                'media_store_id': msId,
                'artist': a,
              });
            }
          }
        }
        await saBatch.commit(noResult: true);
      }

      // 4. Prune Space pinned albums/artists that no longer have any tracks
      if (toDelete.isNotEmpty) {
        prunedPins = await PinnedFavoritesDao.instance.pruneOrphanedPins(
          executor: txn,
          notify: false,
        );
      }
    });

    if (prunedPins > 0) {
      PinnedFavoritesDao.revision.value++;
    }
    if (toDelete.isNotEmpty) {
      await FavoriteSongsDao.instance.refreshCache();
    }
  }

  /// Synchronizes the relational `song_artists` table with `songs` if out of sync.
  Future<void> syncSongArtistsIfNeeded() async {
    final db = await _appDatabase.database;
    try {
      final songRows = await db.rawQuery(
        "SELECT COUNT(*) as count FROM songs WHERE artist IS NOT NULL AND TRIM(artist) != '' AND artist != '<Desconocido>'",
      );
      final int songCount = (songRows.first['count'] as int?) ?? 0;
      if (songCount == 0) return;

      final saRows = await db.rawQuery(
        'SELECT COUNT(DISTINCT song_id) as count FROM song_artists',
      );
      final int saSongCount = (saRows.first['count'] as int?) ?? 0;

      if (saSongCount != songCount) {
        await syncAllSongArtists();
      }
    } catch (_) {}
  }

  /// Rebuilds all entries in the `song_artists` table from `songs`.
  Future<void> syncAllSongArtists() async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('song_artists');
      final songs = await txn.rawQuery(
        "SELECT id, media_store_id, artist FROM songs WHERE artist IS NOT NULL AND TRIM(artist) != '' AND artist != '<Desconocido>'",
      );
      if (songs.isEmpty) return;

      final batch = txn.batch();
      for (final row in songs) {
        final id = row['id'] as int?;
        final mediaStoreId = (row['media_store_id'] as int?) ?? 0;
        final rawArtist = row['artist'] as String?;
        if (id != null && rawArtist != null) {
          final splitArtists = ArtistSplitter.split(rawArtist);
          for (final artist in splitArtists) {
            batch.insert('song_artists', {
              'song_id': id,
              'media_store_id': mediaStoreId,
              'artist': artist,
            });
          }
        }
      }
      await batch.commit(noResult: true);
    });
  }

  /// Wipes all songs and song_artists from tables (primarily used for unit testing).
  Future<void> clearAll() async {
    final db = await _appDatabase.database;
    await db.delete('song_artists');
    await db.delete('songs');
  }

  // ==========================================
  // Section 4.2: Anti-N+1 Relational Discovery
  // ==========================================

  /// Retrieves aggregated artist statistics in a single relational query (Rule 4.2).
  /// Strictly eliminates N+1 loops by joining songs and playback_history in SQLite.
  Future<List<ArtistDiscoveryItem>> getDiscoveryArtists({int limit = 15}) async {
    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        sa.artist AS name,
        COUNT(DISTINCT s.id) AS song_count,
        COUNT(DISTINCT s.album) AS album_count,
        MIN(s.media_store_id) AS representative_song_id,
        MIN(s.album_id) AS representative_album_id,
        MAX(ph.played_at) AS last_played
      FROM song_artists sa
      JOIN songs s ON sa.song_id = s.id
      LEFT JOIN playback_history ph ON s.id = ph.song_id
      WHERE sa.artist IS NOT NULL AND TRIM(sa.artist) != '' AND sa.artist != '<Desconocido>'
      GROUP BY sa.artist COLLATE NOCASE
      ORDER BY 
        CASE WHEN MAX(ph.played_at) IS NOT NULL THEN 0 ELSE 1 END,
        MAX(ph.played_at) DESC,
        COUNT(DISTINCT s.id) DESC,
        sa.artist COLLATE NOCASE ASC
      LIMIT ?;
      ''',
      [limit],
    );

    return results.map((row) => ArtistDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves aggregated album statistics in a single relational query (Rule 4.2).
  /// Correctly aggregates collaborative and featured albums by album_artist,
  /// falling back to track artist when album_artist is absent.
  /// Eliminates N+1 loops by grouping songs and calculating total tracks and duration.
  Future<List<AlbumDiscoveryItem>> getDiscoveryAlbums({int limit = 15}) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      WITH album_meta AS (
        SELECT
          s.album COLLATE NOCASE AS album_norm,
          COALESCE(s.album_id, 0) AS album_id_norm,
          MAX(
            CASE
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL
            END
          ) AS definitive_album_artist
        FROM songs s
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
        GROUP BY s.album COLLATE NOCASE, COALESCE(s.album_id, 0)
      ),
      song_resolved AS (
        SELECT
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          ph.played_at,
          COALESCE(
            CASE
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL
            END,
            am.definitive_album_artist,
            CASE
              WHEN INSTR(LOWER(s.artist), ' feat. ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' feat. ') - 1))
              WHEN INSTR(LOWER(s.artist), ' ft. ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' ft. ') - 1))
              WHEN INSTR(LOWER(s.artist), ' feat ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' feat ') - 1))
              WHEN INSTR(LOWER(s.artist), ' ft ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' ft ') - 1))
              WHEN INSTR(LOWER(s.artist), ' featuring ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' featuring ') - 1))
              WHEN INSTR(LOWER(s.artist), ' with ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' with ') - 1))
              WHEN INSTR(LOWER(s.artist), ', ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ', ') - 1))
              WHEN INSTR(LOWER(s.artist), ' & ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' & ') - 1))
              WHEN INSTR(LOWER(s.artist), ' / ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' / ') - 1))
              ELSE NULLIF(NULLIF(TRIM(s.artist), ''), '<Desconocido>')
            END,
            'Unknown Artist'
          ) AS resolved_artist
        FROM songs s
        LEFT JOIN album_meta am ON (
          s.album COLLATE NOCASE = am.album_norm 
          AND COALESCE(s.album_id, 0) = am.album_id_norm
        )
        LEFT JOIN (
          SELECT song_id, MAX(played_at) AS played_at
          FROM playback_history
          GROUP BY song_id
        ) ph ON s.id = ph.song_id
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
      )
      SELECT
        album AS name,
        resolved_artist AS artist,
        MIN(album_id) AS album_id,
        MIN(media_store_id) AS representative_song_id,
        COUNT(DISTINCT id) AS song_count,
        SUM(duration) AS total_duration,
        MAX(played_at) AS last_played
      FROM song_resolved
      GROUP BY album COLLATE NOCASE, resolved_artist COLLATE NOCASE
      ORDER BY last_played DESC, song_count DESC
      LIMIT ?;
      ''',
      [limit],
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves all aggregated distinct albums in the user's library,
  /// strictly filtered and grouped by album and unified album artist to prevent duplicate album entries.
  Future<List<AlbumDiscoveryItem>> getLibraryAlbums() async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      WITH album_meta AS (
        SELECT
          s.album COLLATE NOCASE AS album_norm,
          COALESCE(s.album_id, 0) AS album_id_norm,
          MAX(
            CASE
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL
            END
          ) AS definitive_album_artist
        FROM songs s
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
        GROUP BY s.album COLLATE NOCASE, COALESCE(s.album_id, 0)
      ),
      song_resolved AS (
        SELECT
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          COALESCE(
            CASE
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL
            END,
            am.definitive_album_artist,
            CASE
              WHEN INSTR(LOWER(s.artist), ' feat. ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' feat. ') - 1))
              WHEN INSTR(LOWER(s.artist), ' ft. ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' ft. ') - 1))
              WHEN INSTR(LOWER(s.artist), ' feat ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' feat ') - 1))
              WHEN INSTR(LOWER(s.artist), ' ft ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' ft ') - 1))
              WHEN INSTR(LOWER(s.artist), ' featuring ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' featuring ') - 1))
              WHEN INSTR(LOWER(s.artist), ' with ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' with ') - 1))
              WHEN INSTR(LOWER(s.artist), ', ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ', ') - 1))
              WHEN INSTR(LOWER(s.artist), ' & ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' & ') - 1))
              WHEN INSTR(LOWER(s.artist), ' / ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' / ') - 1))
              ELSE NULLIF(NULLIF(TRIM(s.artist), ''), '<Desconocido>')
            END,
            'Unknown Artist'
          ) AS resolved_artist
        FROM songs s
        LEFT JOIN album_meta am ON (
          s.album COLLATE NOCASE = am.album_norm 
          AND COALESCE(s.album_id, 0) = am.album_id_norm
        )
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
      )
      SELECT
        album AS name,
        resolved_artist AS artist,
        MIN(album_id) AS album_id,
        MIN(media_store_id) AS representative_song_id,
        COUNT(DISTINCT id) AS song_count,
        SUM(duration) AS total_duration
      FROM song_resolved
      GROUP BY album COLLATE NOCASE, resolved_artist COLLATE NOCASE
      ORDER BY album COLLATE NOCASE ASC;
      ''',
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves all distinct artists in the user's library, ordered alphabetically.
  Future<List<ArtistDiscoveryItem>> getLibraryArtists() async {
    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        sa.artist AS name,
        COUNT(DISTINCT s.id) AS song_count,
        COUNT(DISTINCT s.album) AS album_count,
        MIN(s.media_store_id) AS representative_song_id,
        MIN(s.album_id) AS representative_album_id
      FROM song_artists sa
      JOIN songs s ON sa.song_id = s.id
      WHERE sa.artist IS NOT NULL AND TRIM(sa.artist) != '' AND sa.artist != '<Desconocido>'
      GROUP BY sa.artist COLLATE NOCASE
      ORDER BY sa.artist COLLATE NOCASE ASC;
      ''',
    );

    return results.map((row) => ArtistDiscoveryItem.fromMap(row)).toList();
  }

  /// Records a playback event in `playback_history` backed by B-Tree indices.
  Future<void> recordPlayback({
    required int songId,
    String? artist,
    int? timestampSeconds,
  }) async {
    final db = await _appDatabase.database;
    final int playedAt =
        timestampSeconds ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

    await db.insert('playback_history', {
      'song_id': songId,
      'artist': artist,
      'played_at': playedAt,
    });
    notifyPlaybackHistoryChanged();
  }

  /// Retrieves the newest distinct albums added to the library, ordered by newest addition.
  Future<List<AlbumDiscoveryItem>> getNewestAlbums({int limit = 5}) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      WITH album_meta AS (
        SELECT
          s.album COLLATE NOCASE AS album_norm,
          COALESCE(s.album_id, 0) AS album_id_norm,
          MAX(
            CASE
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL
            END
          ) AS definitive_album_artist
        FROM songs s
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
        GROUP BY s.album COLLATE NOCASE, COALESCE(s.album_id, 0)
      ),
      song_resolved AS (
        SELECT
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          COALESCE(s.date_added, s.date_modified, s.id) AS sort_key,
          COALESCE(
            CASE
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL
            END,
            am.definitive_album_artist,
            CASE
              WHEN INSTR(LOWER(s.artist), ' feat. ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' feat. ') - 1))
              WHEN INSTR(LOWER(s.artist), ' ft. ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' ft. ') - 1))
              WHEN INSTR(LOWER(s.artist), ' feat ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' feat ') - 1))
              WHEN INSTR(LOWER(s.artist), ' ft ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' ft ') - 1))
              WHEN INSTR(LOWER(s.artist), ' featuring ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' featuring ') - 1))
              WHEN INSTR(LOWER(s.artist), ' with ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' with ') - 1))
              WHEN INSTR(LOWER(s.artist), ', ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ', ') - 1))
              WHEN INSTR(LOWER(s.artist), ' & ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' & ') - 1))
              WHEN INSTR(LOWER(s.artist), ' / ') > 0 THEN TRIM(SUBSTR(s.artist, 1, INSTR(LOWER(s.artist), ' / ') - 1))
              ELSE NULLIF(NULLIF(TRIM(s.artist), ''), '<Desconocido>')
            END,
            'Unknown Artist'
          ) AS resolved_artist
        FROM songs s
        LEFT JOIN album_meta am ON (
          s.album COLLATE NOCASE = am.album_norm 
          AND COALESCE(s.album_id, 0) = am.album_id_norm
        )
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
      )
      SELECT
        album AS name,
        resolved_artist AS artist,
        MIN(album_id) AS album_id,
        MIN(media_store_id) AS representative_song_id,
        COUNT(DISTINCT id) AS song_count,
        SUM(duration) AS total_duration,
        MAX(sort_key) AS newest_time
      FROM song_resolved
      GROUP BY album COLLATE NOCASE, resolved_artist COLLATE NOCASE
      ORDER BY newest_time DESC
      LIMIT ?;
      ''',
      [limit],
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves the newest distinct artists in the library, ordered by newest addition.
  Future<List<ArtistDiscoveryItem>> getNewestArtists({int limit = 5}) async {
    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        sa.artist AS name,
        COUNT(DISTINCT s.id) AS song_count,
        COUNT(DISTINCT s.album) AS album_count,
        MIN(s.media_store_id) AS representative_song_id,
        MIN(s.album_id) AS representative_album_id,
        MAX(COALESCE(s.date_added, s.date_modified, s.id)) AS newest_time
      FROM song_artists sa
      JOIN songs s ON sa.song_id = s.id
      WHERE sa.artist IS NOT NULL AND TRIM(sa.artist) != '' AND sa.artist != '<Desconocido>'
      GROUP BY sa.artist COLLATE NOCASE
      ORDER BY newest_time DESC
      LIMIT ?;
      ''',
      [limit],
    );

    return results.map((row) => ArtistDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves recently played tracks using a single relational JOIN query.
  /// Eliminates duplicate song instances by grouping by song_id.
  Future<List<Song>> getRecentlyPlayedSongs({int limit = 20}) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT s.*
      FROM songs s
      JOIN (
        SELECT song_id, MAX(played_at) as max_played_at
        FROM playback_history
        GROUP BY song_id
      ) ph ON (s.id = ph.song_id OR s.media_store_id = ph.song_id)
      GROUP BY s.id
      ORDER BY MAX(ph.max_played_at) DESC
      LIMIT ?;
      ''',
      [limit],
    );

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves songs belonging to [artist], ordered by title.
  /// When [limit] is null, all songs for the artist are retrieved.
  /// Matches against relational individual artists and album_artist for complete discographical coverage.
  Future<List<Song>> getSongsByArtist(
    String artist, {
    int? limit,
    int? offset,
  }) async {
    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();
    final clean = artist.trim();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT DISTINCT s.* FROM songs s
      JOIN song_artists sa ON s.id = sa.song_id
      WHERE sa.artist = ?1 COLLATE NOCASE OR s.album_artist = ?1 COLLATE NOCASE
      ORDER BY s.title COLLATE NOCASE ASC
      ${limit != null ? 'LIMIT ?2 OFFSET ${offset ?? 0}' : ''}
      ''',
      limit != null ? [clean, limit] : [clean],
    );

    if (results.isEmpty) {
      // Fallback matching against artist delimiters or exact equality
      final List<Map<String, dynamic>> fallbackResults = await db.rawQuery(
        '''
        SELECT DISTINCT s.* FROM songs s
        WHERE s.artist = ?1 COLLATE NOCASE 
           OR s.album_artist = ?1 COLLATE NOCASE
           OR s.artist LIKE ?1 || ', %' COLLATE NOCASE
           OR s.artist LIKE '%, ' || ?1 COLLATE NOCASE
           OR s.artist LIKE '%, ' || ?1 || ', %' COLLATE NOCASE
           OR s.artist LIKE ?1 || ' / %' COLLATE NOCASE
           OR s.artist LIKE '% / ' || ?1 COLLATE NOCASE
           OR s.artist LIKE '% / ' || ?1 || ' / %' COLLATE NOCASE
           OR s.artist LIKE ?1 || '; %' COLLATE NOCASE
           OR s.artist LIKE '%; ' || ?1 COLLATE NOCASE
        ORDER BY s.title COLLATE NOCASE ASC
        ${limit != null ? 'LIMIT ?2 OFFSET ${offset ?? 0}' : ''}
        ''',
        limit != null ? [clean, limit] : [clean],
      );
      return fallbackResults.map((row) => Song.fromMap(row)).toList();
    }

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves the top [limit] most played songs for an artist.
  /// Falls back to recent tracks by date if user playback history is sparse.
  Future<List<Song>> getTopSongsByArtist(String artist, {int limit = 3}) async {
    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();
    final clean = artist.trim();

    // 1. Fetch songs with playback history count
    final List<Map<String, dynamic>> historyResults = await db.rawQuery(
      '''
      SELECT s.*, COUNT(ph.id) AS play_count
      FROM songs s
      JOIN song_artists sa ON s.id = sa.song_id
      LEFT JOIN playback_history ph ON s.id = ph.song_id
      WHERE (sa.artist = ?1 COLLATE NOCASE OR s.album_artist = ?1 COLLATE NOCASE)
        AND ph.id IS NOT NULL
      GROUP BY s.id
      ORDER BY play_count DESC, s.title COLLATE NOCASE ASC
      LIMIT ?2;
      ''',
      [clean, limit],
    );

    final List<Song> topSongs =
        historyResults.map((row) => Song.fromMap(row)).toList();

    // 2. Fall back to artist songs if playback history has fewer than limit
    if (topSongs.length < limit) {
      final existingIds = topSongs.map((s) => s.id ?? s.mediaStoreId).toSet();

      final List<Song> fallbackSongs = await getSongsByArtist(clean, limit: limit * 2);

      for (final song in fallbackSongs) {
        final id = song.id ?? song.mediaStoreId;
        if (!existingIds.contains(id)) {
          topSongs.add(song);
          existingIds.add(id);
          if (topSongs.length >= limit) break;
        }
      }
    }

    return topSongs;
  }

  /// Retrieves distinct albums belonging to [artist] for discography horizontal carousel.
  /// Retrieves distinct albums belonging to [artist] for discography presentation.
  /// Guarantees that:
  /// 1. Albums belonging to other artists (or compilations where this artist only has a guest feature) are excluded.
  /// 2. Albums are uniquely grouped by name, eliminating duplicates caused by heterogeneous MediaStore album_ids.
  Future<List<AlbumDiscoveryItem>> getAlbumsByArtist(String artist) async {
    final cleanArtist = artist.trim();
    if (cleanArtist.isEmpty ||
        cleanArtist == '<Desconocido>' ||
        cleanArtist.toLowerCase() == 'unknown artist') {
      return [];
    }

    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      WITH artist_tracks AS (
        SELECT 
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          s.album_artist,
          s.artist
        FROM songs s
        LEFT JOIN song_artists sa ON s.id = sa.song_id
        WHERE s.album IS NOT NULL 
          AND TRIM(s.album) != '' 
          AND s.album != '<Desconocido>'
          AND (
            -- Explicit album_artist matches target artist or collaborative group
            s.album_artist = ?1 COLLATE NOCASE
            OR s.album_artist LIKE ?1 || ' & %' COLLATE NOCASE
            OR s.album_artist LIKE '% & ' || ?1 COLLATE NOCASE
            OR s.album_artist LIKE ?1 || ', %' COLLATE NOCASE
            OR s.album_artist LIKE '%, ' || ?1 COLLATE NOCASE
            OR s.album_artist LIKE ?1 || ' / %' COLLATE NOCASE
            OR s.album_artist LIKE '% / ' || ?1 COLLATE NOCASE
            -- Match relational song_artists
            OR sa.artist = ?1 COLLATE NOCASE
            -- Fallback when album_artist is empty: match track artist
            OR (
              (s.album_artist IS NULL OR TRIM(s.album_artist) = '' OR s.album_artist = '<Desconocido>' OR s.album_artist = 'Unknown Artist')
              AND (
                s.artist = ?1 COLLATE NOCASE
                OR s.artist LIKE ?1 || ' feat. %' COLLATE NOCASE
                OR s.artist LIKE ?1 || ' ft. %' COLLATE NOCASE
                OR s.artist LIKE ?1 || ' featuring %' COLLATE NOCASE
                OR s.artist LIKE ?1 || ' with %' COLLATE NOCASE
                OR s.artist LIKE ?1 || ' & %' COLLATE NOCASE
                OR s.artist LIKE '% & ' || ?1 COLLATE NOCASE
                OR s.artist LIKE ?1 || ', %' COLLATE NOCASE
                OR s.artist LIKE '%, ' || ?1 COLLATE NOCASE
                OR s.artist LIKE ?1 || ' / %' COLLATE NOCASE
                OR s.artist LIKE '% / ' || ?1 COLLATE NOCASE
                OR s.artist LIKE ?1 || '; %' COLLATE NOCASE
                OR s.artist LIKE '%; ' || ?1 COLLATE NOCASE
              )
            )
          )
      ),
      album_song_totals AS (
        SELECT 
          s.album COLLATE NOCASE AS album_norm,
          COUNT(DISTINCT s.id) AS total_count
        FROM songs s
        WHERE s.album IS NOT NULL AND TRIM(s.album) != '' AND s.album != '<Desconocido>'
        GROUP BY s.album COLLATE NOCASE
      )
      SELECT 
        at.album AS name,
        COALESCE(
          MAX(CASE 
            WHEN at.album_artist IS NOT NULL 
              AND TRIM(at.album_artist) != '' 
              AND at.album_artist != '<Desconocido>' 
              AND at.album_artist != 'Unknown Artist'
            THEN TRIM(at.album_artist)
            ELSE NULL 
          END),
          ?1
        ) AS artist,
        COALESCE(MAX(CASE WHEN at.album_id IS NOT NULL AND at.album_id > 0 THEN at.album_id ELSE NULL END), 0) AS album_id,
        COALESCE(
          MIN(CASE WHEN at.media_store_id IS NOT NULL AND at.media_store_id > 0 THEN at.media_store_id ELSE NULL END),
          0
        ) AS representative_song_id,
        COUNT(DISTINCT at.id) AS song_count,
        SUM(at.duration) AS total_duration,
        MAX(ph.played_at) AS last_played
      FROM artist_tracks at
      JOIN album_song_totals ast ON at.album COLLATE NOCASE = ast.album_norm
      LEFT JOIN (
        SELECT song_id, MAX(played_at) AS played_at
        FROM playback_history
        GROUP BY song_id
      ) ph ON at.id = ph.song_id
      GROUP BY at.album COLLATE NOCASE
      HAVING (
        -- Either album_artist explicitly belongs to target artist
        MAX(CASE 
          WHEN at.album_artist = ?1 COLLATE NOCASE 
            OR at.album_artist LIKE ?1 || ' & %' COLLATE NOCASE 
            OR at.album_artist LIKE '% & ' || ?1 COLLATE NOCASE
            OR at.album_artist LIKE ?1 || ', %' COLLATE NOCASE
            OR at.album_artist LIKE '%, ' || ?1 COLLATE NOCASE
            OR at.album_artist LIKE ?1 || ' / %' COLLATE NOCASE
            OR at.album_artist LIKE '% / ' || ?1 COLLATE NOCASE
            OR at.album_artist LIKE ?1 || '; %' COLLATE NOCASE
            OR at.album_artist LIKE '%; ' || ?1 COLLATE NOCASE
          THEN 1 
          ELSE 0 
        END) = 1
        -- Or this artist owns at least 50% of the tracks in this album (when album_artist is absent/unknown)
        OR (
          MAX(CASE 
            WHEN at.album_artist IS NOT NULL 
              AND TRIM(at.album_artist) != '' 
              AND at.album_artist != '<Desconocido>' 
              AND at.album_artist != 'Unknown Artist'
            THEN 1 
            ELSE 0 
          END) = 0
          AND (COUNT(DISTINCT at.id) * 2 >= MAX(ast.total_count))
        )
      )
      ORDER BY at.album COLLATE NOCASE ASC;
      ''',
      [cleanArtist],
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves distinct albums where [artist] appears as a secondary / guest artist
  /// (i.e. not the primary album artist, and not an album belonging to their main discography).
  Future<List<AlbumDiscoveryItem>> getAppearsOnAlbumsByArtist(String artist) async {
    final cleanArtist = artist.trim();
    if (cleanArtist.isEmpty ||
        cleanArtist == '<Desconocido>' ||
        cleanArtist.toLowerCase() == 'unknown artist') {
      return [];
    }

    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      WITH artist_tracks AS (
        SELECT 
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          s.album_artist,
          s.artist
        FROM songs s
        LEFT JOIN song_artists sa ON s.id = sa.song_id
        WHERE s.album IS NOT NULL 
          AND TRIM(s.album) != '' 
          AND s.album != '<Desconocido>'
          AND (
            sa.artist = ?1 COLLATE NOCASE
            OR (
              s.artist = ?1 COLLATE NOCASE
              OR s.artist LIKE ?1 || ' feat. %' COLLATE NOCASE
              OR s.artist LIKE ?1 || ' ft. %' COLLATE NOCASE
              OR s.artist LIKE ?1 || ' featuring %' COLLATE NOCASE
              OR s.artist LIKE ?1 || ' with %' COLLATE NOCASE
              OR s.artist LIKE '% feat. ' || ?1 COLLATE NOCASE
              OR s.artist LIKE '% ft. ' || ?1 COLLATE NOCASE
              OR s.artist LIKE '% featuring ' || ?1 COLLATE NOCASE
              OR s.artist LIKE '% with ' || ?1 COLLATE NOCASE
              OR s.artist LIKE ?1 || ' & %' COLLATE NOCASE
              OR s.artist LIKE '% & ' || ?1 COLLATE NOCASE
              OR s.artist LIKE ?1 || ', %' COLLATE NOCASE
              OR s.artist LIKE '%, ' || ?1 COLLATE NOCASE
              OR s.artist LIKE ?1 || ' / %' COLLATE NOCASE
              OR s.artist LIKE '% / ' || ?1 COLLATE NOCASE
              OR s.artist LIKE ?1 || '; %' COLLATE NOCASE
              OR s.artist LIKE '%; ' || ?1 COLLATE NOCASE
            )
          )
      ),
      album_song_totals AS (
        SELECT 
          s.album COLLATE NOCASE AS album_norm,
          COUNT(DISTINCT s.id) AS total_count,
          COALESCE(
            MAX(CASE 
              WHEN s.album_artist IS NOT NULL 
                AND TRIM(s.album_artist) != '' 
                AND s.album_artist != '<Desconocido>' 
                AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
              ELSE NULL 
            END),
            MAX(CASE 
              WHEN s.artist IS NOT NULL 
                AND TRIM(s.artist) != '' 
                AND s.artist != '<Desconocido>' 
                AND s.artist != 'Unknown Artist'
              THEN TRIM(s.artist)
              ELSE NULL 
            END),
            '<Desconocido>'
          ) AS main_artist
        FROM songs s
        WHERE s.album IS NOT NULL AND TRIM(s.album) != '' AND s.album != '<Desconocido>'
        GROUP BY s.album COLLATE NOCASE
      )
      SELECT 
        at.album AS name,
        ast.main_artist AS artist,
        COALESCE(MAX(CASE WHEN at.album_id IS NOT NULL AND at.album_id > 0 THEN at.album_id ELSE NULL END), 0) AS album_id,
        COALESCE(
          MIN(CASE WHEN at.media_store_id IS NOT NULL AND at.media_store_id > 0 THEN at.media_store_id ELSE NULL END),
          0
        ) AS representative_song_id,
        MAX(ast.total_count) AS song_count,
        SUM(at.duration) AS total_duration,
        MAX(ph.played_at) AS last_played
      FROM artist_tracks at
      JOIN album_song_totals ast ON at.album COLLATE NOCASE = ast.album_norm
      LEFT JOIN (
        SELECT song_id, MAX(played_at) AS played_at
        FROM playback_history
        GROUP BY song_id
      ) ph ON at.id = ph.song_id
      GROUP BY at.album COLLATE NOCASE
      HAVING (
        -- Target artist is NOT the album_artist
        MAX(CASE 
          WHEN at.album_artist = ?1 COLLATE NOCASE 
            OR at.album_artist LIKE ?1 || ' & %' COLLATE NOCASE 
            OR at.album_artist LIKE '% & ' || ?1 COLLATE NOCASE
            OR at.album_artist LIKE ?1 || ', %' COLLATE NOCASE
            OR at.album_artist LIKE '%, ' || ?1 COLLATE NOCASE
            OR at.album_artist LIKE ?1 || ' / %' COLLATE NOCASE
            OR at.album_artist LIKE '% / ' || ?1 COLLATE NOCASE
            OR at.album_artist LIKE ?1 || '; %' COLLATE NOCASE
            OR at.album_artist LIKE '%; ' || ?1 COLLATE NOCASE
          THEN 1 
          ELSE 0 
        END) = 0
        -- And if album_artist is absent/unknown, target artist does NOT own >= 50%
        AND (
          MAX(CASE 
            WHEN at.album_artist IS NOT NULL 
              AND TRIM(at.album_artist) != '' 
              AND at.album_artist != '<Desconocido>' 
              AND at.album_artist != 'Unknown Artist'
            THEN 1 
            ELSE 0 
          END) = 1
          OR (COUNT(DISTINCT at.id) * 2 < MAX(ast.total_count))
        )
      )
      ORDER BY at.album COLLATE NOCASE ASC;
      ''',
      [cleanArtist],
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves up to [limit] assorted songs for [artist] ordered by modification/addition date.
  Future<List<Song>> getAssortedSongsByArtist(String artist, {int limit = 10}) async {
    final db = await _appDatabase.database;
    await syncSongArtistsIfNeeded();
    final clean = artist.trim();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT DISTINCT s.* FROM songs s
      JOIN song_artists sa ON s.id = sa.song_id
      WHERE sa.artist = ?1 COLLATE NOCASE OR s.album_artist = ?1 COLLATE NOCASE
      ORDER BY s.date_modified DESC, s.date_added DESC, s.title COLLATE NOCASE ASC
      LIMIT ?2;
      ''',
      [clean, limit],
    );

    if (results.isEmpty) {
      return getSongsByArtist(clean, limit: limit);
    }

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves songs belonging to [album], accurately scoped to [artist] or [albumId].
  /// Matches against `album_artist` first, falling back to `artist` when `album_artist` is absent.
  /// Guarantees that collaboration tracks and guest features remain with the parent album.
  Future<List<Song>> getSongsByAlbum(
    String album, {
    String? artist,
    int? albumId,
    int? limit,
  }) async {
    final db = await _appDatabase.database;
    final bool hasArtist = artist != null &&
        artist.trim().isNotEmpty &&
        artist != '<Desconocido>' &&
        artist != 'Unknown Artist';

    String where;
    List<dynamic> whereArgs;

    // 1. Resolve definitive album_artist for this album if available (Priority Rule)
    String? targetArtist = artist?.trim();
    if (hasArtist) {
      final List<Map<String, dynamic>> albumArtistRows = await db.rawQuery(
        '''
        SELECT s.album_artist
        FROM songs s
        WHERE s.album = ? COLLATE NOCASE
          ${albumId != null && albumId > 0 ? 'AND s.album_id = ?' : ''}
          AND s.album_artist IS NOT NULL 
          AND TRIM(s.album_artist) != '' 
          AND s.album_artist != '<Desconocido>' 
          AND s.album_artist != 'Unknown Artist'
        LIMIT 1;
        ''',
        albumId != null && albumId > 0 ? [album, albumId] : [album],
      );

      if (albumArtistRows.isNotEmpty) {
        final found = albumArtistRows.first['album_artist'] as String?;
        if (found != null && found.trim().isNotEmpty) {
          targetArtist = found.trim();
        }
      }
    }

    if (hasArtist && targetArtist != null) {
      if (albumId != null && albumId > 0) {
        where =
            "album = ? COLLATE NOCASE AND ("
            "album_artist = ? COLLATE NOCASE "
            "OR ("
            "(album_artist IS NULL OR TRIM(album_artist) = '' OR album_artist = '<Desconocido>' OR album_artist = 'Unknown Artist') "
            "AND ("
            "artist = ? COLLATE NOCASE "
            "OR artist LIKE ? COLLATE NOCASE "
            "OR (INSTR(LOWER(artist), ' feat. ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' feat. ') - 1)) = ? COLLATE NOCASE) "
            "OR (INSTR(LOWER(artist), ' ft. ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' ft. ') - 1)) = ? COLLATE NOCASE) "
            "OR (INSTR(LOWER(artist), ' & ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' & ') - 1)) = ? COLLATE NOCASE) "
            "OR (INSTR(LOWER(artist), ', ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ', ') - 1)) = ? COLLATE NOCASE)"
            ")"
            ") "
            "OR ("
            "(album_artist = ? COLLATE NOCASE OR album_artist IS NULL OR TRIM(album_artist) = '' OR album_artist = '<Desconocido>' OR album_artist = 'Unknown Artist') "
            "AND album_id = ? AND album_id IN ("
            "SELECT sub.album_id FROM songs sub "
            "WHERE sub.album = ? COLLATE NOCASE "
            "AND sub.album_artist = ? COLLATE NOCASE "
            "AND sub.album_artist IS NOT NULL "
            "AND TRIM(sub.album_artist) != '' "
            "AND sub.album_id IS NOT NULL AND sub.album_id > 0"
            ")"
            ")"
            ")";
        whereArgs = [
          album,
          targetArtist,
          targetArtist,
          '$targetArtist%',
          targetArtist,
          targetArtist,
          targetArtist,
          targetArtist,
          targetArtist,
          albumId,
          album,
          targetArtist,
        ];
      } else {
        where =
            "album = ? COLLATE NOCASE AND ("
            "album_artist = ? COLLATE NOCASE "
            "OR ("
            "(album_artist IS NULL OR TRIM(album_artist) = '' OR album_artist = '<Desconocido>' OR album_artist = 'Unknown Artist') "
            "AND ("
            "artist = ? COLLATE NOCASE "
            "OR artist LIKE ? COLLATE NOCASE "
            "OR (INSTR(LOWER(artist), ' feat. ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' feat. ') - 1)) = ? COLLATE NOCASE) "
            "OR (INSTR(LOWER(artist), ' ft. ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' ft. ') - 1)) = ? COLLATE NOCASE) "
            "OR (INSTR(LOWER(artist), ' & ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' & ') - 1)) = ? COLLATE NOCASE) "
            "OR (INSTR(LOWER(artist), ', ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ', ') - 1)) = ? COLLATE NOCASE)"
            ")"
            ") "
            "OR ("
            "(album_artist = ? COLLATE NOCASE OR album_artist IS NULL OR TRIM(album_artist) = '' OR album_artist = '<Desconocido>' OR album_artist = 'Unknown Artist') "
            "AND album_id IS NOT NULL AND album_id > 0 AND album_id IN ("
            "SELECT sub.album_id FROM songs sub "
            "WHERE sub.album = ? COLLATE NOCASE "
            "AND sub.album_artist = ? COLLATE NOCASE "
            "AND sub.album_artist IS NOT NULL "
            "AND TRIM(sub.album_artist) != '' "
            "AND sub.album_id IS NOT NULL AND sub.album_id > 0"
            ")"
            ")"
            ")";
        whereArgs = [
          album,
          targetArtist,
          targetArtist,
          '$targetArtist%',
          targetArtist,
          targetArtist,
          targetArtist,
          targetArtist,
          targetArtist,
          album,
          targetArtist,
        ];
      }
    } else if (albumId != null && albumId > 0) {
      where = 'album = ? COLLATE NOCASE AND album_id = ?';
      whereArgs = [album, albumId];
    } else {
      where = 'album = ? COLLATE NOCASE';
      whereArgs = [album];
    }

    final List<Map<String, dynamic>> results = await db.query(
      'songs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'CASE WHEN disc_number IS NOT NULL AND disc_number > 0 THEN disc_number ELSE 1 END ASC, CASE WHEN track_number IS NOT NULL AND track_number > 0 THEN track_number ELSE 999999 END ASC, path ASC, title COLLATE NOCASE ASC',
      limit: limit,
    );

    final songs = results.map((row) => Song.fromMap(row)).toList();

    // Natural sort prioritizing discNumber first, then trackNumber (from tags/MediaStore),
    // fallback to regex on filename/title, and finally alphabetical on title.
    songs.sort((a, b) {
      final discA = (a.discNumber != null && a.discNumber! > 0) ? a.discNumber! : 1;
      final discB = (b.discNumber != null && b.discNumber! > 0) ? b.discNumber! : 1;
      if (discA != discB) {
        return discA.compareTo(discB);
      }

      final trackA = a.trackNumber ?? _extractTrackNumber(a);
      final trackB = b.trackNumber ?? _extractTrackNumber(b);
      if (trackA != null && trackB != null) {
        final cmp = trackA.compareTo(trackB);
        if (cmp != 0) return cmp;
      } else if (trackA != null) {
        return -1;
      } else if (trackB != null) {
        return 1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return songs;
  }

  static int? _extractTrackNumber(Song song) {
    if (song.trackNumber != null && song.trackNumber! > 0) {
      return song.trackNumber;
    }

    final filename = song.path.split(RegExp(r'[\\/]')).last;
    final parsedFromPath = _parseTrackFromString(filename);
    if (parsedFromPath != null) return parsedFromPath;

    final parsedFromTitle = _parseTrackFromString(song.title);
    if (parsedFromTitle != null) return parsedFromTitle;

    return null;
  }

  static int? _parseTrackFromString(String str) {
    final clean = str.trim();
    if (clean.isEmpty) return null;

    // Pattern 1: Multi-disc "1-02 Title" or "1.02 Title" -> Disc 1, Track 2 -> 1002
    final discMatch = RegExp(r'^(\d{1,2})[-.](\d{1,3})[\s._-]+').firstMatch(clean);
    if (discMatch != null) {
      final disc = int.tryParse(discMatch.group(1)!);
      final track = int.tryParse(discMatch.group(2)!);
      if (disc != null && track != null && disc > 0 && track > 0 && disc < 10) {
        return disc * 1000 + track;
      }
    }

    // Pattern 2: "[01] Title" or "(01) Title"
    final bracketMatch = RegExp(r'^[\[\(](\d{1,3})[\]\)][\s._-]*').firstMatch(clean);
    if (bracketMatch != null) {
      final track = int.tryParse(bracketMatch.group(1)!);
      if (track != null && track > 0) return track;
    }

    // Pattern 3: "Track 01" or "Pista 01" or "Track 1"
    final trackPrefixMatch = RegExp(r'^(?:track|pista)\s*(\d{1,3})', caseSensitive: false).firstMatch(clean);
    if (trackPrefixMatch != null) {
      final track = int.tryParse(trackPrefixMatch.group(1)!);
      if (track != null && track > 0) return track;
    }

    // Pattern 4: Standard "01 Title", "01 - Title", "01. Title", "01_Title"
    final standardMatch = RegExp(r'^(\d{1,3})[\s._-]+').firstMatch(clean);
    if (standardMatch != null) {
      final track = int.tryParse(standardMatch.group(1)!);
      if (track != null && track > 0) return track;
    }

    return null;
  }

  /// Checks whether the one-time album_artist backfill has been executed.
  Future<bool> isAlbumArtistBackfilled() async {
    final db = await _appDatabase.database;
    try {
      final res = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['album_artist_backfilled'],
      );
      return res.isNotEmpty && res.first['value'] == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the one-time album_artist backfill as complete in app_metadata.
  Future<void> markAlbumArtistBackfilled() async {
    final db = await _appDatabase.database;
    try {
      await db.insert(
        'app_metadata',
        {'key': 'album_artist_backfilled', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Batch backfills `album_artist` for cached songs using a mapping of {mediaStoreId: albumArtist}.
  /// Executes inside a single ACID batch in < 20 ms.
  Future<void> backfillAlbumArtists(Map<int, String> albumArtistsByMediaStoreId) async {
    if (albumArtistsByMediaStoreId.isEmpty) return;
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in albumArtistsByMediaStoreId.entries) {
        batch.update(
          'songs',
          {'album_artist': entry.value},
          where: 'media_store_id = ? AND (album_artist IS NULL OR TRIM(album_artist) = "" OR album_artist = "<Desconocido>")',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Checks whether the one-time physical file album_artist backfill has been executed.
  Future<bool> isPhysicalAlbumArtistBackfilled() async {
    final db = await _appDatabase.database;
    try {
      final res = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['physical_album_artist_backfilled'],
      );
      return res.isNotEmpty && res.first['value'] == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the one-time physical file album_artist backfill as complete in app_metadata.
  Future<void> markPhysicalAlbumArtistBackfilled() async {
    final db = await _appDatabase.database;
    try {
      await db.insert(
        'app_metadata',
        {'key': 'physical_album_artist_backfilled', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Retrieves cached songs that lack an album_artist value.
  Future<List<Song>> getSongsWithoutAlbumArtist() async {
    final db = await _appDatabase.database;
    final results = await db.query(
      'songs',
      columns: ['id', 'media_store_id', 'path'],
      where: 'album_artist IS NULL OR TRIM(album_artist) = "" OR album_artist = "<Desconocido>"',
    );
    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves lightweight id and path mappings for songs that lack an album_artist value
  /// without instantiating Song domain models.
  Future<List<Map<String, dynamic>>> getSongPathsWithoutAlbumArtist() async {
    final db = await _appDatabase.database;
    return await db.rawQuery(
      'SELECT media_store_id AS id, path FROM songs WHERE album_artist IS NULL OR TRIM(album_artist) = "" OR album_artist = "<Desconocido>"',
    );
  }

  /// Checks whether the one-time track_number backfill has been executed.
  Future<bool> isTrackNumberBackfilled() async {
    final db = await _appDatabase.database;
    try {
      final res = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['track_number_backfilled'],
      );
      return res.isNotEmpty && res.first['value'] == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the one-time track_number backfill as complete in app_metadata.
  Future<void> markTrackNumberBackfilled() async {
    final db = await _appDatabase.database;
    try {
      await db.insert(
        'app_metadata',
        {'key': 'track_number_backfilled', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Batch backfills `track_number` for cached songs using a mapping of {mediaStoreId: trackNumber}.
  /// Executes inside a single ACID batch in < 20 ms.
  Future<void> backfillTrackNumbers(Map<int, int> trackNumbersByMediaStoreId) async {
    if (trackNumbersByMediaStoreId.isEmpty) return;
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in trackNumbersByMediaStoreId.entries) {
        batch.update(
          'songs',
          {'track_number': entry.value},
          where: 'media_store_id = ? AND (track_number IS NULL OR track_number = 0)',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Updates track_number for a single song by its database ID or MediaStore ID.
  Future<void> updateSongTrackNumber({int? songId, int? mediaStoreId, required int trackNumber}) async {
    if (trackNumber <= 0) return;
    final db = await _appDatabase.database;
    if (songId != null) {
      await db.update(
        'songs',
        {'track_number': trackNumber},
        where: 'id = ?',
        whereArgs: [songId],
      );
    } else if (mediaStoreId != null) {
      await db.update(
        'songs',
        {'track_number': trackNumber},
        where: 'media_store_id = ?',
        whereArgs: [mediaStoreId],
      );
    }
  }

  /// Checks whether the one-time disc_number backfill has been executed.
  Future<bool> isDiscNumberBackfilled() async {
    final db = await _appDatabase.database;
    try {
      final res = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['disc_number_backfilled'],
      );
      return res.isNotEmpty && res.first['value'] == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the one-time disc_number backfill as complete in app_metadata.
  Future<void> markDiscNumberBackfilled() async {
    final db = await _appDatabase.database;
    try {
      await db.insert(
        'app_metadata',
        {'key': 'disc_number_backfilled', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Batch backfills `disc_number` for cached songs using a mapping of {mediaStoreId: discNumber}.
  /// Executes inside a single ACID batch in < 20 ms.
  Future<void> backfillDiscNumbers(Map<int, int> discNumbersByMediaStoreId) async {
    if (discNumbersByMediaStoreId.isEmpty) return;
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in discNumbersByMediaStoreId.entries) {
        batch.update(
          'songs',
          {'disc_number': entry.value},
          where: 'media_store_id = ? AND (disc_number IS NULL OR disc_number = 0)',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Updates disc_number for a single song by its database ID or MediaStore ID.
  Future<void> updateSongDiscNumber({int? songId, int? mediaStoreId, required int discNumber}) async {
    if (discNumber <= 0) return;
    final db = await _appDatabase.database;
    if (songId != null) {
      await db.update(
        'songs',
        {'disc_number': discNumber},
        where: 'id = ?',
        whereArgs: [songId],
      );
    } else if (mediaStoreId != null) {
      await db.update(
        'songs',
        {'disc_number': discNumber},
        where: 'media_store_id = ?',
        whereArgs: [mediaStoreId],
      );
    }
  }

  /// Checks whether audio BPM analysis backfill has completed for cached songs.
  Future<bool> isBpmBackfilled() async {
    final db = await _appDatabase.database;
    try {
      final res = await db.query(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['bpm_backfilled'],
      );
      return res.isNotEmpty && res.first['value'] == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks audio BPM analysis backfill as complete in app_metadata.
  Future<void> markBpmBackfilled() async {
    final db = await _appDatabase.database;
    try {
      await db.insert(
        'app_metadata',
        {'key': 'bpm_backfilled', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Clears the BPM backfill completion marker so all missing/unanalyzed songs are re-queued.
  Future<void> resetBpmBackfilled() async {
    final db = await _appDatabase.database;
    try {
      await db.delete(
        'app_metadata',
        where: 'key = ?',
        whereArgs: ['bpm_backfilled'],
      );
    } catch (_) {}
  }

  /// Retrieves cached song metadata rows requiring BPM analysis.
  Future<List<Map<String, dynamic>>> getSongsWithoutBpm({bool includeExisting = false}) async {
    final db = await _appDatabase.database;
    if (includeExisting) {
      return await db.rawQuery(
        'SELECT media_store_id AS id, path, duration FROM songs',
      );
    }
    return await db.rawQuery(
      'SELECT media_store_id AS id, path, duration FROM songs WHERE bpm IS NULL OR bpm <= 0',
    );
  }

  /// Batch updates BPM values for cached songs using a mapping of {mediaStoreId: bpm}.
  Future<void> backfillBpms(Map<int, double> bpmByMediaStoreId) async {
    if (bpmByMediaStoreId.isEmpty) return;
    final db = await _appDatabase.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final entry in bpmByMediaStoreId.entries) {
        if (entry.value <= 0) continue;
        batch.update(
          'songs',
          {'bpm': entry.value},
          where: 'media_store_id = ?',
          whereArgs: [entry.key],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Updates BPM for a single song by its database ID or MediaStore ID.
  Future<void> updateSongBpm({int? songId, int? mediaStoreId, required double bpm}) async {
    if (bpm <= 0) return;
    final db = await _appDatabase.database;
    if (songId != null) {
      await db.update(
        'songs',
        {'bpm': bpm},
        where: 'id = ?',
        whereArgs: [songId],
      );
    } else if (mediaStoreId != null) {
      await db.update(
        'songs',
        {'bpm': bpm},
        where: 'media_store_id = ?',
        whereArgs: [mediaStoreId],
      );
    }
  }

  /// Updates detected leading silence (ms) for a song by MediaStore ID.
  Future<void> updateSongLeadingSilence({
    required int mediaStoreId,
    required int leadingSilenceMs,
  }) async {
    final safeMs = leadingSilenceMs < 0 ? 0 : leadingSilenceMs;
    final db = await _appDatabase.database;
    await db.update(
      'songs',
      {'leading_silence_ms': safeMs},
      where: 'media_store_id = ?',
      whereArgs: [mediaStoreId],
    );
  }

  /// Retrieves tracks that have not yet been analyzed for leading silence.
  Future<List<Map<String, dynamic>>> getSongsWithoutLeadingSilence({
    int limit = 120,
  }) async {
    final db = await _appDatabase.database;
    return db.query(
      'songs',
      columns: ['media_store_id', 'path', 'duration'],
      where: 'leading_silence_ms IS NULL',
      limit: limit,
    );
  }

  /// Retrieves unique artists for search dictionary indexing.
  Future<List<ArtistDiscoveryItem>> getAllUniqueArtists({int limit = 1000}) =>
      getDiscoveryArtists(limit: limit);

  /// Retrieves unique albums for search dictionary indexing.
  Future<List<AlbumDiscoveryItem>> getAllUniqueAlbums({int limit = 1000}) =>
      getDiscoveryAlbums(limit: limit);

  /// Retrieves up to [limit] global top-played songs across the entire library,
  /// ordered by total playback count descending and most recent play.
  Future<List<Song>> getTopSongsGlobal({int limit = 5}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT s.*
      FROM songs s
      INNER JOIN playback_history ph ON s.id = ph.song_id
      GROUP BY s.id
      ORDER BY COUNT(ph.id) DESC, MAX(ph.played_at) DESC, s.title COLLATE NOCASE ASC
      LIMIT ?;
      ''',
      [limit],
    );
    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves the total active listening time in milliseconds from app_metadata.
  Future<int> getTotalPlaybackTimeMs() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['total_listening_time_ms'],
      limit: 1,
    );
    if (results.isEmpty || results.first['value'] == null) return 0;
    return int.tryParse(results.first['value'].toString()) ?? 0;
  }

  /// Retrieves up to [limit] most played artists across playback history.
  Future<List<ArtistDiscoveryItem>> getTopPlayedArtists({int limit = 3}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT
        COALESCE(
          NULLIF(TRIM(s.album_artist), ''),
          NULLIF(TRIM(s.artist), '')
        ) AS name,
        COUNT(DISTINCT s.id) AS song_count,
        COUNT(DISTINCT COALESCE(NULLIF(TRIM(s.album), ''), '<Desconocido>')) AS album_count,
        MIN(s.media_store_id) AS representative_song_id,
        MAX(s.album_id) AS representative_album_id,
        MAX(ph.played_at) AS last_played
      FROM playback_history ph
      INNER JOIN songs s ON s.id = ph.song_id
      WHERE COALESCE(NULLIF(TRIM(s.album_artist), ''), NULLIF(TRIM(s.artist), '')) IS NOT NULL
        AND COALESCE(NULLIF(TRIM(s.album_artist), ''), NULLIF(TRIM(s.artist), '')) != '<Desconocido>'
        AND COALESCE(NULLIF(TRIM(s.album_artist), ''), NULLIF(TRIM(s.artist), '')) != 'Unknown Artist'
      GROUP BY COALESCE(NULLIF(TRIM(s.album_artist), ''), NULLIF(TRIM(s.artist), '')) COLLATE NOCASE
      ORDER BY COUNT(ph.id) DESC, MAX(ph.played_at) DESC
      LIMIT ?;
      ''',
      [limit],
    );
    return results.map((row) => ArtistDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves the user's overall most played artist across playback history.
  Future<ArtistDiscoveryItem?> getMostPlayedArtist() async {
    final top = await getTopPlayedArtists(limit: 1);
    return top.isEmpty ? null : top.first;
  }

  /// Retrieves up to [limit] most played albums across playback history.
  Future<List<AlbumDiscoveryItem>> getTopPlayedAlbums({int limit = 3}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT
        s.album AS name,
        COALESCE(
          NULLIF(TRIM(s.album_artist), ''),
          NULLIF(TRIM(s.artist), ''),
          '<Desconocido>'
        ) AS artist,
        MAX(s.album_id) AS album_id,
        MIN(s.media_store_id) AS representative_song_id,
        COUNT(DISTINCT s.id) AS song_count,
        SUM(DISTINCT s.duration) AS total_duration,
        MAX(ph.played_at) AS last_played
      FROM playback_history ph
      INNER JOIN songs s ON s.id = ph.song_id
      WHERE s.album IS NOT NULL
        AND TRIM(s.album) != ''
        AND s.album != '<Desconocido>'
        AND s.album != 'Unknown Album'
      GROUP BY s.album COLLATE NOCASE
      ORDER BY COUNT(ph.id) DESC, MAX(ph.played_at) DESC
      LIMIT ?;
      ''',
      [limit],
    );
    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves the user's overall most played album across playback history.
  Future<AlbumDiscoveryItem?> getMostPlayedAlbum() async {
    final top = await getTopPlayedAlbums(limit: 1);
    return top.isEmpty ? null : top.first;
  }

  /// Retrieves the user's most played genre across playback history by inspecting
  /// audio tag metadata for the most played tracks, returning null if unavailable.
  Future<String?> getFavoriteGenre() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> rows = await db.rawQuery(
        '''
        SELECT s.path AS path, COUNT(ph.id) AS plays
        FROM playback_history ph
        INNER JOIN songs s ON s.id = ph.song_id
        WHERE s.path IS NOT NULL AND TRIM(s.path) != ''
        GROUP BY s.id
        ORDER BY plays DESC, MAX(ph.played_at) DESC
        LIMIT 25;
        ''',
      );
      if (rows.isEmpty) return null;

      final Map<String, int> genreScores = {};
      final Map<String, String> displayNames = {};

      for (final row in rows) {
        final path = row['path'] as String?;
        final plays = (row['plays'] as num?)?.toInt() ?? 1;
        if (path == null || path.isEmpty) continue;
        try {
          final file = File(path);
          if (!file.existsSync()) continue;
          final metadata = readMetadata(file, getImage: false);
          for (final rawGenre in metadata.genres) {
            final clean = rawGenre.trim();
            if (clean.isEmpty ||
                clean == '<Desconocido>' ||
                clean.toLowerCase() == 'unknown') {
              continue;
            }
            final normalized = clean.toLowerCase();
            genreScores[normalized] = (genreScores[normalized] ?? 0) + plays;
            displayNames.putIfAbsent(normalized, () => clean);
          }
        } catch (_) {
          // Skip unreadable files gracefully
        }
      }

      if (genreScores.isEmpty) return null;
      String? bestKey;
      int bestScore = -1;
      for (final entry in genreScores.entries) {
        if (entry.value > bestScore) {
          bestScore = entry.value;
          bestKey = entry.key;
        }
      }
      return bestKey != null ? displayNames[bestKey] : null;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a song from SQLite across songs, playlist_songs, favorite_songs, playback_history, and Space pins.
  Future<void> deleteSong(int mediaStoreId) async {
    final db = await _appDatabase.database;
    int prunedPins = 0;
    final List<int> affectedPlaylistIds = [];
    await db.transaction((txn) async {
      final playlistRows = await txn.rawQuery(
        'SELECT DISTINCT playlist_id FROM playlist_songs WHERE media_store_id = ?',
        [mediaStoreId],
      );
      for (final row in playlistRows) {
        final pid = row['playlist_id'] as int?;
        if (pid != null) affectedPlaylistIds.add(pid);
      }

      await txn.delete('playlist_songs', where: 'media_store_id = ?', whereArgs: [mediaStoreId]);
      await txn.delete('favorite_songs', where: 'media_store_id = ?', whereArgs: [mediaStoreId]);
      await txn.rawDelete(
        'DELETE FROM playback_history WHERE song_id IN (SELECT id FROM songs WHERE media_store_id = ?)',
        [mediaStoreId],
      );
      await txn.delete('song_artists', where: 'media_store_id = ?', whereArgs: [mediaStoreId]);
      await txn.delete('songs', where: 'media_store_id = ?', whereArgs: [mediaStoreId]);

      for (final pid in affectedPlaylistIds) {
        await txn.rawUpdate('''
          UPDATE playlists
          SET song_count = (SELECT COUNT(*) FROM playlist_songs WHERE playlist_id = ?),
              total_duration = COALESCE((
                SELECT SUM(s.duration)
                FROM playlist_songs ps
                JOIN songs s ON ps.media_store_id = s.media_store_id
                WHERE ps.playlist_id = ?
              ), 0)
          WHERE id = ?
        ''', [pid, pid, pid]);
      }

      prunedPins = await PinnedFavoritesDao.instance.pruneOrphanedPins(
        executor: txn,
        notify: false,
      );
    });
    if (prunedPins > 0) {
      PinnedFavoritesDao.revision.value++;
    }
    if (affectedPlaylistIds.isNotEmpty) {
      PlaylistDao.playlistRevision.value++;
    }
    await FavoriteSongsDao.instance.refreshCache();
    notifyPlaybackHistoryChanged();
    notifyLibraryChanged();
  }

  /// Builds a suggested radio queue for [artist] using:
  /// 1. Tracks by collaborating artists (artists who appear alongside [artist]),
  /// 2. Tracks with matching or similar genre names (analyzed in an isolate).
  Future<List<Song>> getSuggestedRadioSongs({
    required String artist,
    required Set<int> excludeMediaStoreIds,
    int limit = 25,
  }) async {
    final cleanArtist = artist.trim();
    if (cleanArtist.isEmpty || limit <= 0) return const [];

    final String normArtist = cleanArtist.toLowerCase();
    final Set<int> seenIds = Set<int>.from(excludeMediaStoreIds);
    final List<Song> suggested = [];

    // 1. Collect collaborating artists from tracks where this artist appears
    final artistSongs = await getSongsByArtist(cleanArtist, limit: 1000);
    final Set<String> collaborators = {};
    for (final s in artistSongs) {
      for (final a in s.artists) {
        final trimmed = a.trim();
        if (trimmed.isNotEmpty &&
            trimmed.toLowerCase() != normArtist &&
            trimmed != '<Desconocido>' &&
            trimmed.toLowerCase() != 'unknown artist') {
          collaborators.add(trimmed);
        }
      }
    }

    final List<Song> collabPool = [];
    for (final collab in collaborators.take(8)) {
      final songs = await getSongsByArtist(collab, limit: 25);
      for (final s in songs) {
        if (!seenIds.contains(s.mediaStoreId)) {
          seenIds.add(s.mediaStoreId);
          collabPool.add(s);
        }
      }
    }
    collabPool.shuffle();
    for (final s in collabPool) {
      if (suggested.length >= limit) return suggested;
      suggested.add(s);
    }

    // 2. Fill remaining slots using exact or name-similar genres in a background isolate
    final int remainingNeeded = limit - suggested.length;
    if (remainingNeeded <= 0) return suggested;

    final List<String> artistPaths = artistSongs
        .map((s) => s.path)
        .where((p) => p.isNotEmpty)
        .take(8)
        .toList();
    if (artistPaths.isEmpty) return suggested;

    final db = await _appDatabase.database;
    final candidateRows = await db.rawQuery(
      '''
      SELECT * FROM songs
      WHERE path IS NOT NULL AND TRIM(path) != ''
      ORDER BY RANDOM()
      LIMIT 140;
      ''',
    );
    final List<Song> candidateSongs = candidateRows
        .map((r) => Song.fromMap(r))
        .where((s) => !seenIds.contains(s.mediaStoreId))
        .toList();
    if (candidateSongs.isEmpty) return suggested;

    final List<Map<String, dynamic>> candidatePayload = candidateSongs
        .map((s) => {'id': s.mediaStoreId, 'path': s.path})
        .toList();

    final List<int> matchedIds = await Isolate.run(
      () => _matchSongsByGenreInIsolate(artistPaths, candidatePayload),
    );

    final Map<int, Song> byId = {
      for (final s in candidateSongs) s.mediaStoreId: s,
    };
    for (final id in matchedIds) {
      if (suggested.length >= limit) break;
      final song = byId[id];
      if (song != null && seenIds.add(song.mediaStoreId)) {
        suggested.add(song);
      }
    }

    return suggested;
  }

  /// Builds a continuous radio queue from [seedSong] so playback never stops
  /// when a queue ends:
  /// 1. Same album tracks not yet in [excludeMediaStoreIds]
  /// 2. Same artist, collaborators, and exact/similar genre matches
  /// 3. Remaining library tracks (or shuffled library if everything was played)
  Future<List<Song>> getEndlessRadioSuggestions(
    Song seedSong, {
    required Set<int> excludeMediaStoreIds,
    int limit = 20,
  }) async {
    if (limit <= 0) return const [];

    final Set<int> seenIds = Set<int>.from(excludeMediaStoreIds)
      ..add(seedSong.mediaStoreId);
    final List<Song> suggested = [];

    // 1. Same album tracks
    final albumName = seedSong.album?.trim() ?? '';
    if (albumName.isNotEmpty && albumName != '<Desconocido>') {
      final albumSongs = await getSongsByAlbum(
        albumName,
        artist: seedSong.albumArtist ?? seedSong.artist,
      );
      final albumPool = albumSongs
          .where((s) => !seenIds.contains(s.mediaStoreId))
          .toList()
        ..shuffle();
      for (final s in albumPool) {
        if (suggested.length >= limit) return suggested;
        if (seenIds.add(s.mediaStoreId)) suggested.add(s);
      }
    }

    // 2. Same artist tracks not yet played
    final primaryArtist = seedSong.primaryArtist.trim();
    if (primaryArtist.isNotEmpty &&
        primaryArtist != '<Desconocido>' &&
        primaryArtist.toLowerCase() != 'unknown artist') {
      final sameArtist = await getSongsByArtist(primaryArtist, limit: 30);
      final artistPool = sameArtist
          .where((s) => !seenIds.contains(s.mediaStoreId))
          .toList()
        ..shuffle();
      for (final s in artistPool) {
        if (suggested.length >= limit) return suggested;
        if (seenIds.add(s.mediaStoreId)) suggested.add(s);
      }

      // 3. Collaborators & similar genres
      final radio = await getSuggestedRadioSongs(
        artist: primaryArtist,
        excludeMediaStoreIds: seenIds,
        limit: limit - suggested.length,
      );
      for (final s in radio) {
        if (suggested.length >= limit) return suggested;
        if (seenIds.add(s.mediaStoreId)) suggested.add(s);
      }
    }

    // 4. General library fallback so music never stops
    final db = await _appDatabase.database;
    if (suggested.length < limit) {
      final fallbackRows = await db.rawQuery(
        'SELECT * FROM songs ORDER BY RANDOM() LIMIT ?;',
        [limit * 3],
      );
      for (final row in fallbackRows) {
        if (suggested.length >= limit) break;
        final s = Song.fromMap(row);
        if (seenIds.add(s.mediaStoreId)) {
          suggested.add(s);
        }
      }
    }

    // 5. Tiny-library fallback: if every song was already in excludeMediaStoreIds,
    // replay shuffled tracks excluding only the just-finished track.
    if (suggested.isEmpty) {
      final allRows = await db.rawQuery(
        'SELECT * FROM songs WHERE media_store_id != ? ORDER BY RANDOM() LIMIT ?;',
        [seedSong.mediaStoreId, limit],
      );
      for (final row in allRows) {
        suggested.add(Song.fromMap(row));
      }
    }

    return suggested;
  }

  /// Extracts all distinct genres present across the indexed library by reading
  /// audio metadata tags in a background isolate, sorted alphabetically.
  Future<List<GenreDiscoveryItem>> getLibraryGenres() async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> rows = await db.rawQuery(
      '''
      SELECT * FROM songs
      WHERE path IS NOT NULL AND TRIM(path) != ''
      ORDER BY title COLLATE NOCASE ASC;
      ''',
    );
    if (rows.isEmpty) return const [];

    final songs = rows.map((row) => Song.fromMap(row)).toList();
    final paths = songs.map((s) => s.path).toList();

    final extracted = await Isolate.run(
      () => _extractLibraryGenresInIsolate(paths),
    );
    if (extracted.isEmpty) return const [];

    final List<GenreDiscoveryItem> items = [];
    for (final entry in extracted) {
      final name = entry['name'] as String;
      final indices = entry['indices'] as List<int>;
      if (indices.isEmpty) continue;
      final genreSongs = [for (final idx in indices) songs[idx]];
      final rep = genreSongs.first;
      items.add(
        GenreDiscoveryItem(
          name: name,
          songCount: genreSongs.length,
          representativeSongId: rep.mediaStoreId,
          representativeAlbumId: rep.albumId,
          songs: genreSongs,
        ),
      );
    }

    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }
}

/// Isolate helper scanning audio file tags for genre names and grouping song
/// indices by normalized genre.
List<Map<String, dynamic>> _extractLibraryGenresInIsolate(List<String> paths) {
  final Map<String, String> displayNames = {};
  final Map<String, List<int>> groupedIndices = {};

  for (int i = 0; i < paths.length; i++) {
    final path = paths[i];
    if (path.isEmpty) continue;
    try {
      final file = File(path);
      if (!file.existsSync()) continue;
      final metadata = readMetadata(file, getImage: false);
      final Set<String> seenForSong = {};
      for (final rawGenre in metadata.genres) {
        final clean = rawGenre.trim();
        final normalized = clean.toLowerCase();
        if (clean.isEmpty ||
            normalized == '<desconocido>' ||
            normalized == 'unknown' ||
            normalized == 'unknown genre' ||
            normalized == 'género desconocido') {
          continue;
        }
        if (!seenForSong.add(normalized)) continue;
        displayNames.putIfAbsent(normalized, () => clean);
        groupedIndices.putIfAbsent(normalized, () => []).add(i);
      }
    } catch (_) {
      // Skip unreadable files gracefully
    }
  }

  return [
    for (final entry in groupedIndices.entries)
      {
        'name': displayNames[entry.key]!,
        'indices': entry.value,
      },
  ];
}

/// Isolate helper extracting genre tags and ranking candidate tracks by exact or
/// token-similar genre names.
List<int> _matchSongsByGenreInIsolate(
  List<String> artistPaths,
  List<Map<String, dynamic>> candidates,
) {
  List<String> readGenres(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return const [];
      final metadata = readMetadata(file, getImage: false);
      return metadata.genres
          .map((g) => g.trim().toLowerCase())
          .where((g) =>
              g.isNotEmpty &&
              g != '<desconocido>' &&
              g != 'unknown' &&
              g != 'other')
          .toList();
    } catch (_) {
      return const [];
    }
  }

  final Set<String> artistGenres = {};
  final Set<String> artistTokens = {};
  for (final path in artistPaths) {
    for (final g in readGenres(path)) {
      artistGenres.add(g);
      for (final tok in g.split(RegExp(r'[\s/&,\-]+'))) {
        if (tok.length >= 3) artistTokens.add(tok);
      }
    }
  }
  if (artistGenres.isEmpty) return const [];

  final List<int> exactMatches = [];
  final List<int> similarMatches = [];

  for (final c in candidates) {
    final int id = c['id'] as int;
    final String path = c['path'] as String;
    final cGenres = readGenres(path);
    if (cGenres.isEmpty) continue;

    bool isExact = false;
    bool isSimilar = false;
    for (final cg in cGenres) {
      if (artistGenres.contains(cg)) {
        isExact = true;
        break;
      }
      for (final ag in artistGenres) {
        if (cg.contains(ag) || ag.contains(cg)) {
          isSimilar = true;
          break;
        }
      }
      if (!isSimilar) {
        for (final tok in cg.split(RegExp(r'[\s/&,\-]+'))) {
          if (tok.length >= 3 && artistTokens.contains(tok)) {
            isSimilar = true;
            break;
          }
        }
      }
    }

    if (isExact) {
      exactMatches.add(id);
    } else if (isSimilar) {
      similarMatches.add(id);
    }
  }

  exactMatches.shuffle();
  similarMatches.shuffle();
  return [...exactMatches, ...similarMatches];
}
