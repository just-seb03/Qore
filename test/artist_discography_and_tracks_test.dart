import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/components/scroll_edge_fade_mask.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/artist/components/artist_assorted_songs_section.dart';
import 'package:project_anima/features/artist/components/artist_discography_section.dart';
import 'package:project_anima/features/artist_discography/components/artist_discography_album_card.dart';
import 'package:project_anima/features/artist_discography/components/artist_discography_header.dart';
import 'package:project_anima/features/artist_discography/controls/artist_discography_controller.dart';
import 'package:project_anima/features/artist_discography/screens/artist_discography_screen.dart';
import 'package:project_anima/features/artist_tracks/components/artist_track_tile.dart';
import 'package:project_anima/features/artist_tracks/components/artist_tracks_header.dart';
import 'package:project_anima/features/artist_tracks/controls/artist_tracks_controller.dart';
import 'package:project_anima/features/artist_tracks/screens/artist_tracks_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeDiscographyController extends ArtistDiscographyController {
  final List<AlbumDiscoveryItem> fakeAlbums;
  _FakeDiscographyController(this.fakeAlbums) : super(artistName: 'Radiohead');

  @override
  bool get isLoading => false;

  @override
  List<AlbumDiscoveryItem> get albums => fakeAlbums;

  @override
  int get albumCount => fakeAlbums.length;

  @override
  Future<void> loadDiscography() async {}
}

class _FakeTracksController extends ArtistTracksController {
  final List<Song> fakeSongs;
  _FakeTracksController(this.fakeSongs) : super(artistName: 'Radiohead');

  @override
  bool get isLoading => false;

  @override
  List<Song> get songs => fakeSongs;

  @override
  int get songCount => fakeSongs.length;

  @override
  int get totalDurationMs => fakeSongs.fold(0, (s, e) => s + e.duration);

  @override
  Future<void> loadTracks() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late SongDao songDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_discog_tracks_');
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

  Future<void> insertTestSong(Song song) async {
    final db = await appDatabase.database;
    await db.insert('songs', song.toMap());
  }

