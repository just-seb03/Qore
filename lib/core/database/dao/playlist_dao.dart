/// File: playlist_dao.dart
/// Description: Data Access Object managing user playlists and ordered playlist songs.
/// Eliminates N+1 queries by aggregating track counts, durations, and cover fallback pointers.
///
/// Components / Classes / Functions:
/// - PlaylistDao: Data access class executing queries and transactions for Playlists.
library;

import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Data Access Object for persisting and retrieving user Playlists and their songs.
class PlaylistDao {
  final AppDatabase _appDatabase;

  PlaylistDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  /// Retrieves all user playlists, aggregated with track count, total duration,
  /// and the representative MediaStore ID of the first song.
  Future<List<Playlist>> getPlaylists() async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.cover_path,
        p.font_family,
        p.created_at,
        p.updated_at,
        COUNT(ps.id) AS song_count,
        COALESCE(SUM(s.duration), 0) AS total_duration,
        (
          SELECT ps2.media_store_id
          FROM playlist_songs ps2
          WHERE ps2.playlist_id = p.id
          ORDER BY ps2.track_order ASC
          LIMIT 1
        ) AS first_media_store_id
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      LEFT JOIN songs s ON ps.media_store_id = s.media_store_id
      GROUP BY p.id
      ORDER BY p.updated_at DESC, p.id DESC;
      ''',
    );

    return results.map((row) => Playlist.fromMap(row)).toList();
  }

  /// Retrieves a single playlist by [id] with its aggregated statistics.
  Future<Playlist?> getPlaylistById(int id) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        p.cover_path,
        p.font_family,
        p.created_at,
        p.updated_at,
        COUNT(ps.id) AS song_count,
        COALESCE(SUM(s.duration), 0) AS total_duration,
        (
          SELECT ps2.media_store_id
          FROM playlist_songs ps2
          WHERE ps2.playlist_id = p.id
          ORDER BY ps2.track_order ASC
          LIMIT 1
        ) AS first_media_store_id
      FROM playlists p
      LEFT JOIN playlist_songs ps ON p.id = ps.playlist_id
      LEFT JOIN songs s ON ps.media_store_id = s.media_store_id
      WHERE p.id = ?
      GROUP BY p.id;
      ''',
      [id],
    );

    if (results.isEmpty) return null;
    return Playlist.fromMap(results.first);
  }

  /// Retrieves songs belonging to [playlistId], strictly ordered by custom [track_order ASC].
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final db = await _appDatabase.database;

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
      SELECT s.*
      FROM playlist_songs ps
      JOIN songs s ON ps.media_store_id = s.media_store_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.track_order ASC;
      ''',
      [playlistId],
    );

    return results.map((row) => Song.fromMap(row)).toList();
  }

  /// Creates a new playlist with optional initial songs, custom cover path, and font family.
  Future<Playlist> createPlaylist(
    String name, {
    String? coverPath,
    String? fontFamily,
    List<Song>? songs,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.transaction((txn) async {
      // 1. Insert playlist record
      final playlistId = await txn.insert('playlists', {
        'name': name.trim().isEmpty ? 'Untitled Playlist' : name.trim(),
        'cover_path': coverPath,
        'font_family': fontFamily,
        'created_at': now,
        'updated_at': now,
      });

      // 2. Insert playlist tracks sequentially
      if (songs != null && songs.isNotEmpty) {
        for (int i = 0; i < songs.length; i++) {
          final song = songs[i];
          await txn.insert('playlist_songs', {
            'playlist_id': playlistId,
            'song_id': song.id,
            'media_store_id': song.mediaStoreId,
            'track_order': i,
            'added_at': now,
          });
        }
      }

      int totalDuration = 0;
      if (songs != null) {
        for (final s in songs) {
          totalDuration += s.duration;
        }
      }

      return Playlist(
        id: playlistId,
        name: name.trim().isEmpty ? 'Untitled Playlist' : name.trim(),
        coverPath: coverPath,
        fontFamily: fontFamily,
        createdAt: now,
        updatedAt: now,
        songCount: songs?.length ?? 0,
        totalDuration: totalDuration,
        firstMediaStoreId: songs?.isNotEmpty == true ? songs!.first.mediaStoreId : null,
      );
    });
  }

  /// Updates playlist metadata and rewrites its ordered track sequence.
  Future<void> updatePlaylist(
    int playlistId, {
    String? name,
    String? coverPath,
    String? fontFamily,
    List<Song>? songs,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // 1. Update playlist header
      final Map<String, dynamic> updateFields = {
        'updated_at': now,
      };
      if (name != null) updateFields['name'] = name.trim();
      if (coverPath != null) updateFields['cover_path'] = coverPath;
      if (fontFamily != null) updateFields['font_family'] = fontFamily;

      await txn.update(
        'playlists',
        updateFields,
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      // 2. Update song list and order if supplied
      if (songs != null) {
        await txn.delete(
          'playlist_songs',
          where: 'playlist_id = ?',
          whereArgs: [playlistId],
        );

        for (int i = 0; i < songs.length; i++) {
          final song = songs[i];
          await txn.insert('playlist_songs', {
            'playlist_id': playlistId,
            'song_id': song.id,
            'media_store_id': song.mediaStoreId,
            'track_order': i,
            'added_at': now,
          });
        }
      }
    });
  }

  /// Deletes a playlist and its track associations.
  Future<void> deletePlaylist(int playlistId) async {
    final db = await _appDatabase.database;
    await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }
}
