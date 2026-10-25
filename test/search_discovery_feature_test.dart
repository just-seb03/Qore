/// File: search_discovery_feature_test.dart
/// Description: Comprehensive unit and widget tests for the Search Discovery features,
/// including DAO queries for newest albums/artists/recents, SearchDiscoveryCard 4-cover collage,
/// empty-library blank state, and animated switching between discovery and search modes.
library;

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
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';
import 'package:project_anima/features/search/components/cards/search_discovery_card.dart';
import 'package:project_anima/features/search/components/search_bar.dart';
import 'package:project_anima/features/search/components/search_discovery_view.dart';
import 'package:project_anima/features/search/screens/search.dart';

void main() {
  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  const testDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  group('SongDao Discovery Queries Tests', () {
    late Directory tempDir;
    late AppDatabase db;
    late SongDao songDao;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('discovery_test_db_');
      final dbPath = p.join(tempDir.path, 'discovery_test.db');
      db = AppDatabase.instance;
      await db.initDatabase(customPath: dbPath);
      songDao = SongDao(appDatabase: db);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('getNewestAlbums orders by newest addition and limits to requested count', () async {
      final database = await db.database;
      // Insert 7 songs across 7 different albums with ascending date_added
      for (int i = 1; i <= 7; i++) {
        await database.insert('songs', {
          'id': i,
          'media_store_id': 100 + i,
          'title': 'Track $i',
          'artist': 'Artist $i',
          'album': 'Album $i',
          'path': '/music/track$i.mp3',
          'duration': 180000,
          'date_added': 1000 + i * 100,
          'date_modified': 1700000000,
        });
      }

      final newest5 = await songDao.getNewestAlbums(limit: 5);
      expect(newest5.length, 5);
      // Newest should be Album 7 down to Album 3
      expect(newest5[0].name, 'Album 7');
      expect(newest5[1].name, 'Album 6');
      expect(newest5[2].name, 'Album 5');
      expect(newest5[3].name, 'Album 4');
      expect(newest5[4].name, 'Album 3');
    });

    test('getNewestArtists orders by newest addition and limits to requested count', () async {
      final database = await db.database;
      for (int i = 1; i <= 7; i++) {
        await database.insert('songs', {
          'id': i,
          'media_store_id': 200 + i,
          'title': 'Track $i',
          'artist': 'Solo Artist $i',
          'album': 'Album $i',
          'path': '/music/artist_track$i.mp3',
          'duration': 180000,
          'date_added': 2000 + i * 50,
          'date_modified': 1700000000,
        });
      }

      final newest5 = await songDao.getNewestArtists(limit: 5);
      expect(newest5.length, 5);
      expect(newest5[0].name, 'Solo Artist 7');
      expect(newest5[1].name, 'Solo Artist 6');
      expect(newest5[2].name, 'Solo Artist 5');
      expect(newest5[3].name, 'Solo Artist 4');
      expect(newest5[4].name, 'Solo Artist 3');
    });

    test('getRecentlyPlayedSongs returns distinct songs ordered by playback time', () async {
      final database = await db.database;
      for (int i = 1; i <= 5; i++) {
        await database.insert('songs', {
          'id': i,
          'media_store_id': 300 + i,
          'title': 'Recent Track $i',
          'artist': 'Recent Artist',
          'album': 'Recent Album',
          'path': '/music/recent$i.mp3',
          'duration': 200000,
          'date_modified': 1700000000,
        });
      }

      // Record multiple playbacks: song 1, then 2, then 1 again, then 3
      await songDao.recordPlayback(songId: 1, timestampSeconds: 100);
      await songDao.recordPlayback(songId: 2, timestampSeconds: 200);
      await songDao.recordPlayback(songId: 1, timestampSeconds: 300); // 1 is newest
      await songDao.recordPlayback(songId: 3, timestampSeconds: 250);

      final recents = await songDao.getRecentlyPlayedSongs(limit: 20);
      expect(recents.length, 3);
      // Order should be Song 1 (300), Song 3 (250), Song 2 (200)
      expect(recents[0].id, 1);
      expect(recents[1].id, 3);
      expect(recents[2].id, 2);
    });
  });

  group('SearchDiscoveryCard Widget Tests', () {
    testWidgets('renders empty vinyl disc icon when songs list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160.0,
              child: SearchDiscoveryCard(
                title: 'Recientes',
                subtitle: '0 canciones',
                songs: const [],
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Recientes'), findsOneWidget);
      expect(find.text('0 canciones'), findsOneWidget);
      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
    });

    testWidgets('renders 4-cover collage when 4 or more songs are provided', (tester) async {
      final List<Song> songs = List.generate(
        4,
        (i) => Song(
          id: i + 1,
          mediaStoreId: 500 + i,
          title: 'Collage Song $i',
          artist: 'Artist $i',
          album: 'Album $i',
          path: '/path/$i.mp3',
          duration: 180000,
          dateModified: 1700000000,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160.0,
              child: SearchDiscoveryCard(
                title: 'Today Selection',
                subtitle: '4 canciones',
                songs: songs,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Today Selection'), findsOneWidget);
      expect(find.text('4 canciones'), findsOneWidget);
      // 4 album icons from AnimaArtworkImage placeholders
      expect(find.byIcon(Icons.album_rounded), findsNWidgets(4));
    });
  });

  group('SearchDiscoveryView Widget Tests', () {
    testWidgets('renders nothing (SizedBox.shrink) if songCount is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchDiscoveryView(
              initialSongCount: 0,
            ),
          ),
        ),
      );

      // Should be empty
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('Today Selection'), findsNothing);
      expect(find.text('Recientes'), findsNothing);
    });

    testWidgets('renders newest albums, newest artists, and system playlist cards', (tester) async {
      final mockAlbums = [
        const AlbumDiscoveryItem(
          name: 'Random Access Memories',
          artist: 'Daft Punk',
          representativeSongId: 10,
          songCount: 13,
          totalDuration: 4000,
        ),
      ];

      final mockArtists = [
        const ArtistDiscoveryItem(
          name: 'Daft Punk',
          songCount: 13,
          albumCount: 1,
          representativeSongId: 10,
        ),
      ];

      final List<Song> mockTodaySongs = [
        const Song(
          id: 1,
          mediaStoreId: 10,
          title: 'Get Lucky',
          artist: 'Daft Punk',
          album: 'Random Access Memories',
          path: '/music/get_lucky.mp3',
          duration: 240000,
          dateModified: 1700000000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: SearchDiscoveryView(
              initialSongCount: 10,
              initialAlbums: mockAlbums,
              initialArtists: mockArtists,
              initialTodaySongs: mockTodaySongs,
              initialRecentSongs: const [],
            ),
          ),
        ),
      );

      expect(find.text('NUEVOS ÁLBUMES'), findsOneWidget);
      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('ARTISTAS NUEVOS'), findsOneWidget);
      expect(find.text('Daft Punk'), findsWidgets);
      expect(find.text('Today Selection'), findsOneWidget);
      expect(find.text('Recientes'), findsOneWidget);
    });

    testWidgets('tapping Today Selection opens PlaylistDetailScreen', (tester) async {
      final List<Song> mockTodaySongs = [
        const Song(
          id: 1,
          mediaStoreId: 10,
          title: 'Instant Crush',
          artist: 'Daft Punk',
          album: 'Random Access Memories',
          path: '/music/instant_crush.mp3',
          duration: 300000,
          dateModified: 1700000000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: SearchDiscoveryView(
              initialSongCount: 5,
              initialAlbums: const [],
              initialArtists: const [],
              initialTodaySongs: mockTodaySongs,
              initialRecentSongs: const [],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Today Selection'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
      expect(find.text('Instant Crush'), findsOneWidget);
    });

    testWidgets('tapping Recientes opens PlaylistDetailScreen', (tester) async {
      final List<Song> mockRecentSongs = [
        const Song(
          id: 2,
          mediaStoreId: 20,
          title: 'Harder, Better, Faster, Stronger',
          artist: 'Daft Punk',
          album: 'Discovery',
          path: '/music/harder.mp3',
          duration: 224000,
          dateModified: 1700000000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: SearchDiscoveryView(
              initialSongCount: 5,
              initialAlbums: const [],
              initialArtists: const [],
              initialTodaySongs: const [],
              initialRecentSongs: mockRecentSongs,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Recientes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
      expect(find.text('Harder, Better, Faster, Stronger'), findsOneWidget);
    });
  });

  group('SearchScreen Discovery and Focus Animation Tests', () {
    testWidgets('SearchScreen starts in Discovery Mode and transitions to Search Mode on focus', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: SearchScreen(),
        ),
      );

      // Initially SearchDiscoveryView is in the tree
      expect(find.byKey(const ValueKey('search_discovery_view')), findsOneWidget);
      expect(find.byKey(const ValueKey('search_results_list')), findsNothing);

      // Tap on search bar to focus
      await tester.tap(find.byType(AppSearchBar));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should have transitioned to SearchResultsList with SearchRecentList / SearchEmptyView
      expect(find.byKey(const ValueKey('search_results_list')), findsOneWidget);
      expect(find.byKey(const ValueKey('search_discovery_view')), findsNothing);
    });
  });
}
