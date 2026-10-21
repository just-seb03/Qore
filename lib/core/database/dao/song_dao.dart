/// File: song_dao.dart
/// Description: Data Access Object for the 'songs' table in SQLite.
/// Implements atomic batch synchronization and high-speed projection queries.
///
/// Components / Classes / Functions:
/// - SongDao: Data access class managing queries and atomic transactions for songs.
library;

import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
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

  // ==========================================
  // Section 4.2: Anti-N+1 Relational Discovery
  // ==========================================

  /// Retrieves aggregated artist statistics in a single relational query (Rule 4.2).
  /// Strictly eliminates N+1 loops by joining songs and playback_history in SQLite.
  Future<List<ArtistDiscoveryItem>> getDiscoveryArtists({int limit = 15}) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        s.artist AS name,
        COUNT(s.id) AS song_count,
        COUNT(DISTINCT s.album) AS album_count,
        MIN(s.media_store_id) AS representative_song_id,
        MIN(s.album_id) AS representative_album_id,
        MAX(ph.played_at) AS last_played
      FROM songs s
      LEFT JOIN playback_history ph ON s.artist = ph.artist COLLATE NOCASE
      WHERE s.artist IS NOT NULL AND s.artist != '' AND s.artist != '<Desconocido>'
      GROUP BY s.artist COLLATE NOCASE
      ORDER BY last_played DESC, song_count DESC
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
      WITH song_clean AS (
        SELECT
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          ph.played_at,
          NULLIF(NULLIF(TRIM(s.album_artist), ''), '<Desconocido>') AS raw_album_artist,
          CASE
            WHEN s.album_artist IS NOT NULL AND TRIM(s.album_artist) != '' AND s.album_artist != '<Desconocido>' AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
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
          END AS clean_artist
        FROM songs s
        LEFT JOIN playback_history ph ON s.id = ph.song_id
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
      )
      SELECT
        album AS name,
        COALESCE(MAX(raw_album_artist), clean_artist, 'Unknown Artist') AS artist,
        MIN(album_id) AS album_id,
        MIN(media_store_id) AS representative_song_id,
        COUNT(id) AS song_count,
        SUM(duration) AS total_duration,
        MAX(played_at) AS last_played
      FROM song_clean
      GROUP BY album COLLATE NOCASE, clean_artist COLLATE NOCASE
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
      WITH song_clean AS (
        SELECT
          s.id,
          s.album,
          s.album_id,
          s.media_store_id,
          s.duration,
          NULLIF(NULLIF(TRIM(s.album_artist), ''), '<Desconocido>') AS raw_album_artist,
          CASE
            WHEN s.album_artist IS NOT NULL AND TRIM(s.album_artist) != '' AND s.album_artist != '<Desconocido>' AND s.album_artist != 'Unknown Artist'
              THEN TRIM(s.album_artist)
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
          END AS clean_artist
        FROM songs s
        WHERE s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
      )
      SELECT
        album AS name,
        COALESCE(MAX(raw_album_artist), clean_artist, 'Unknown Artist') AS artist,
        MIN(album_id) AS album_id,
        MIN(media_store_id) AS representative_song_id,
        COUNT(id) AS song_count,
        SUM(duration) AS total_duration
      FROM song_clean
      GROUP BY album COLLATE NOCASE, clean_artist COLLATE NOCASE
      ORDER BY album COLLATE NOCASE ASC;
      ''',
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves all distinct artists in the user's library, ordered alphabetically.
  Future<List<ArtistDiscoveryItem>> getLibraryArtists() async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        s.artist AS name,
        COUNT(s.id) AS song_count,
        COUNT(DISTINCT s.album) AS album_count,
        MIN(s.media_store_id) AS representative_song_id,
        MIN(s.album_id) AS representative_album_id
      FROM songs s
      WHERE s.artist IS NOT NULL AND s.artist != '' AND s.artist != '<Desconocido>'
      GROUP BY s.artist COLLATE NOCASE
      ORDER BY s.artist COLLATE NOCASE ASC;
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
  }

  /// Retrieves recently played tracks using a single relational JOIN query.
  Future<List<Song>> getRecentlyPlayedSongs({int limit = 15}) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT s.*
      FROM playback_history ph
      JOIN songs s ON ph.song_id = s.id
      ORDER BY ph.played_at DESC
      LIMIT ?;
      ''',
      [limit],
    );

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves up to [limit] songs belonging to [artist], ordered by title.
  Future<List<Song>> getSongsByArtist(String artist, {int limit = 5}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      'songs',
      where: 'artist = ? COLLATE NOCASE',
      whereArgs: [artist],
      orderBy: 'title COLLATE NOCASE ASC',
      limit: limit,
    );
    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves the top [limit] most played songs for an artist.
  /// Falls back to recent tracks by date if user playback history is sparse.
  Future<List<Song>> getTopSongsByArtist(String artist, {int limit = 3}) async {
    final db = await _appDatabase.database;

    // 1. Fetch songs with playback history count
    final List<Map<String, dynamic>> historyResults = await db.rawQuery(
      '''
      SELECT s.*, COUNT(ph.id) AS play_count
      FROM songs s
      JOIN playback_history ph ON s.id = ph.song_id
      WHERE s.artist = ? COLLATE NOCASE
      GROUP BY s.id
      ORDER BY play_count DESC, s.title COLLATE NOCASE ASC
      LIMIT ?;
      ''',
      [artist, limit],
    );

    final List<Song> topSongs =
        historyResults.map((row) => Song.fromMap(row)).toList();

    // 2. Fall back to artist songs if playback history has fewer than limit
    if (topSongs.length < limit) {
      final existingIds = topSongs.map((s) => s.id ?? s.mediaStoreId).toSet();

      final List<Map<String, dynamic>> fallbackResults = await db.query(
        'songs',
        where: 'artist = ? COLLATE NOCASE',
        whereArgs: [artist],
        orderBy: 'date_modified DESC, title COLLATE NOCASE ASC',
        limit: limit * 2,
      );

      for (final row in fallbackResults) {
        final song = Song.fromMap(row);
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
  Future<List<AlbumDiscoveryItem>> getAlbumsByArtist(String artist) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT 
        s.album AS name,
        COALESCE(NULLIF(TRIM(s.album_artist), ''), s.artist, ?) AS artist,
        MIN(s.album_id) AS album_id,
        MIN(s.media_store_id) AS representative_song_id,
        COUNT(s.id) AS song_count,
        SUM(s.duration) AS total_duration,
        MAX(ph.played_at) AS last_played
      FROM songs s
      LEFT JOIN playback_history ph ON s.id = ph.song_id
      WHERE (s.artist = ? COLLATE NOCASE OR s.album_artist = ? COLLATE NOCASE)
        AND s.album IS NOT NULL AND s.album != '' AND s.album != '<Desconocido>'
      GROUP BY s.album COLLATE NOCASE
      ORDER BY s.album COLLATE NOCASE ASC;
      ''',
      [artist, artist, artist],
    );

    return results.map((row) => AlbumDiscoveryItem.fromMap(row)).toList();
  }

  /// Retrieves up to [limit] assorted songs for [artist] ordered by modification/addition date.
  Future<List<Song>> getAssortedSongsByArtist(String artist, {int limit = 10}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results = await db.query(
      'songs',
      where: 'artist = ? COLLATE NOCASE',
      whereArgs: [artist],
      orderBy: 'date_modified DESC, date_added DESC, title COLLATE NOCASE ASC',
      limit: limit,
    );
    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Retrieves songs belonging to [album], optionally scoped to [artist] or [albumId].
  /// Matches against `album_artist` first, falling back to `artist` when `album_artist` is null.
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

    if (hasArtist) {
      where =
          "album = ? COLLATE NOCASE AND ("
          "album_artist = ? COLLATE NOCASE "
          "OR artist = ? COLLATE NOCASE "
          "OR artist LIKE ? COLLATE NOCASE "
          "OR ("
          "album_artist IS NULL AND ("
          "INSTR(LOWER(artist), ' feat. ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' feat. ') - 1)) = ? COLLATE NOCASE "
          "OR INSTR(LOWER(artist), ' ft. ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' ft. ') - 1)) = ? COLLATE NOCASE "
          "OR INSTR(LOWER(artist), ' & ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ' & ') - 1)) = ? COLLATE NOCASE "
          "OR INSTR(LOWER(artist), ', ') > 0 AND TRIM(SUBSTR(artist, 1, INSTR(LOWER(artist), ', ') - 1)) = ? COLLATE NOCASE"
          ")"
          ")"
          ")";
      whereArgs = [album, artist, artist, '$artist%', artist, artist, artist, artist];
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
      orderBy: 'CASE WHEN track_number IS NOT NULL AND track_number > 0 THEN track_number ELSE 999999 END ASC, path ASC, title COLLATE NOCASE ASC',
      limit: limit,
    );

    final songs = results.map((row) => Song.fromMap(row)).toList();

    // Natural sort prioritizing trackNumber (from tags/MediaStore),
    // fallback to regex on filename/title, and finally alphabetical on title.
    songs.sort((a, b) {
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

  /// Retrieves unique artists for search dictionary indexing.
  Future<List<ArtistDiscoveryItem>> getAllUniqueArtists({int limit = 1000}) =>
      getDiscoveryArtists(limit: limit);

  /// Retrieves unique albums for search dictionary indexing.
  Future<List<AlbumDiscoveryItem>> getAllUniqueAlbums({int limit = 1000}) =>
      getDiscoveryAlbums(limit: limit);
}
