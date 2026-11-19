import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/localization/localization_controller.dart';
import 'package:project_anima/core/scanner/models/indexing_result.dart';
import 'package:project_anima/core/theme/controllers/theme_controller.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/settings/screens/settings_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _testDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_settings_test_');
    final dbPath = p.join(tempDir.path, 'test_anima.db');
    appDatabase = AppDatabase.instance;
    await appDatabase.initDatabase(customPath: dbPath);

    ThemeController.instance.setDarkMode(true);
    LocalizationController.instance.setLocale(AppLocale.es);
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Metro SettingsScreen Tests', () {
    testWidgets('renders Metro header, AmbientParticlesCanvas, and switches Theme & Language immediately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: LocalizationController.instance.currentLocale,
          home: SettingsScreen(appDatabase: appDatabase),
        ),
      );
      await tester.pump();

      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(ThemeController.instance.isDarkMode, isTrue);

      // Switch to Light theme immediately
      await tester.tap(find.byKey(const ValueKey('settings_theme_light')));
      await tester.pump();
      expect(ThemeController.instance.isDarkMode, isFalse);

      // Switch to Dark theme immediately
      await tester.tap(find.byKey(const ValueKey('settings_theme_dark')));
      await tester.pump();
      expect(ThemeController.instance.isDarkMode, isTrue);

      // System language button was removed; only Español and English remain
      expect(find.byKey(const ValueKey('settings_lang_system')), findsNothing);
      expect(find.byKey(const ValueKey('settings_lang_es')), findsOneWidget);
      expect(find.byKey(const ValueKey('settings_lang_en')), findsOneWidget);

      // Switch language to English immediately
      await tester.tap(find.byKey(const ValueKey('settings_lang_en')));
      await tester.pump();
      expect(LocalizationController.instance.currentAppLocale, AppLocale.en);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Quick Rescan triggers UI restart when changes are detected', (tester) async {
      bool restarted = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: SettingsScreen(
            appDatabase: appDatabase,
            onQuickRescan: () async => IndexingResult(
              addedCount: 3,
              updatedCount: 0,
              deletedCount: 0,
              totalSongs: 10,
              elapsedMilliseconds: 12,
            ),
            onUiRestartRequested: () => restarted = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('settings_quick_rescan')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(restarted, isTrue);
    });

    test('SettingsScreen.resetUserData clears SQLite user tables without deleting songs', () async {
      final db = await appDatabase.database;
      final songId = await db.insert(
        'songs',
        Song(
          mediaStoreId: 9001,
          title: 'Keep Me',
          artist: 'Artist',
          album: 'Album',
          duration: 180000,
          path: '/music/keep.mp3',
          dateModified: 100,
        ).toMap(),
      );
      await db.insert('playback_history', {
        'song_id': songId,
        'artist': 'Artist',
        'played_at': 1000,
      });
      await db.insert('recent_searches', {
        'entity_type': 'song',
        'entity_key': '9001',
        'title': 'Keep Me',
        'subtitle': 'Artist',
        'representative_song_id': 9001,
        'searched_at': 1000,
      });

      await SettingsScreen.resetUserData(appDatabase: appDatabase);

      final historyRows = await db.query('playback_history');
      final searchRows = await db.query('recent_searches');
      final songRows = await db.query('songs');
      expect(historyRows, isEmpty);
      expect(searchRows, isEmpty);
      expect(songRows.length, 1);
    });

    testWidgets('Reset User Data shows confirmation dialog and triggers UI restart', (tester) async {
      bool resetCalled = false;
      bool restarted = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: SettingsScreen(
            appDatabase: appDatabase,
            onResetUserData: () async {
              resetCalled = true;
            },
            onUiRestartRequested: () => restarted = true,
          ),
        ),
      );
      await tester.pump();

      // Tap reset button -> opens Metro confirmation dialog
      await tester.tap(find.byKey(const ValueKey('settings_reset_user_data')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('confirm_reset_user_data_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm_reset_user_data_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(resetCalled, isTrue);
      expect(restarted, isTrue);
    });
  });
}
