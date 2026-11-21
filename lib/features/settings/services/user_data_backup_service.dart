/// File: user_data_backup_service.dart
/// Description: Serializes and restores user statistics (playback history,
/// play counts, listening time), favorite songs, playlists, and Space pins
/// to/from JSON while safely skipping entries whose songs/albums/artists do
/// not exist in the current local library.
///
/// Components / Classes / Functions:
/// - UserDataImportResult: Summary counts of restored and skipped entries.
/// - UserDataBackupService: Export, import, and native Android SAF file I/O.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Result returned after restoring a user data JSON backup.
class UserDataImportResult {
  final int restoredPlays;
  final int skippedPlays;
  final int restoredFavorites;
  final int skippedFavorites;
  final int restoredPlaylists;
  final int restoredSpacePins;
  final int skippedSpacePins;

  const UserDataImportResult({
    required this.restoredPlays,
    required this.skippedPlays,
    required this.restoredFavorites,
    required this.skippedFavorites,
    required this.restoredPlaylists,
    required this.restoredSpacePins,
    required this.skippedSpacePins,
  });

  int get totalRestored =>
      restoredPlays + restoredFavorites + restoredPlaylists + restoredSpacePins;
}

/// Service handling JSON export/import of user statistics and Space data.
class UserDataBackupService {
  UserDataBackupService._();

  static const MethodChannel _channel =
      MethodChannel('project_anima/user_data_backup');

  static const String formatId = 'qore_user_data';
  static const int currentVersion = 1;

