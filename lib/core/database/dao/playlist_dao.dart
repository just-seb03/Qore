/// File: playlist_dao.dart
/// Description: Data Access Object managing user playlists and ordered playlist songs.
/// Eliminates N+1 queries by aggregating track counts, durations, and cover fallback pointers.
///
/// Components / Classes / Functions:
/// - PlaylistDao: Data access class executing queries and transactions for Playlists.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';

/// Data Access Object for persisting and retrieving user Playlists and their songs.
class PlaylistDao {
  /// Global change notifier incremented whenever playlists are created, updated, or deleted.
  /// Allows all playlist presentation widgets to reactively reload without app restarts.
  static final ValueNotifier<int> playlistRevision = ValueNotifier<int>(0);

  /// Dispatches a reactive update notification to all playlist listeners.
  static void notifyPlaylistsChanged() {
    playlistRevision.value++;
  }

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
        p.text_align_x,
        p.text_align_y,
        p.text_color,
        p.text_gradient_color,
        p.font_size,
        p.text_effect,
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
        p.text_align_x,
        p.text_align_y,
        p.text_color,
        p.text_gradient_color,
        p.font_size,
        p.text_effect,
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

  /// Creates a new playlist with optional initial songs, custom cover path, font family, and typography styling.
  Future<Playlist> createPlaylist(
    String name, {
    String? coverPath,
    String? fontFamily,
    double textAlignX = 0.0,
    double textAlignY = 0.0,
    int textColor = 0xFFFFFFFF,
    int? textGradientColor,
    double fontSize = 26.0,
    String textEffect = 'none',
    List<Song>? songs,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final result = await db.transaction((txn) async {
      // 1. Insert playlist record
      final playlistId = await txn.insert('playlists', {
        'name': name.trim().isEmpty ? 'Untitled Playlist' : name.trim(),
        'cover_path': coverPath,
        'font_family': fontFamily,
        'text_align_x': textAlignX,
        'text_align_y': textAlignY,
        'text_color': textColor,
        'text_gradient_color': textGradientColor,
        'font_size': fontSize,
        'text_effect': textEffect,
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
        textAlignX: textAlignX,
        textAlignY: textAlignY,
        textColor: textColor,
        textGradientColor: textGradientColor,
        fontSize: fontSize,
        textEffect: textEffect,
        createdAt: now,
        updatedAt: now,
        songCount: songs?.length ?? 0,
        totalDuration: totalDuration,
        firstMediaStoreId: songs?.isNotEmpty == true ? songs!.first.mediaStoreId : null,
      );
    });

    notifyPlaylistsChanged();
    PinnedFavoritesDao.revision.value++;
    return result;
  }

  /// Updates playlist metadata and rewrites its ordered track sequence.
  Future<void> updatePlaylist(
    int playlistId, {
    String? name,
    String? coverPath,
    String? fontFamily,
    double? textAlignX,
    double? textAlignY,
    int? textColor,
    int? textGradientColor,
    double? fontSize,
    String? textEffect,
    bool clearGradient = false,
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
      if (textAlignX != null) updateFields['text_align_x'] = textAlignX;
      if (textAlignY != null) updateFields['text_align_y'] = textAlignY;
      if (textColor != null) updateFields['text_color'] = textColor;
      if (fontSize != null) updateFields['font_size'] = fontSize;
      if (textEffect != null) updateFields['text_effect'] = textEffect;
      if (clearGradient) {
        updateFields['text_gradient_color'] = null;
      } else if (textGradientColor != null) {
        updateFields['text_gradient_color'] = textGradientColor;
      }

      await txn.update(
        'playlists',
        updateFields,
        where: 'id = ?',
        whereArgs: [playlistId],
      );

      // Sync changes to pinned_favorites if this playlist is pinned
      final Map<String, dynamic> pinnedUpdate = {};
      if (name != null) pinnedUpdate['title'] = name.trim();
      if (coverPath != null) pinnedUpdate['cover_path'] = coverPath;
      if (fontFamily != null) pinnedUpdate['font_family'] = fontFamily;
      if (textAlignX != null) pinnedUpdate['text_align_x'] = textAlignX;
      if (textAlignY != null) pinnedUpdate['text_align_y'] = textAlignY;
      if (textColor != null) pinnedUpdate['text_color'] = textColor;
      if (fontSize != null) pinnedUpdate['font_size'] = fontSize;
      if (textEffect != null) pinnedUpdate['text_effect'] = textEffect;
      if (clearGradient) {
        pinnedUpdate['text_gradient_color'] = null;
      } else if (textGradientColor != null) {
        pinnedUpdate['text_gradient_color'] = textGradientColor;
      }

      if (pinnedUpdate.isNotEmpty) {
        await txn.update(
          'pinned_favorites',
          pinnedUpdate,
          where: 'playlist_id = ?',
          whereArgs: [playlistId],
        );
      }

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

    notifyPlaylistsChanged();
    PinnedFavoritesDao.revision.value++;
  }

  /// Deletes a playlist, its track associations, and any pinned favorite reference.
  Future<void> deletePlaylist(int playlistId) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.delete(
        'playlist_songs',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'pinned_favorites',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );
      await txn.delete(
        'playlists',
        where: 'id = ?',
        whereArgs: [playlistId],
      );
    });

    notifyPlaylistsChanged();
    PinnedFavoritesDao.revision.value++;
  }
}
