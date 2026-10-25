import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/utils/artist_splitter.dart';
import 'package:project_anima/features/artist/components/artist_appears_on_section.dart';
import 'package:project_anima/features/artist/components/artist_discography_section.dart';
import 'package:project_anima/features/artist/components/artist_top_track_tile.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/artist_tracks/components/artist_track_tile.dart';
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

  group('SongDao getAppearsOnAlbumsByArtist Tests', () {
    late AppDatabase appDatabase;
    late SongDao songDao;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('appears_on_test_');
      final dbPath = p.join(tempDir.path, 'appears_on_test.db');
      appDatabase = AppDatabase.instance;
      await appDatabase.initDatabase(customPath: dbPath);
      songDao = SongDao(appDatabase: appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('correctly partitions albums into own discography vs appears on', () async {
      final db = await appDatabase.database;

      // 1. Virtual Riot's own album "Simulation"
      await db.insert('songs', {
        'media_store_id': 2001,
        'title': 'Redline',
        'artist': 'Virtual Riot',
        'album_artist': 'Virtual Riot',
        'album': 'Simulation',
        'duration': 210000,
        'path': '/music/redline.mp3',
        'date_modified': 100,
      });

      // 2. Eliminate's album "Cyber Whirl" where Virtual Riot is a guest feature
      await db.insert('songs', {
        'media_store_id': 2002,
        'title': 'Cyber Rave',
        'artist': 'Eliminate feat. Virtual Riot',
        'album_artist': 'Eliminate',
        'album': 'Cyber Whirl',
        'duration': 190000,
        'path': '/music/cyber_rave.mp3',
        'date_modified': 200,
      });
      await db.insert('songs', {
        'media_store_id': 2003,
        'title': 'Breathe',
        'artist': 'Eliminate',
        'album_artist': 'Eliminate',
        'album': 'Cyber Whirl',
        'duration': 180000,
        'path': '/music/breathe.mp3',
        'date_modified': 200,
      });

      // Query Virtual Riot's albums:
      final vrOwnAlbums = await songDao.getAlbumsByArtist('Virtual Riot');
      expect(vrOwnAlbums.length, equals(1));
      expect(vrOwnAlbums.first.name, equals('Simulation'));

      final vrAppearsOn = await songDao.getAppearsOnAlbumsByArtist('Virtual Riot');
      expect(vrAppearsOn.length, equals(1));
      expect(vrAppearsOn.first.name, equals('Cyber Whirl'));
      expect(vrAppearsOn.first.artist, equals('Eliminate'));

      // Query Eliminate's albums:
      final elimOwnAlbums = await songDao.getAlbumsByArtist('Eliminate');
      expect(elimOwnAlbums.length, equals(1));
      expect(elimOwnAlbums.first.name, equals('Cyber Whirl'));

      final elimAppearsOn = await songDao.getAppearsOnAlbumsByArtist('Eliminate');
      expect(elimAppearsOn, isEmpty);
    });
  });

  group('Unrounded Cover Artwork and ArtistAppearsOnSection Widget Tests', () {
    testWidgets('ArtistAppearsOnSection renders localized header and unrounded square covers', (tester) async {
      final albums = [
        const AlbumDiscoveryItem(
          name: 'Cyber Whirl',
          artist: 'Eliminate',
          albumId: 10,
          representativeSongId: 2002,
          songCount: 8,
          totalDuration: 1800000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: ArtistAppearsOnSection(
              albums: albums,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header is rendered
      expect(find.text('APARECE EN'), findsOneWidget);
      // Album name and primary artist rendered
      expect(find.text('Cyber Whirl'), findsOneWidget);
      expect(find.text('Eliminate'), findsOneWidget);

      // Verify AnimaArtworkImage has borderRadius 0.0
      final artworkFinder = find.byType(AnimaArtworkImage);
      expect(artworkFinder, findsOneWidget);
      final artwork = tester.widget<AnimaArtworkImage>(artworkFinder);
      expect(artwork.borderRadius, equals(0.0));
    });

    testWidgets('ArtistDiscographySection renders unrounded square covers (borderRadius: 0.0)', (tester) async {
      final albums = [
        const AlbumDiscoveryItem(
          name: 'Simulation',
          artist: 'Virtual Riot',
          albumId: 5,
          representativeSongId: 2001,
          songCount: 12,
          totalDuration: 2400000,
        ),
      ];

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
            body: ArtistDiscographySection(
              albums: albums,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final artworkFinder = find.byType(AnimaArtworkImage);
      expect(artworkFinder, findsOneWidget);
      final artwork = tester.widget<AnimaArtworkImage>(artworkFinder);
      expect(artwork.borderRadius, equals(0.0));
    });

    testWidgets('ArtistTopTrackTile renders unrounded cover thumbnail (borderRadius: 0.0)', (tester) async {
      final song = Song(
        mediaStoreId: 3001,
        title: 'Energy Drink',
        artist: 'Virtual Riot',
        album: 'Simulation',
        duration: 210000,
        path: '/music/energy.mp3',
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
            body: ArtistTopTrackTile(
              song: song,
              allArtistSongs: [song],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final artworkFinder = find.byType(AnimaArtworkImage);
      expect(artworkFinder, findsOneWidget);
      final artwork = tester.widget<AnimaArtworkImage>(artworkFinder);
      expect(artwork.borderRadius, equals(0.0));
    });

    testWidgets('ArtistTrackTile renders unrounded cover thumbnail (borderRadius: 0.0)', (tester) async {
      final song = Song(
        mediaStoreId: 3002,
        title: 'Basement Dwellers',
        artist: 'Virtual Riot',
        album: 'The Classics',
        duration: 180000,
        path: '/music/basement.mp3',
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
            body: ArtistTrackTile(
              song: song,
              allArtistSongs: [song],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final artworkFinder = find.byType(AnimaArtworkImage);
      expect(artworkFinder, findsOneWidget);
      final artwork = tester.widget<AnimaArtworkImage>(artworkFinder);
      expect(artwork.borderRadius, equals(0.0));
    });
  });
}
