/// File: app_metadata_dao.dart
/// Description: Data Access Object managing application-level configuration metadata
/// stored in SQLite table 'app_metadata' (e.g. initial onboarding completion status).
///
/// Components / Classes / Functions:
/// - AppMetadataDao: DAO providing CRUD access to the app_metadata table.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

/// DAO coordinating persistence of app lifecycle and setup flags into SQLite 'app_metadata'.
class AppMetadataDao {
  static const String _kOnboardingCompletedKey = 'onboarding_completed';
  static const String _kActiveThemeFamilyKey = 'active_theme_family';
  static const String _kIsDarkModeKey = 'is_dark_mode';
  static AppMetadataDao? _instance;

  final AppDatabase _appDatabase;
  bool? _mockOnboardingCompleted;
  bool? _cachedOnboardingCompleted;
  String? _mockThemeFamily;
  String? _cachedThemeFamily;
  bool? _mockIsDarkMode;
  bool? _cachedIsDarkMode;

  AppMetadataDao({
    AppDatabase? appDatabase,
    bool? mockOnboardingCompleted,
  })  : _appDatabase = appDatabase ?? AppDatabase.instance,
        _mockOnboardingCompleted = mockOnboardingCompleted ??
            (Platform.environment.containsKey('FLUTTER_TEST') ? null : null);

  /// Global shared instance.
  static AppMetadataDao get instance => _instance ??= AppMetadataDao();

  @visibleForTesting
  static void setMockInstance(AppMetadataDao? mockDao) {
    _instance = mockDao;
  }

  /// Sets an in-memory override for testing without SQLite interaction.
  @visibleForTesting
  void setMockOnboardingCompleted(bool? value) {
    _mockOnboardingCompleted = value;
    _cachedOnboardingCompleted = value;
  }

  /// Sets an in-memory theme override for testing.
  @visibleForTesting
  void setMockTheme({String? family, bool? isDark}) {
    _mockThemeFamily = family;
    _cachedThemeFamily = family;
    _mockIsDarkMode = isDark;
    _cachedIsDarkMode = isDark;
  }

  /// Synchronous getter if status has been loaded or mocked.
  bool get isOnboardingCompletedSync =>
      _mockOnboardingCompleted ?? _cachedOnboardingCompleted ?? false;

  /// Cached theme family if previously loaded.
  String? get cachedThemeFamily => _mockThemeFamily ?? _cachedThemeFamily;

  /// Cached dark mode flag if previously loaded.
  bool? get cachedIsDarkMode => _mockIsDarkMode ?? _cachedIsDarkMode;

  /// Checks if the first-time onboarding sequence (splash, permissions, theme)
  /// was already completed.
  Future<bool> isOnboardingCompleted() async {
    if (_mockOnboardingCompleted != null) {
      _cachedOnboardingCompleted = _mockOnboardingCompleted;
      return _mockOnboardingCompleted!;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _cachedOnboardingCompleted = false;
      return false;
    }

    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_kOnboardingCompletedKey],
        limit: 1,
      );

      if (results.isEmpty || results.first['value'] == null) {
        _cachedOnboardingCompleted = false;
        return false;
      }
      final completed = results.first['value'] == 'true';
      _cachedOnboardingCompleted = completed;
      return completed;
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error checking onboarding status: $e');
      _cachedOnboardingCompleted = false;
      return false;
    }
  }

  /// Persists onboarding status to SQLite.
  Future<void> setOnboardingCompleted({bool completed = true}) async {
    _mockOnboardingCompleted = completed;
    _cachedOnboardingCompleted = completed;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'app_metadata',
        {
          'key': _kOnboardingCompletedKey,
          'value': completed ? 'true' : 'false',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving onboarding status: $e');
    }
  }

  /// Retrieves the saved theme family identifier (e.g. 'monochrome', 'that_pad').
  Future<String?> getThemeFamily() async {
    if (_mockThemeFamily != null) {
      _cachedThemeFamily = _mockThemeFamily;
      return _mockThemeFamily;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _cachedThemeFamily;
    }

    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_kActiveThemeFamilyKey],
        limit: 1,
      );

      if (results.isEmpty || results.first['value'] == null) {
        return null;
      }
      final family = results.first['value'] as String?;
      _cachedThemeFamily = family;
      return family;
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error reading theme family: $e');
      return null;
    }
  }

  /// Persists the active theme family identifier to SQLite app_metadata.
  Future<void> setThemeFamily(String family) async {
    _mockThemeFamily = family;
    _cachedThemeFamily = family;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'app_metadata',
        {
          'key': _kActiveThemeFamilyKey,
          'value': family,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving theme family: $e');
    }
  }

  /// Retrieves whether dark mode is currently selected.
  Future<bool?> getIsDarkMode() async {
    if (_mockIsDarkMode != null) {
      _cachedIsDarkMode = _mockIsDarkMode;
      return _mockIsDarkMode;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _cachedIsDarkMode;
    }

    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_kIsDarkModeKey],
        limit: 1,
      );

      if (results.isEmpty || results.first['value'] == null) {
        return null;
      }
      final isDark = results.first['value'] == 'true';
      _cachedIsDarkMode = isDark;
      return isDark;
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error reading is_dark_mode: $e');
      return null;
    }
  }

  /// Persists dark mode flag to SQLite app_metadata.
  Future<void> setIsDarkMode(bool isDark) async {
    _mockIsDarkMode = isDark;
    _cachedIsDarkMode = isDark;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'app_metadata',
        {
          'key': _kIsDarkModeKey,
          'value': isDark ? 'true' : 'false',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving is_dark_mode: $e');
    }
  }
}