  /// Exports user statistics (`playback_history`), `favorite_songs`, `playlists`,
  /// `playlist_songs`, and Space (`pinned_favorites`) as a formatted JSON string.
  static Future<String> exportToJson({AppDatabase? appDatabase}) async {
    final db = await (appDatabase ?? AppDatabase.instance).database;

    // 1. Playback history joined with song identity for cross-device matching.
    final historyRows = await db.rawQuery('''
      SELECT
        ph.played_at,
        ph.artist AS history_artist,
        s.media_store_id,
        s.title,
        s.artist,
        s.album,
        s.duration,
        s.path
      FROM playback_history ph
      INNER JOIN songs s ON s.id = ph.song_id
      ORDER BY ph.played_at ASC
    ''');

    // 2. Favorite songs
    final favoriteRows = await db.query(
      'favorite_songs',
      orderBy: 'favorited_at DESC',
    );

    // 3. Playlists & their ordered tracks joined with songs
    final playlistRows = await db.query('playlists', orderBy: 'id ASC');
    final List<Map<String, dynamic>> exportedPlaylists = [];
    for (final pl in playlistRows) {
      final int plId = pl['id'] as int;
      final trackRows = await db.rawQuery(
        '''
        SELECT
          ps.media_store_id,
          ps.track_order,
          ps.added_at,
          s.title,
          s.artist,
          s.album,
          s.path
        FROM playlist_songs ps
        LEFT JOIN songs s ON s.id = ps.song_id OR s.media_store_id = ps.media_store_id
        WHERE ps.playlist_id = ?
        GROUP BY ps.id
        ORDER BY ps.track_order ASC
        ''',
        [plId],
      );
      exportedPlaylists.add({
        'original_id': plId,
        'name': pl['name'],
        'cover_path': pl['cover_path'],
        'font_family': pl['font_family'],
        'text_align_x': pl['text_align_x'],
        'text_align_y': pl['text_align_y'],
        'text_color': pl['text_color'],
        'text_gradient_color': pl['text_gradient_color'],
        'font_size': pl['font_size'],
        'text_effect': pl['text_effect'],
        'created_at': pl['created_at'],
        'updated_at': pl['updated_at'],
        'tracks': trackRows
            .map(
              (t) => {
                'media_store_id': t['media_store_id'],
                'track_order': t['track_order'],
                'added_at': t['added_at'],
                'title': t['title'],
                'artist': t['artist'],
                'album': t['album'],
                'path': t['path'],
              },
            )
            .toList(),
      });
    }

    // 4. Space (pinned_favorites)
    final spaceRows = await db.rawQuery('''
      SELECT
        pf.*,
        s.title AS rep_title,
        s.artist AS rep_artist,
        s.album AS rep_album,
        s.path AS rep_path,
        p.name AS playlist_name
      FROM pinned_favorites pf
      LEFT JOIN songs s ON s.media_store_id = pf.representative_song_id
      LEFT JOIN playlists p ON p.id = pf.playlist_id
      ORDER BY pf.pinned_at DESC
    ''');

    final payload = <String, dynamic>{
      'format': formatId,
      'version': currentVersion,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'playback_history': historyRows
          .map(
            (r) => {
              'played_at': r['played_at'],
              'history_artist': r['history_artist'],
              'media_store_id': r['media_store_id'],
              'title': r['title'],
              'artist': r['artist'],
              'album': r['album'],
              'duration': r['duration'],
              'path': r['path'],
            },
          )
          .toList(),
      'favorite_songs': favoriteRows
          .map(
            (r) => {
              'media_store_id': r['media_store_id'],
              'title': r['title'],
              'artist': r['artist'],
              'album': r['album'],
              'album_artist': r['album_artist'],
              'album_id': r['album_id'],
              'duration': r['duration'],
              'path': r['path'],
              'date_modified': r['date_modified'],
              'track_number': r['track_number'],
              'disc_number': r['disc_number'],
              'favorited_at': r['favorited_at'],
            },
          )
          .toList(),
      'playlists': exportedPlaylists,
      'space_pins': spaceRows
          .map(
            (r) => {
              'item_type': r['item_type'],
              'item_key': r['item_key'],
              'title': r['title'],
              'subtitle': r['subtitle'],
              'representative_song_id': r['representative_song_id'],
              'album_id': r['album_id'],
              'playlist_id': r['playlist_id'],
              'playlist_name': r['playlist_name'],
              'cover_path': r['cover_path'],
              'font_family': r['font_family'],
              'text_align_x': r['text_align_x'],
              'text_align_y': r['text_align_y'],
              'text_color': r['text_color'],
              'text_gradient_color': r['text_gradient_color'],
              'font_size': r['font_size'],
              'text_effect': r['text_effect'],
              'pinned_at': r['pinned_at'],
              'rep_title': r['rep_title'],
              'rep_artist': r['rep_artist'],
              'rep_album': r['rep_album'],
              'rep_path': r['rep_path'],
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Imports user statistics and Space data from [jsonString].
  /// Any song, album, artist, or playlist item that does not match an existing
  /// local library item is skipped cleanly.
  static Future<UserDataImportResult> importFromJson(
    String jsonString, {
    AppDatabase? appDatabase,
  }) async {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic> || decoded['format'] != formatId) {
      throw const FormatException('Invalid Qore user data backup format.');
    }

    final db = await (appDatabase ?? AppDatabase.instance).database;

    // Load local songs once into fast lookup maps to match imported items without N+1 queries.
    final localSongs = await db.query('songs');
    final Map<int, Map<String, dynamic>> byMediaStoreId = {};
    final Map<String, Map<String, dynamic>> byPath = {};
    final Map<String, Map<String, dynamic>> byMetadataKey = {};
    final Map<String, Map<String, dynamic>> byTitleDuration = {};
    final Set<String> localAlbums = {};
    final Map<int, Map<String, dynamic>> albumRepById = {};
    final Map<String, Map<String, dynamic>> albumRepByName = {};
    final Set<String> localArtists = {};
    final Map<String, Map<String, dynamic>> artistRepByName = {};

    for (final s in localSongs) {
      final int? msId = s['media_store_id'] as int?;
      if (msId != null) byMediaStoreId[msId] = s;

      final String? path = s['path'] as String?;
      if (path != null && path.isNotEmpty) {
        byPath[path] = s;
      }

      final String title = _norm(s['title']);
      final String artist = _norm(s['artist']);
      final String album = _norm(s['album']);
      final int duration = (s['duration'] as num?)?.toInt() ?? 0;

      if (title.isNotEmpty) {
        byMetadataKey.putIfAbsent('$title|$artist|$album', () => s);
        byTitleDuration.putIfAbsent('$title|$duration', () => s);
      }

      if (album.isNotEmpty && album != '<desconocido>') {
        localAlbums.add(album);
        albumRepByName.putIfAbsent(album, () => s);
        final int? albId = s['album_id'] as int?;
        if (albId != null) {
          albumRepById.putIfAbsent(albId, () => s);
        }
      }

      final String albumArtist = _norm(s['album_artist']);
      for (final candidate in [artist, albumArtist]) {
        if (candidate.isNotEmpty &&
            candidate != '<desconocido>' &&
            candidate != 'unknown artist') {
          localArtists.add(candidate);
          artistRepByName.putIfAbsent(candidate, () => s);
        }
      }
    }

    // Also include multi-artist relational table if present
    final songArtistRows = await db.query('song_artists');
    for (final row in songArtistRows) {
      final String artistName = _norm(row['artist']);
      if (artistName.isNotEmpty) {
        localArtists.add(artistName);
        if (!artistRepByName.containsKey(artistName)) {
          final int? msId = row['media_store_id'] as int?;
          if (msId != null && byMediaStoreId.containsKey(msId)) {
            artistRepByName[artistName] = byMediaStoreId[msId]!;
          }
        }
      }
    }

    Map<String, dynamic>? matchLocalSong({
      dynamic mediaStoreId,
      dynamic path,
      dynamic title,
      dynamic artist,
      dynamic album,
      dynamic duration,
    }) {
      if (mediaStoreId is int && byMediaStoreId.containsKey(mediaStoreId)) {
        return byMediaStoreId[mediaStoreId];
      }
      if (path is String && path.isNotEmpty && byPath.containsKey(path)) {
        return byPath[path];
      }
      final String normTitle = _norm(title);
      if (normTitle.isNotEmpty) {
        final key = '$normTitle|${_norm(artist)}|${_norm(album)}';
        if (byMetadataKey.containsKey(key)) {
          return byMetadataKey[key];
        }
        if (duration is int && duration > 0) {
          final tdKey = '$normTitle|$duration';
          if (byTitleDuration.containsKey(tdKey)) {
            return byTitleDuration[tdKey];
          }
        }
      }
      return null;
    }

    int restoredPlays = 0;
    int skippedPlays = 0;
    int restoredFavorites = 0;
    int skippedFavorites = 0;
    int restoredPlaylists = 0;
    int restoredSpacePins = 0;
    int skippedSpacePins = 0;

    await db.transaction((txn) async {
      // Existing playback history set to prevent duplicate rows on re-import
      final existingHistory = await txn.query(
        'playback_history',
        columns: ['song_id', 'played_at'],
      );
      final Set<String> existingPlayKeys = {
        for (final r in existingHistory) '${r['song_id']}_${r['played_at']}',
      };

      // 1. Restore playback_history
      final historyList = decoded['playback_history'];
      if (historyList is List) {
        final batch = txn.batch();
        for (final item in historyList) {
          if (item is! Map) continue;
          final matched = matchLocalSong(
            mediaStoreId: item['media_store_id'],
            path: item['path'],
            title: item['title'],
            artist: item['artist'],
            album: item['album'],
            duration: item['duration'],
          );
          if (matched == null) {
            skippedPlays++;
            continue;
          }
          final int localSongId = matched['id'] as int;
          final int playedAt =
              (item['played_at'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch;
          final String dedupKey = '${localSongId}_$playedAt';
          if (existingPlayKeys.contains(dedupKey)) {
            continue;
          }
          existingPlayKeys.add(dedupKey);
          batch.insert('playback_history', {
            'song_id': localSongId,
            'artist':
                (item['history_artist'] as String?) ??
                (matched['artist'] as String?),
            'played_at': playedAt,
          });
          restoredPlays++;
        }
        await batch.commit(noResult: true);
      }

      // 2. Restore favorite_songs
      final favList = decoded['favorite_songs'];
      if (favList is List) {
        for (final item in favList) {
          if (item is! Map) continue;
          final matched = matchLocalSong(
            mediaStoreId: item['media_store_id'],
            path: item['path'],
            title: item['title'],
            artist: item['artist'],
            album: item['album'],
            duration: item['duration'],
          );
          if (matched == null) {
            skippedFavorites++;
            continue;
          }
          final int? localMsId = matched['media_store_id'] as int?;
          if (localMsId == null) {
            skippedFavorites++;
            continue;
          }
          await txn.insert(
            'favorite_songs',
            {
              'media_store_id': localMsId,
              'title': matched['title'] ?? item['title'] ?? '',
              'artist': matched['artist'],
              'album': matched['album'],
              'album_artist': matched['album_artist'],
              'album_id': matched['album_id'],
              'duration': matched['duration'] ?? 0,
              'path': matched['path'] ?? '',
              'date_modified': matched['date_modified'],
              'track_number': matched['track_number'],
              'disc_number': matched['disc_number'],
              'favorited_at':
                  (item['favorited_at'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          restoredFavorites++;
        }
      }

      // 3. Restore playlists & tracks (mapping original_id / name -> local playlist_id)
      final Map<int, int> importedPlaylistIdMap = {};
      final Map<String, int> localPlaylistIdByName = {};
      final existingPlaylists = await txn.query('playlists', columns: ['id', 'name']);
      for (final p in existingPlaylists) {
        final name = _norm(p['name']);
        if (name.isNotEmpty) {
          localPlaylistIdByName[name] = p['id'] as int;
        }
      }

      final playlistsList = decoded['playlists'];
      if (playlistsList is List) {
        for (final pl in playlistsList) {
          if (pl is! Map) continue;
          final String plName = (pl['name'] as String?)?.trim() ?? '';
          if (plName.isEmpty) continue;

          final List rawTracks = (pl['tracks'] as List?) ?? const [];
          final List<Map<String, dynamic>> matchedTracks = [];
          for (final t in rawTracks) {
            if (t is! Map) continue;
            final matched = matchLocalSong(
              mediaStoreId: t['media_store_id'],
              path: t['path'],
              title: t['title'],
              artist: t['artist'],
              album: t['album'],
            );
            if (matched != null && matched['media_store_id'] != null) {
              matchedTracks.add({
                'song': matched,
                'track_order': t['track_order'],
                'added_at': t['added_at'],
              });
            }
          }

          // Skip playlists whose tracks are all missing from the user's library
          // unless the playlist already exists locally.
          final String normPlName = _norm(plName);
          int? targetPlaylistId = localPlaylistIdByName[normPlName];
          if (targetPlaylistId == null && matchedTracks.isEmpty && rawTracks.isNotEmpty) {
            continue;
          }

          if (targetPlaylistId == null) {
            final String? coverPath = pl['cover_path'] as String?;
            final validCover =
                coverPath != null && File(coverPath).existsSync() ? coverPath : null;
            final int now = DateTime.now().millisecondsSinceEpoch;
            targetPlaylistId = await txn.insert('playlists', {
              'name': plName,
              'cover_path': validCover,
              'font_family': pl['font_family'],
              'text_align_x': pl['text_align_x'] ?? 0.0,
              'text_align_y': pl['text_align_y'] ?? 0.0,
              'text_color': pl['text_color'] ?? 4294967295,
              'text_gradient_color': pl['text_gradient_color'],
              'font_size': pl['font_size'] ?? 26.0,
              'text_effect': pl['text_effect'] ?? 'none',
              'created_at': (pl['created_at'] as num?)?.toInt() ?? now,
              'updated_at': (pl['updated_at'] as num?)?.toInt() ?? now,
            });
            localPlaylistIdByName[normPlName] = targetPlaylistId;
            restoredPlaylists++;
          }

          final int? origId = (pl['original_id'] as num?)?.toInt();
          if (origId != null) {
            importedPlaylistIdMap[origId] = targetPlaylistId;
          }

          // Insert matched tracks not yet in target playlist
          final existingTrackRows = await txn.query(
            'playlist_songs',
            columns: ['media_store_id'],
            where: 'playlist_id = ?',
            whereArgs: [targetPlaylistId],
          );
          final Set<int> existingMsIds = {
            for (final r in existingTrackRows)
              if (r['media_store_id'] is int) r['media_store_id'] as int,
          };

          int nextOrder = existingMsIds.length;
          for (final mt in matchedTracks) {
            final Map<String, dynamic> song =
                mt['song'] as Map<String, dynamic>;
            final int msId = song['media_store_id'] as int;
            if (existingMsIds.contains(msId)) continue;
            existingMsIds.add(msId);
            await txn.insert('playlist_songs', {
              'playlist_id': targetPlaylistId,
              'song_id': song['id'],
              'media_store_id': msId,
              'track_order': nextOrder++,
              'added_at':
                  (mt['added_at'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
      }

      // 4. Restore Space (pinned_favorites), skipping items missing in local library
      final spaceList = decoded['space_pins'];
      if (spaceList is List) {
        for (final pin in spaceList) {
          if (pin is! Map) continue;
          final String itemType = (pin['item_type'] as String?) ?? '';
          final String itemKey = (pin['item_key'] as String?) ?? '';
          final String title = (pin['title'] as String?) ?? '';
          if (itemType.isEmpty || itemKey.isEmpty || title.isEmpty) {
            skippedSpacePins++;
            continue;
          }

          int? resolvedRepSongId = (pin['representative_song_id'] as num?)?.toInt();
          int? resolvedAlbumId = (pin['album_id'] as num?)?.toInt();
          int? resolvedPlaylistId = (pin['playlist_id'] as num?)?.toInt();

          if (itemType == 'album') {
            Map<String, dynamic>? repSong;
            if (resolvedAlbumId != null &&
                albumRepById.containsKey(resolvedAlbumId)) {
              repSong = albumRepById[resolvedAlbumId];
            } else if (albumRepByName.containsKey(_norm(title))) {
              repSong = albumRepByName[_norm(title)];
            }
            if (repSong == null) {
              skippedSpacePins++;
              continue;
            }
            resolvedRepSongId = repSong['media_store_id'] as int?;
            resolvedAlbumId = repSong['album_id'] as int?;
          } else if (itemType == 'artist') {
            final repSong = artistRepByName[_norm(title)];
            if (repSong == null) {
              skippedSpacePins++;
              continue;
            }
            resolvedRepSongId = repSong['media_store_id'] as int?;
          } else if (itemType == 'playlist') {
            final String plName = _norm(pin['playlist_name'] ?? title);
            final int? mappedById =
                resolvedPlaylistId != null
                    ? importedPlaylistIdMap[resolvedPlaylistId]
                    : null;
            final int? mappedByName = localPlaylistIdByName[plName];
            resolvedPlaylistId = mappedById ?? mappedByName;
            if (resolvedPlaylistId == null) {
              skippedSpacePins++;
              continue;
            }
          } else {
            // Track / generic item with representative song
            final repSong = matchLocalSong(
              mediaStoreId: pin['representative_song_id'],
              path: pin['rep_path'],
              title: pin['rep_title'] ?? title,
              artist: pin['rep_artist'] ?? pin['subtitle'],
              album: pin['rep_album'],
            );
            if (repSong == null) {
              skippedSpacePins++;
              continue;
            }
            resolvedRepSongId = repSong['media_store_id'] as int?;
            resolvedAlbumId = repSong['album_id'] as int?;
          }

          final String? coverPath = pin['cover_path'] as String?;
          final validCover =
              coverPath != null && File(coverPath).existsSync() ? coverPath : null;

          await txn.insert(
            'pinned_favorites',
            {
              'item_type': itemType,
              'item_key': itemKey,
              'title': title,
              'subtitle': pin['subtitle'],
              'representative_song_id': resolvedRepSongId,
              'album_id': resolvedAlbumId,
              'playlist_id': resolvedPlaylistId,
              'cover_path': validCover,
              'font_family': pin['font_family'],
              'text_align_x': pin['text_align_x'] ?? 0.0,
              'text_align_y': pin['text_align_y'] ?? 0.0,
              'text_color': pin['text_color'] ?? 4294967295,
              'text_gradient_color': pin['text_gradient_color'],
              'font_size': pin['font_size'] ?? 26.0,
              'text_effect': pin['text_effect'] ?? 'none',
              'pinned_at':
                  (pin['pinned_at'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          restoredSpacePins++;
        }
      }
    });

    await FavoriteSongsDao.instance.ensureLoaded();
    await PinnedFavoritesDao.instance.getAllPinned();
    SongDao.notifyPlaybackHistoryChanged();

    return UserDataImportResult(
      restoredPlays: restoredPlays,
      skippedPlays: skippedPlays,
      restoredFavorites: restoredFavorites,
      skippedFavorites: skippedFavorites,
      restoredPlaylists: restoredPlaylists,
      restoredSpacePins: restoredSpacePins,
      skippedSpacePins: skippedSpacePins,
    );
  }

  /// Opens the native Android SAF Save dialog and writes [jsonContent] to the chosen file.
  /// Returns `true` if saved, `false` if cancelled by the user.
  static Future<bool> exportWithSystemPicker(String jsonContent) async {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final fileName = 'qore_backup_$stamp.json';
    final saved = await _channel.invokeMethod<bool>('exportJsonFile', {
      'fileName': fileName,
      'content': jsonContent,
    });
    return saved ?? false;
  }

  /// Opens the native Android SAF Open dialog and returns the selected JSON file contents,
  /// or `null` if cancelled by the user.
  static Future<String?> importWithSystemPicker() async {
    return await _channel.invokeMethod<String>('importJsonFile');
  }

  static String _norm(dynamic value) {
    if (value == null) return '';
    return value.toString().trim().toLowerCase();
  }
}