  group('ScrollEdgeFadeMask Tests', () {
    testWidgets('ScrollEdgeFadeMask renders child inside ShaderMask', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollEdgeFadeMask(
              child: ListView(
                children: const [
                  Text('Item 1'),
                  Text('Item 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ScrollEdgeFadeMask), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });
  });

  group('ArtistDiscography Feature Tests', () {
    test('ArtistDiscographyController loads albums and updates state', () async {
      final song1 = Song(
        mediaStoreId: 101,
        title: 'Song A',
        artist: 'Radiohead',
        album: 'OK Computer',
        duration: 200000,
        path: '/storage/a.mp3',
        dateAdded: 100,
        dateModified: 200,
      );
      final song2 = Song(
        mediaStoreId: 102,
        title: 'Song B',
        artist: 'Radiohead',
        album: 'Kid A',
        duration: 180000,
        path: '/storage/b.mp3',
        dateAdded: 110,
        dateModified: 210,
      );
      await insertTestSong(song1);
      await insertTestSong(song2);

      final controller = ArtistDiscographyController(
        artistName: 'Radiohead',
        songDao: songDao,
      );

      expect(controller.isLoading, isTrue);
      await controller.loadDiscography();
      expect(controller.isLoading, isFalse);
      expect(controller.albumCount, equals(2));
      expect(controller.albums.any((a) => a.name == 'OK Computer'), isTrue);
      expect(controller.albums.any((a) => a.name == 'Kid A'), isTrue);
      controller.dispose();
    });

    test('getAlbumsByArtist merges tracks with differing album_ids into a single album without duplicates', () async {
      // 3 tracks of the same album, but track 1 has album_id 50, track 2 has null (0), track 3 has album_id 51
      final song1 = Song(
        mediaStoreId: 201,
        title: 'Airbag',
        artist: 'Radiohead',
        album: 'OK Computer',
        albumId: 50,
        duration: 280000,
        path: '/storage/airbag.mp3',
        dateAdded: 100,
        dateModified: 200,
      );
      final song2 = Song(
        mediaStoreId: 202,
        title: 'Paranoid Android',
        artist: 'Radiohead',
        album: 'OK Computer',
        albumId: 0,
        duration: 380000,
        path: '/storage/pa.mp3',
        dateAdded: 101,
        dateModified: 201,
      );
      final song3 = Song(
        mediaStoreId: 203,
        title: 'Subterranean Homesick Alien',
        artist: 'Radiohead',
        album: 'OK Computer',
        albumId: 51,
        duration: 260000,
        path: '/storage/sha.mp3',
        dateAdded: 102,
        dateModified: 202,
      );
      await insertTestSong(song1);
      await insertTestSong(song2);
      await insertTestSong(song3);

      final albums = await songDao.getAlbumsByArtist('Radiohead');
      // Must be EXACTLY 1 album, NOT 2 or 3!
      expect(albums.length, equals(1));
      expect(albums.first.name, equals('OK Computer'));
      expect(albums.first.songCount, equals(3));
      expect(albums.first.totalDuration, equals(920000));
      expect(albums.first.albumId, equals(51)); // takes positive ID
    });

    test('getAlbumsByArtist excludes other artists albums and compilations', () async {
      // 1. Eminem solo album
      await insertTestSong(Song(
        mediaStoreId: 301,
        title: 'Lose Yourself',
        artist: 'Eminem',
        album: 'The Eminem Show',
        duration: 320000,
        path: '/storage/es1.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));

      // 2. Dr. Dre album where Eminem is only a featured guest on 1 track
      await insertTestSong(Song(
        mediaStoreId: 302,
        title: 'Still D.R.E.',
        artist: 'Dr. Dre feat. Snoop Dogg',
        albumArtist: 'Dr. Dre',
        album: '2001',
        duration: 270000,
        path: '/storage/2001_1.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));
      await insertTestSong(Song(
        mediaStoreId: 303,
        title: 'Forgot About Dre',
        artist: 'Dr. Dre feat. Eminem',
        albumArtist: 'Dr. Dre',
        album: '2001',
        duration: 220000,
        path: '/storage/2001_2.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));

      // 3. Various Artists compilation where Eminem has 1 track out of 3
      await insertTestSong(Song(
        mediaStoreId: 304,
        title: 'Track A',
        artist: 'Artist A',
        album: 'Grammy Nominees',
        duration: 200000,
        path: '/storage/comp1.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));
      await insertTestSong(Song(
        mediaStoreId: 305,
        title: 'Track B',
        artist: 'Artist B',
        album: 'Grammy Nominees',
        duration: 200000,
        path: '/storage/comp2.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));
      await insertTestSong(Song(
        mediaStoreId: 306,
        title: 'Eminem Song',
        artist: 'Eminem',
        album: 'Grammy Nominees',
        duration: 200000,
        path: '/storage/comp3.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));

      // 4. Ghostface Killah track (should NOT match when searching for "Ghost")
      await insertTestSong(Song(
        mediaStoreId: 307,
        title: 'Cherchez LaGhost',
        artist: 'Ghostface Killah',
        album: 'Supreme Clientele',
        duration: 210000,
        path: '/storage/sc.mp3',
        dateAdded: 100,
        dateModified: 200,
      ));

      // Query Eminem albums
      final eminemAlbums = await songDao.getAlbumsByArtist('Eminem');
      expect(eminemAlbums.length, equals(1));
      expect(eminemAlbums.first.name, equals('The Eminem Show'));
      // Dr. Dre's "2001" and "Grammy Nominees" must NOT be in Eminem's discography!
      expect(eminemAlbums.any((a) => a.name == '2001'), isFalse);
      expect(eminemAlbums.any((a) => a.name == 'Grammy Nominees'), isFalse);

      // Query "Ghost" albums: Ghostface Killah's album must NOT appear!
      final ghostAlbums = await songDao.getAlbumsByArtist('Ghost');
      expect(ghostAlbums.isEmpty, isTrue);
    });

    testWidgets('ArtistDiscographyHeader renders Inconsolata labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistDiscographyHeader(
              artistName: 'Radiohead',
            ),
          ),
        ),
      );

      expect(find.text('DISCOGRAPHY'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
    });

    testWidgets('ArtistDiscographyAlbumCard displays title and track count', (tester) async {
      final item = AlbumDiscoveryItem(
        name: 'In Rainbows',
        artist: 'Radiohead',
        albumId: 44,
        representativeSongId: 101,
        songCount: 10,
        totalDuration: 2500000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 240,
              child: ArtistDiscographyAlbumCard(album: item),
            ),
          ),
        ),
      );

      expect(find.text('In Rainbows'), findsOneWidget);
      expect(find.text('10 tracks'), findsOneWidget);
    });

    testWidgets('ArtistDiscographyScreen displays header, grid, and bottom dismiss indicator', (tester) async {
      final fakeAlbum = AlbumDiscoveryItem(
        name: 'OK Computer',
        artist: 'Radiohead',
        albumId: 44,
        representativeSongId: 201,
        songCount: 12,
        totalDuration: 3200000,
      );

      final controller = _FakeDiscographyController([fakeAlbum]);

      await tester.pumpWidget(
        MaterialApp(
          home: ArtistDiscographyScreen(
            artistName: 'Radiohead',
            controller: controller,
            animateBounce: false,
            showMiniPlayer: false,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('DISCOGRAPHY'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('OK Computer'), findsOneWidget);
      expect(find.byType(ModalDismissIndicator), findsOneWidget);
    });
  });

  group('ArtistTracks Feature Tests', () {
    test('ArtistTracksController loads all tracks and aggregates duration', () async {
      final song1 = Song(
        mediaStoreId: 301,
        title: 'Paranoid Android',
        artist: 'Radiohead',
        album: 'OK Computer',
        duration: 380000,
        path: '/storage/pa.mp3',
        dateAdded: 100,
        dateModified: 200,
      );
      final song2 = Song(
        mediaStoreId: 302,
        title: 'No Surprises',
        artist: 'Radiohead',
        album: 'OK Computer',
        duration: 220000,
        path: '/storage/ns.mp3',
        dateAdded: 110,
        dateModified: 210,
      );
      await insertTestSong(song1);
      await insertTestSong(song2);

      final controller = ArtistTracksController(
        artistName: 'Radiohead',
        songDao: songDao,
      );

      expect(controller.isLoading, isTrue);
      await controller.loadTracks();
      expect(controller.isLoading, isFalse);
      expect(controller.songCount, equals(2));
      expect(controller.totalDurationMs, equals(600000));
      controller.dispose();
    });

    testWidgets('ArtistTracksHeader renders Inconsolata labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistTracksHeader(
              artistName: 'Radiohead',
            ),
          ),
        ),
      );

      expect(find.text('TRACKS'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
    });

    testWidgets('ArtistTrackTile renders fixed height with title, album, and duration', (tester) async {
      final song = Song(
        mediaStoreId: 401,
        title: 'Fake Plastic Trees',
        artist: 'Radiohead',
        album: 'The Bends',
        duration: 290000, // 4:50
        path: '/storage/fpt.mp3',
        dateAdded: 100,
        dateModified: 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistTrackTile(
              song: song,
              allArtistSongs: [song],
            ),
          ),
        ),
      );

      expect(find.text('Fake Plastic Trees'), findsOneWidget);
      expect(find.text('The Bends'), findsOneWidget);
      expect(find.text('4:50'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
    });

    testWidgets('ArtistTracksScreen displays header, list, and bottom dismiss indicator', (tester) async {
      final fakeSong = Song(
        mediaStoreId: 501,
        title: 'High and Dry',
        artist: 'Radiohead',
        album: 'The Bends',
        duration: 257000,
        path: '/storage/had.mp3',
        dateAdded: 100,
        dateModified: 200,
      );

      final controller = _FakeTracksController([fakeSong]);

      await tester.pumpWidget(
        MaterialApp(
          home: ArtistTracksScreen(
            artistName: 'Radiohead',
            controller: controller,
            animateBounce: false,
            showMiniPlayer: false,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('TRACKS'), findsOneWidget);
      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('High and Dry'), findsOneWidget);
      expect(find.byType(ModalDismissIndicator), findsOneWidget);
    });
  });

  group('Artist Navigation Arrow Tests', () {
    testWidgets('ArtistDiscographySection arrow triggers onViewAll callback', (tester) async {
      bool tapped = false;
      final album = AlbumDiscoveryItem(
        name: 'Amnesiac',
        artist: 'Radiohead',
        albumId: 55,
        representativeSongId: 101,
        songCount: 11,
        totalDuration: 2600000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistDiscographySection(
              albums: [album],
              artistName: 'Radiohead',
              onViewAll: () => tapped = true,
            ),
          ),
        ),
      );

      final arrowFinder = find.byIcon(Icons.arrow_forward_ios_rounded);
      expect(arrowFinder, findsOneWidget);
      await tester.tap(arrowFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('ArtistAssortedSongsSection arrow triggers onViewAll callback', (tester) async {
      bool tapped = false;
      final song = Song(
        mediaStoreId: 601,
        title: 'Creep',
        artist: 'Radiohead',
        album: 'Pablo Honey',
        duration: 238000,
        path: '/storage/creep.mp3',
        dateAdded: 100,
        dateModified: 200,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistAssortedSongsSection(
              songs: [song],
              allArtistSongs: [song],
              artistName: 'Radiohead',
              onViewAll: () => tapped = true,
            ),
          ),
        ),
      );

      final arrowFinder = find.byIcon(Icons.arrow_forward_ios_rounded);
      expect(arrowFinder, findsOneWidget);
      await tester.tap(arrowFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('SongDao getSongsByArtist Unbounded Tests', () {
    test('getSongsByArtist returns all songs when limit is null', () async {
      for (int i = 1; i <= 8; i++) {
        await insertTestSong(
          Song(
            mediaStoreId: 700 + i,
            title: 'Song $i',
            artist: 'Radiohead',
            album: 'Album X',
            duration: 180000,
            path: '/storage/song_$i.mp3',
            dateAdded: 100 + i,
            dateModified: 200 + i,
          ),
        );
      }

      final allSongs = await songDao.getSongsByArtist('Radiohead');
      expect(allSongs.length, equals(8));

      final limitedSongs = await songDao.getSongsByArtist('Radiohead', limit: 3);
      expect(limitedSongs.length, equals(3));
    });
  });
}
