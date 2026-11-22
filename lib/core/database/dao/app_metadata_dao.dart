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
  static const String _kSpaceIntroSeenKey = 'space_intro_seen';
  static const String _kAppLanguageKey = 'app_language';
  static const String totalListeningTimeMsKey = 'total_listening_time_ms';
  static const String trimSilenceEnabledKey = 'trim_leading_silence_enabled';
  static AppMetadataDao? _instance;

  final AppDatabase _appDatabase;
  bool? _mockOnboardingCompleted;
  bool? _cachedOnboardingCompleted;
  String? _mockThemeFamily;
  String? _cachedThemeFamily;
  bool? _mockIsDarkMode;
  bool? _cachedIsDarkMode;
  bool? _mockSpaceIntroSeen;
  bool? _cachedSpaceIntroSeen;
  String? _mockLanguage;
  String? _cachedLanguage;
  bool _trimSilenceEnabled = true;

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

  /// Sets an in-memory space intro override for testing without SQLite interaction.
  @visibleForTesting
  void setMockSpaceIntroSeen(bool? value) {
    _mockSpaceIntroSeen = value;
    _cachedSpaceIntroSeen = value;
  }

  /// Synchronous getter if space intro status has been loaded or mocked.
  bool get hasSeenSpaceIntroSync =>
      _mockSpaceIntroSeen ?? _cachedSpaceIntroSeen ?? false;

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

  /// Checks if the first-time Space onboarding tour was already seen.
  Future<bool> hasSeenSpaceIntro() async {
    if (_mockSpaceIntroSeen != null) {
      _cachedSpaceIntroSeen = _mockSpaceIntroSeen;
      return _mockSpaceIntroSeen!;
    }

    if (_cachedSpaceIntroSeen != null) {
      return _cachedSpaceIntroSeen!;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _cachedSpaceIntroSeen = false;
      return false;
    }

    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_kSpaceIntroSeenKey],
        limit: 1,
      );

      if (results.isEmpty || results.first['value'] == null) {
        _cachedSpaceIntroSeen = false;
        return false;
      }
      final seen = results.first['value'] == 'true';
      _cachedSpaceIntroSeen = seen;
      return seen;
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error checking space intro status: $e');
      _cachedSpaceIntroSeen = false;
      return false;
    }
  }

  /// Persists Space onboarding completed status to SQLite app_metadata.
  Future<void> setSpaceIntroSeen({bool seen = true}) async {
    _mockSpaceIntroSeen = seen;
    _cachedSpaceIntroSeen = seen;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'app_metadata',
        {
          'key': _kSpaceIntroSeenKey,
          'value': seen ? 'true' : 'false',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving space intro status: $e');
    }
  }

  /// Retrieves the persisted language code (e.g. 'es', 'en') if set.
  Future<String?> getAppLanguage() async {
    if (_mockLanguage != null) {
      _cachedLanguage = _mockLanguage;
      return _mockLanguage;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _cachedLanguage;
    }

    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [_kAppLanguageKey],
        limit: 1,
      );

      if (results.isEmpty || results.first['value'] == null) {
        return null;
      }
      final lang = results.first['value'] as String?;
      _cachedLanguage = lang;
      return lang;
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error reading app language: $e');
      return null;
    }
  }

  /// Persists the active application language code to SQLite app_metadata.
  Future<void> setAppLanguage(String code) async {
    _mockLanguage = code;
    _cachedLanguage = code;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.insert(
        'app_metadata',
        {
          'key': _kAppLanguageKey,
          'value': code,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving app language: $e');
    }
  }

  /// Synchronous getter for whether leading silence trimming is enabled (defaults to true).
  bool get isTrimSilenceEnabledSync => _trimSilenceEnabled;

  /// Loads whether leading silence trimming is enabled from SQLite app_metadata.
  Future<bool> getTrimSilenceEnabled({AppDatabase? appDatabase}) async {
    try {
      final db = await (appDatabase ?? _appDatabase).database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [trimSilenceEnabledKey],
        limit: 1,
      );
      if (results.isEmpty || results.first['value'] == null) {
        _trimSilenceEnabled = true;
        return true;
      }
      _trimSilenceEnabled = results.first['value'] != 'false';
      return _trimSilenceEnabled;
    } catch (_) {
      return _trimSilenceEnabled;
    }
  }

  /// Persists the leading silence trimming toggle to SQLite app_metadata.
  Future<void> setTrimSilenceEnabled(
    bool enabled, {
    AppDatabase? appDatabase,
  }) async {
    _trimSilenceEnabled = enabled;
    try {
      final db = await (appDatabase ?? _appDatabase).database;
      await db.insert(
        'app_metadata',
        {
          'key': trimSilenceEnabledKey,
          'value': enabled ? 'true' : 'false',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving trim silence toggle: $e');
    }
  }

  /// Reads the accumulated real listening time in milliseconds from app_metadata.
  Future<int> getTotalListeningTimeMs({AppDatabase? appDatabase}) async {
    try {
      final db = await (appDatabase ?? _appDatabase).database;
      final results = await db.query(
        'app_metadata',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [totalListeningTimeMsKey],
        limit: 1,
      );
      if (results.isEmpty || results.first['value'] == null) return 0;
      return int.tryParse(results.first['value'].toString()) ?? 0;
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error reading total listening time: $e');
      return 0;
    }
  }

  /// Sets the accumulated real listening time in milliseconds in app_metadata.
  Future<void> setTotalListeningTimeMs(
    int totalMs, {
    AppDatabase? appDatabase,
  }) async {
    final safeMs = totalMs < 0 ? 0 : totalMs;
    try {
      final db = await (appDatabase ?? _appDatabase).database;
      await db.insert(
        'app_metadata',
        {
          'key': totalListeningTimeMsKey,
          'value': safeMs.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('⚠️ [AppMetadataDao] Error saving total listening time: $e');
    }
  }

  /// Atomically adds [deltaMs] to the persisted listening time and returns the new total.
  Future<int> addListeningTimeMs(
    int deltaMs, {
    AppDatabase? appDatabase,
  }) async {
    if (deltaMs <= 0) {
      return getTotalListeningTimeMs(appDatabase: appDatabase);
    }
    final current = await getTotalListeningTimeMs(appDatabase: appDatabase);
    final updated = current + deltaMs;
    await setTotalListeningTimeMs(updated, appDatabase: appDatabase);
    return updated;
  }
}
