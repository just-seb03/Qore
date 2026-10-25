import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/utils/artist_splitter.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/player/components/player_metadata_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('ArtistSplitter Utility Tests', () {
    test('splits comma-separated artists with or without spaces', () {
      expect(
        ArtistSplitter.split('Virtual Riot, Eliminate'),
        equals(['Virtual Riot', 'Eliminate']),
      );
      expect(
        ArtistSplitter.split('Virtual Riot,Eliminate'),
        equals(['Virtual Riot', 'Eliminate']),
      );
    });

    test('splits slash-separated artists with or without spaces', () {
      expect(
        ArtistSplitter.split('Virtual Riot / Eliminate'),
        equals(['Virtual Riot', 'Eliminate']),
      );
      expect(
        ArtistSplitter.split('Virtual Riot/Eliminate'),
        equals(['Virtual Riot', 'Eliminate']),
      );
    });

    test('splits semicolon-separated artists', () {
      expect(
        ArtistSplitter.split('Virtual Riot; Eliminate'),
        equals(['Virtual Riot', 'Eliminate']),
      );
    });

    test('splits multiple mixed delimiters', () {
      expect(
        ArtistSplitter.split('Virtual Riot, Eliminate / Skrillex; Noisia'),
        equals(['Virtual Riot', 'Eliminate', 'Skrillex', 'Noisia']),
      );
    });

    test('preserves protected band names like AC/DC', () {
      expect(
        ArtistSplitter.split('AC/DC'),
        equals(['AC/DC']),
      );
    });

    test('handles single artists without delimiters', () {
      expect(
        ArtistSplitter.split('Virtual Riot'),
        equals(['Virtual Riot']),
      );
    });

    test('trims whitespace and deduplicates identical artist entries', () {
      expect(
        ArtistSplitter.split('  Virtual Riot  ,  Eliminate  ,  virtual riot  '),
        equals(['Virtual Riot', 'Eliminate']),
      );
    });

    test('returns empty list for null, empty or unknown placeholders', () {
      expect(ArtistSplitter.split(null), isEmpty);
      expect(ArtistSplitter.split(''), isEmpty);
      expect(ArtistSplitter.split('   '), isEmpty);
      expect(ArtistSplitter.split('<Desconocido>'), isEmpty);
      expect(ArtistSplitter.split('Unknown Artist'), isEmpty);
    });

    test('primaryArtist extracts first artist or fallback', () {
      expect(
        ArtistSplitter.primaryArtist('Virtual Riot, Eliminate'),
        equals('Virtual Riot'),
      );
      expect(
        ArtistSplitter.primaryArtist('Virtual Riot / Eliminate'),
        equals('Virtual Riot'),
      );
      expect(
        ArtistSplitter.primaryArtist(null),
        equals('<Desconocido>'),
      );
    });
  });

  group('Song Model Multi-Artist Getters Tests', () {
    test('Song.artists returns list of split artists', () {
      final song = Song(
        mediaStoreId: 9001,
        title: 'Show Me Your Light',
        artist: 'Virtual Riot, Eliminate',
        duration: 210000,
        path: '/storage/light.mp3',
        dateModified: 1000,
      );

      expect(song.artists, equals(['Virtual Riot', 'Eliminate']));
      expect(song.primaryArtist, equals('Virtual Riot'));
    });

    test('Song.artists returns empty for unknown artist', () {
      final song = Song(
        mediaStoreId: 9002,
        title: 'Mystery Track',
        artist: '<Desconocido>',
        duration: 180000,
        path: '/storage/mystery.mp3',
        dateModified: 1000,
      );

      expect(song.artists, isEmpty);
      expect(song.primaryArtist, equals('<Desconocido>'));
    });
  });

  group('Database Multi-Artist Queries Tests', () {
    late Directory tempDir;
    late AppDatabase appDatabase;
    late SongDao songDao;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('anima_multi_artist_test_');
      final dbPath = p.join(tempDir.path, 'test_multi_artist.db');

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

    test('Library artists tab splits multi-artist tracks into individual artists', () async {
      final db = await appDatabase.database;

      final collabSong = Song(
        mediaStoreId: 501,
        title: 'Show Me Your Light',
        artist: 'Virtual Riot, Eliminate',
        album: 'Save Yourself',
        duration: 200000,
        path: '/music/light.mp3',
        dateModified: 100,
      );
      final vrSoloSong = Song(
        mediaStoreId: 502,
        title: 'Energy Drink',
        artist: 'Virtual Riot',
        album: 'German Engineering',
        duration: 190000,
        path: '/music/energy.mp3',
        dateModified: 100,
      );
      final elimSoloSong = Song(
        mediaStoreId: 503,
        title: 'Weeble Wobble',
        artist: 'Eliminate',
        album: 'Cyber Whale',
        duration: 185000,
        path: '/music/weeble.mp3',
        dateModified: 100,
      );

      await db.insert('songs', collabSong.toMap());
      await db.insert('songs', vrSoloSong.toMap());
      await db.insert('songs', elimSoloSong.toMap());

      final libraryArtists = await songDao.getLibraryArtists();

      // Individual artists must appear, NOT "Virtual Riot, Eliminate"
      final artistNames = libraryArtists.map((a) => a.name).toList();
      expect(artistNames, contains('Eliminate'));
      expect(artistNames, contains('Virtual Riot'));
      expect(artistNames, isNot(contains('Virtual Riot, Eliminate')));

      // Both Eliminate and Virtual Riot should credit the collaborative song
      final eliminate = libraryArtists.firstWhere((a) => a.name == 'Eliminate');
      expect(eliminate.songCount, equals(2)); // Weeble Wobble + Show Me Your Light

      final virtualRiot = libraryArtists.firstWhere((a) => a.name == 'Virtual Riot');
      expect(virtualRiot.songCount, equals(2)); // Energy Drink + Show Me Your Light
    });

    test('getSongsByArtist returns songs where artist participated as co-artist', () async {
      final db = await appDatabase.database;

      final collabSong = Song(
        mediaStoreId: 601,
        title: 'Collaborative Banger',
        artist: 'Virtual Riot / Eliminate',
        album: 'Collabs Vol 1',
        duration: 220000,
        path: '/music/collab.mp3',
        dateModified: 100,
      );
      await db.insert('songs', collabSong.toMap());

      // Querying Virtual Riot must retrieve the song
      final vrSongs = await songDao.getSongsByArtist('Virtual Riot');
      expect(vrSongs.length, equals(1));
      expect(vrSongs.first.title, equals('Collaborative Banger'));

      // Querying Eliminate must also retrieve the song
      final elimSongs = await songDao.getSongsByArtist('Eliminate');
      expect(elimSongs.length, equals(1));
      expect(elimSongs.first.title, equals('Collaborative Banger'));
    });

    test('getTopSongsByArtist and getAssortedSongsByArtist include co-artist tracks', () async {
      final db = await appDatabase.database;

      final collabSong = Song(
        mediaStoreId: 701,
        title: 'Joint Anthem',
        artist: 'Virtual Riot, Eliminate',
        album: 'Anthems',
        duration: 240000,
        path: '/music/joint.mp3',
        dateModified: 200,
      );
      final id = await db.insert('songs', collabSong.toMap());

      // Record playback for the collaborative song
      for (int i = 0; i < 5; i++) {
        await db.insert('playback_history', {
          'song_id': id,
          'artist': 'Virtual Riot, Eliminate',
          'played_at': 1000 + i,
        });
      }

      final vrTop = await songDao.getTopSongsByArtist('Virtual Riot');
      expect(vrTop.any((s) => s.title == 'Joint Anthem'), isTrue);

      final elimTop = await songDao.getTopSongsByArtist('Eliminate');
      expect(elimTop.any((s) => s.title == 'Joint Anthem'), isTrue);

      final vrAssorted = await songDao.getAssortedSongsByArtist('Virtual Riot');
      expect(vrAssorted.any((s) => s.title == 'Joint Anthem'), isTrue);

      final elimAssorted = await songDao.getAssortedSongsByArtist('Eliminate');
      expect(elimAssorted.any((s) => s.title == 'Joint Anthem'), isTrue);
    });

    test('FuzzySearchEngine indexes individual artists and finds songs under both', () async {
      final db = await appDatabase.database;

      final collabSong = Song(
        mediaStoreId: 801,
        title: 'Cry Some More',
        artist: 'Virtual Riot, Eliminate',
        album: 'Bass Cannon',
        duration: 215000,
        path: '/music/cry.mp3',
        dateModified: 100,
      );
      await db.insert('songs', collabSong.toMap());

      final fuzzyEngine = FuzzySearchEngine(songDao: songDao);
      await fuzzyEngine.reloadDictionary();

      // Search for "Eliminate"
      final elimResults = await fuzzyEngine.search('Eliminate');
      expect(elimResults.matchedSongs.any((s) => s.title == 'Cry Some More'), isTrue);

      // Search for "Virtual Riot"
      final vrResults = await fuzzyEngine.search('Virtual Riot');
      expect(vrResults.matchedSongs.any((s) => s.title == 'Cry Some More'), isTrue);
    });
  });

  group('PlayerMetadataView Multi-Artist Widget Tests', () {
    testWidgets('renders individual clickable spans for each artist when multi-artist', (tester) async {
      final song = Song(
        mediaStoreId: 999,
        title: 'Show Me Your Light',
        artist: 'Virtual Riot, Eliminate',
        album: 'Save Yourself',
        duration: 200000,
        path: '/music/light.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlayerMetadataView(
              song: song,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both individual artists must be rendered
      expect(find.text('Virtual Riot'), findsOneWidget);
      expect(find.text('Eliminate'), findsOneWidget);
      expect(find.text(', '), findsOneWidget);

      // Tapping on "Virtual Riot" navigates to ArtistDetailScreen for Virtual Riot
      await tester.tap(find.text('Virtual Riot'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final screen = tester.widget<ArtistDetailScreen>(find.byType(ArtistDetailScreen));
      expect(screen.artistName, equals('Virtual Riot'));
    });

    testWidgets('tapping Eliminate on multi-artist navigates to Eliminate profile', (tester) async {
      final song = Song(
        mediaStoreId: 1000,
        title: 'Show Me Your Light',
        artist: 'Virtual Riot / Eliminate',
        album: 'Save Yourself',
        duration: 200000,
        path: '/music/light.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlayerMetadataView(
              song: song,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Virtual Riot'), findsOneWidget);
      expect(find.text('Eliminate'), findsOneWidget);
      expect(find.text(' / '), findsOneWidget);

      // Tapping on "Eliminate" navigates to ArtistDetailScreen for Eliminate
      await tester.tap(find.text('Eliminate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final screen = tester.widget<ArtistDetailScreen>(find.byType(ArtistDetailScreen));
      expect(screen.artistName, equals('Eliminate'));
    });
  });
}
