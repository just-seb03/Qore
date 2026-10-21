/// File: playback_session_dao.dart
/// Description: Data Access Object for persisting and restoring the active playback session
/// (track, seek position, queue ordering, and player settings) in SQLite.
///
/// Components / Classes / Functions:
/// - PlaybackSessionDao: DAO managing CRUD operations for the persistent playback session.
library;

import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/playback_session.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object managing playback session persistence in SQLite.
class PlaybackSessionDao {
  final AppDatabase _appDatabase;

  PlaybackSessionDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase.instance;

  /// Saves the active playback session snapshot to SQLite (overwriting row id = 1).
  Future<void> saveSession(PlaybackSession session) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'playback_session',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('PlaybackSessionDao error saving session: $e');
    }
  }

  /// Retrieves the last recorded playback session, or null if none exists.
  Future<PlaybackSession?> getLastSession() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, dynamic>> results = await db.query(
        'playback_session',
        where: 'id = 1',
        limit: 1,
      );
      if (results.isEmpty) return null;
      return PlaybackSession.fromMap(results.first);
    } catch (e) {
      debugPrint('PlaybackSessionDao error reading session: $e');
      return null;
    }
  }

  /// Clears the saved playback session (e.g. on full queue reset).
  Future<void> clearSession() async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        'playback_session',
        where: 'id = 1',
      );
    } catch (e) {
      debugPrint('PlaybackSessionDao error clearing session: $e');
    }
  }
}
