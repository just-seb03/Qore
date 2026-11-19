import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/profile/screens/profile.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';
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
  late SongDao songDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_profile_test_');
    final dbPath = p.join(tempDir.path, 'test_anima.db');

    appDatabase = AppDatabase.instance;
    await appDatabase.initDatabase(customPath: dbPath);
    songDao = SongDao(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SongDao Global Profile Stats Tests', () {
    test('getTopSongsGlobal, getMostPlayedArtist, and getMostPlayedAlbum rank by play count', () async {
      final db = await appDatabase.database;

      final id1 = await db.insert(
        'songs',
        Song(
          mediaStoreId: 1001,
          title: 'Starlight',
          artist: 'Muse',
          album: 'Black Holes and Revelations',
          duration: 240000,
          path: '/music/starlight.mp3',
          dateModified: 100,
        ).toMap(),
      );
      final id2 = await db.insert(
        'songs',
        Song(
          mediaStoreId: 1002,
          title: 'Time',
          artist: 'Pink Floyd',
          album: 'The Dark Side of the Moon',
          duration: 420000,
          path: '/music/time.mp3',
          dateModified: 100,
        ).toMap(),
      );

      // 5 plays for Time (Pink Floyd / Dark Side), 2 plays for Starlight (Muse)
      for (int i = 0; i < 5; i++) {
        await songDao.recordPlayback(songId: id2, artist: 'Pink Floyd', timestampSeconds: 1000 + i);
      }
      for (int i = 0; i < 2; i++) {
        await songDao.recordPlayback(songId: id1, artist: 'Muse', timestampSeconds: 2000 + i);
      }

      final topSongs = await songDao.getTopSongsGlobal(limit: 5);
      expect(topSongs.length, 2);
      expect(topSongs.first.title, 'Time');
      expect(topSongs.last.title, 'Starlight');

      final topArtist = await songDao.getMostPlayedArtist();
      expect(topArtist, isNotNull);
      expect(topArtist!.name, 'Pink Floyd');

      final topAlbum = await songDao.getMostPlayedAlbum();
      expect(topAlbum, isNotNull);
      expect(topAlbum!.name, 'The Dark Side of the Moon');
      expect(topAlbum.artist, 'Pink Floyd');
    });
  });

  group('Metro ProfileScreen Widget Tests', () {
    testWidgets('renders Metro ProfileHeader, AmbientParticlesCanvas, top songs without counter, top artist, top album, and Settings button', (tester) async {
      final songs = [
        Song(
          mediaStoreId: 2001,
          title: 'Breathe',
          artist: 'Pink Floyd',
          album: 'The Dark Side of the Moon',
          duration: 163000,
          path: '/music/breathe.mp3',
          dateModified: 100,
        ),
      ];
      const topArtist = ArtistDiscoveryItem(
        name: 'Pink Floyd',
        songCount: 10,
        albumCount: 1,
        representativeSongId: 2001,
      );
      const topAlbum = AlbumDiscoveryItem(
        name: 'The Dark Side of the Moon',
        artist: 'Pink Floyd',
        representativeSongId: 2001,
        songCount: 10,
        totalDuration: 2570000,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: ProfileScreen(
            showBottomNav: false,
            initialTopSongs: songs,
            initialTopArtist: topArtist,
            initialTopAlbum: topAlbum,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('TOP CANCIONES'), findsOneWidget);
      expect(find.text('Breathe'), findsOneWidget);
      expect(find.text('ARTISTA MÁS ESCUCHADO'), findsOneWidget);
      expect(find.text('ÁLBUM MÁS ESCUCHADO'), findsOneWidget);
      expect(find.text('Pink Floyd'), findsAtLeastNWidgets(1));
      expect(find.text('The Dark Side of the Moon'), findsOneWidget);
      expect(find.byType(MaterialArtistAvatar), findsOneWidget);

      // Settings button exists and has sharp BorderRadius.zero
      final settingsFinder = find.byKey(const ValueKey('profile_settings_button'));
      expect(settingsFinder, findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
      final settingsInkWell = tester.widget<InkWell>(settingsFinder);
      expect(settingsInkWell.borderRadius, BorderRadius.zero);

      // Tapping Settings does not crash or navigate (non-functional for now)
      await tester.tap(settingsFinder);
      await tester.pump();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('tapping top artist navigates to ArtistDetailScreen and tapping top album navigates to AlbumDetailScreen', (tester) async {
      final songs = [
        Song(
          mediaStoreId: 3001,
          title: 'Echoes',
          artist: 'Pink Floyd',
          album: 'Meddle',
          duration: 1410000,
          path: '/music/echoes.mp3',
          dateModified: 100,
        ),
      ];
      const topArtist = ArtistDiscoveryItem(
        name: 'Pink Floyd',
        songCount: 6,
        albumCount: 1,
        representativeSongId: 3001,
      );
      const topAlbum = AlbumDiscoveryItem(
        name: 'Meddle',
        artist: 'Pink Floyd',
        representativeSongId: 3001,
        songCount: 6,
        totalDuration: 2800000,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ProfileScreen(
            showBottomNav: false,
            songDao: songDao,
            initialTopSongs: songs,
            initialTopArtist: topArtist,
            initialTopAlbum: topAlbum,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('MOST PLAYED ARTIST'));
      await tester.pump();

      // Tap artist tile
      await tester.runAsync(() async {
        await tester.tap(find.byType(MaterialArtistAvatar));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(ArtistDetailScreen), findsOneWidget);

      // Pop back to Profile
      Navigator.of(tester.element(find.byType(ArtistDetailScreen))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap album tile
      await tester.runAsync(() async {
        await tester.tap(find.text('Meddle'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(AlbumDetailScreen), findsOneWidget);
    });
  });
}

