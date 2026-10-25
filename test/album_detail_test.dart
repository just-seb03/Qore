import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/album/components/album_header_view.dart';
import 'package:project_anima/features/album/components/album_track_tile.dart';
import 'package:project_anima/features/album/screens/album_detail_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late SongDao songDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_album_test_');
    final dbPath = p.join(tempDir.path, 'test_anima_album.db');

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

  group('SongDao Album Queries & Natural Ordering Tests', () {
    test('AudioMetadata has trackNumber property', () {
      final m = AudioMetadata(file: File(''));
      expect(m.trackNumber, isNull);
    });

    test('getSongsByAlbum retrieves all songs and sorts naturally by track number in filename', () async {
      final db = await appDatabase.database;

      final s3 = Song(
        mediaStoreId: 103,
        title: 'Giorgio by Moroder',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: 544000,
        path: '/storage/music/03 - Giorgio by Moroder.mp3',
        dateAdded: 1000,
        dateModified: 2000,
      );
      final s1 = Song(
        mediaStoreId: 101,
        title: 'Give Life Back to Music',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: 274000,
        path: '/storage/music/01 - Give Life Back to Music.mp3',
        dateAdded: 1000,
        dateModified: 2000,
      );
      final s2 = Song(
        mediaStoreId: 102,
        title: 'The Game of Love',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: 321000,
        path: '/storage/music/02 - The Game of Love.mp3',
        dateAdded: 1000,
        dateModified: 2000,
      );
      final sOther = Song(
        mediaStoreId: 201,
        title: 'One More Time',
        artist: 'Daft Punk',
        album: 'Discovery',
        duration: 320000,
        path: '/storage/music/discovery_01.mp3',
        dateAdded: 1000,
        dateModified: 2000,
      );

      await db.insert('songs', s3.toMap());
      await db.insert('songs', s1.toMap());
      await db.insert('songs', s2.toMap());
      await db.insert('songs', sOther.toMap());

      final albumTracks = await songDao.getSongsByAlbum('Random Access Memories');

      expect(albumTracks.length, 3);
      // Verify natural track number sorting (1, 2, 3)
      expect(albumTracks[0].mediaStoreId, 101);
      expect(albumTracks[1].mediaStoreId, 102);
      expect(albumTracks[2].mediaStoreId, 103);
    });

    test('getSongsByAlbum sorts naturally by track number in song title if path lacks digits', () async {
      final db = await appDatabase.database;

      final s10 = Song(
        mediaStoreId: 110,
        title: '10. Track Ten',
        artist: 'Pink Floyd',
        album: 'The Wall',
        duration: 200000,
        path: '/storage/track_ten.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 102,
        title: '2. Track Two',
        artist: 'Pink Floyd',
        album: 'The Wall',
        duration: 210000,
        path: '/storage/track_two.mp3',
        dateModified: 100,
      );
      final s1 = Song(
        mediaStoreId: 101,
        title: '1. Track One',
        artist: 'Pink Floyd',
        album: 'The Wall',
        duration: 220000,
        path: '/storage/track_one.mp3',
        dateModified: 100,
      );

      await db.insert('songs', s10.toMap());
      await db.insert('songs', s2.toMap());
      await db.insert('songs', s1.toMap());

      final albumTracks = await songDao.getSongsByAlbum('The Wall');

      expect(albumTracks.length, 3);
      // 1, 2, 10 (not 1, 10, 2)
      expect(albumTracks[0].mediaStoreId, 101);
      expect(albumTracks[1].mediaStoreId, 102);
      expect(albumTracks[2].mediaStoreId, 110);
    });

    test('getSongsByAlbum scopes accurately with albumId when provided', () async {
      final db = await appDatabase.database;

      final s1 = Song(
        mediaStoreId: 301,
        title: 'Track One',
        artist: 'Artist A',
        album: 'Self-Titled',
        albumId: 55,
        duration: 180000,
        path: '/storage/a/01.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 302,
        title: 'Track Another',
        artist: 'Artist B',
        album: 'Self-Titled',
        albumId: 99,
        duration: 200000,
        path: '/storage/b/01.mp3',
        dateModified: 100,
      );

      await db.insert('songs', s1.toMap());
      await db.insert('songs', s2.toMap());

      final scoped = await songDao.getSongsByAlbum(
        'Self-Titled',
        albumId: 55,
      );

      expect(scoped.length, 1);
      expect(scoped.first.mediaStoreId, 301);
      expect(scoped.first.artist, 'Artist A');
    });

    test('getSongsByAlbum scopes with artist when albumId is absent', () async {
      final db = await appDatabase.database;

      final s1 = Song(
        mediaStoreId: 401,
        title: 'Song by Queen',
        artist: 'Queen',
        album: 'Greatest Hits',
        duration: 180000,
        path: '/storage/queen/01.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 402,
        title: 'Song by Blink-182',
        artist: 'Blink-182',
        album: 'Greatest Hits',
        duration: 200000,
        path: '/storage/blink/01.mp3',
        dateModified: 100,
      );

      await db.insert('songs', s1.toMap());
      await db.insert('songs', s2.toMap());

      final queenTracks = await songDao.getSongsByAlbum('Greatest Hits', artist: 'Queen');
      expect(queenTracks.length, 1);
      expect(queenTracks.first.mediaStoreId, 401);

      final blinkTracks = await songDao.getSongsByAlbum('Greatest Hits', artist: 'Blink-182');
      expect(blinkTracks.length, 1);
      expect(blinkTracks.first.mediaStoreId, 402);
    });
    test('getSongsByAlbum sorts by trackNumber column even when filenames and titles are purely alphabetical', () async {
      final db = await appDatabase.database;

      // Filenames and titles are alphabetical: B, C, A
      // But track numbers are: B is track 1, C is track 2, A is track 3
      final trackB = Song(
        mediaStoreId: 501,
        title: 'B Title Song',
        artist: 'The Beatles',
        album: 'Abbey Road',
        duration: 180000,
        path: '/storage/music/B Title Song.mp3',
        trackNumber: 1,
        dateModified: 100,
      );
      final trackC = Song(
        mediaStoreId: 502,
        title: 'C Title Song',
        artist: 'The Beatles',
        album: 'Abbey Road',
        duration: 190000,
        path: '/storage/music/C Title Song.mp3',
        trackNumber: 2,
        dateModified: 100,
      );
      final trackA = Song(
        mediaStoreId: 503,
        title: 'A Title Song',
        artist: 'The Beatles',
        album: 'Abbey Road',
        duration: 200000,
        path: '/storage/music/A Title Song.mp3',
        trackNumber: 3,
        dateModified: 100,
      );

      // Insert out of order
      await db.insert('songs', trackA.toMap());
      await db.insert('songs', trackC.toMap());
      await db.insert('songs', trackB.toMap());

      final songs = await songDao.getSongsByAlbum('Abbey Road');

      expect(songs.length, 3);
      // Expected track order: Track 1 (B), Track 2 (C), Track 3 (A)
      expect(songs[0].title, 'B Title Song');
      expect(songs[0].trackNumber, 1);
      expect(songs[1].title, 'C Title Song');
      expect(songs[1].trackNumber, 2);
      expect(songs[2].title, 'A Title Song');
      expect(songs[2].trackNumber, 3);
    });

    test('backfillTrackNumbers correctly updates cached songs in SQLite', () async {
      final db = await appDatabase.database;

      final s = Song(
        mediaStoreId: 601,
        title: 'Song Without Track',
        artist: 'Radiohead',
        album: 'OK Computer',
        duration: 200000,
        path: '/storage/music/airbag.mp3',
        trackNumber: null,
        dateModified: 100,
      );
      await db.insert('songs', s.toMap());

      var before = await songDao.getSongsByAlbum('OK Computer');
      expect(before.first.trackNumber, isNull);

      await songDao.backfillTrackNumbers({601: 1});

      var after = await songDao.getSongsByAlbum('OK Computer');
      expect(after.first.trackNumber, 1);
    });
  });

  group('ModalDismissIndicator Tests', () {
    testWidgets('renders chevron down icon and triggers onDismiss on tap', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModalDismissIndicator(
              onDismiss: () => dismissed = true,
              animate: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      await tester.tap(find.byType(ModalDismissIndicator));
      expect(dismissed, isTrue);
    });
  });

  group('AlbumHeaderView Tests', () {
    testWidgets('renders album name, artist, duration, and track count accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlbumHeaderView(
              albumName: 'Discovery',
              artistName: 'Daft Punk',
              songCount: 14,
              totalDurationMs: 3600000,
            ),
          ),
        ),
      );

      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('14 songs • 1 hr 0 min'), findsOneWidget);
    });

    test('AlbumDetailScreen.sanitizeArtist strips prefixes cleanly', () {
      expect(AlbumDetailScreen.sanitizeArtist('Album • Chet Baker'), 'Chet Baker');
      expect(AlbumDetailScreen.sanitizeArtist('Álbum • Chet Baker'), 'Chet Baker');
      expect(AlbumDetailScreen.sanitizeArtist('album chet baker'), 'chet baker');
      expect(AlbumDetailScreen.sanitizeArtist('Song • Queen'), 'Queen');
      expect(AlbumDetailScreen.sanitizeArtist('Chet Baker'), 'Chet Baker');
      expect(AlbumDetailScreen.sanitizeArtist(null), isNull);
      expect(AlbumDetailScreen.sanitizeArtist('Unknown Artist'), isNull);
    });

    testWidgets('sanitizes artist label when passed with "Album • " or "album " prefix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlbumHeaderView(
              albumName: 'Chet Baker Sings',
              artistName: 'Album • Chet Baker',
              songCount: 14,
              totalDurationMs: 2600000,
            ),
          ),
        ),
      );

      // Must render "Chet Baker", NOT "Album • Chet Baker"
      expect(find.text('Chet Baker'), findsOneWidget);
      expect(find.text('Album • Chet Baker'), findsNothing);
    });

    testWidgets('sanitizes lowercase "album chet baker" prefix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlbumHeaderView(
              albumName: 'Chet Baker Sings',
              artistName: 'album chet baker',
              songCount: 14,
              totalDurationMs: 2600000,
            ),
          ),
        ),
      );

      expect(find.text('chet baker'), findsOneWidget);
      expect(find.text('album chet baker'), findsNothing);
    });
  });

  group('AlbumTrackTile Tests', () {
    testWidgets('renders metadata trackNumber zero-padded and multi-disc cleanly', (tester) async {
      final songWithTrack = Song(
        mediaStoreId: 701,
        title: 'Come Together',
        artist: 'The Beatles',
        album: 'Abbey Road',
        duration: 259000,
        path: '/storage/music/Come Together.mp3',
        trackNumber: 1007, // Disc 1 Track 7
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumTrackTile(
              song: songWithTrack,
              trackIndex: 1,
              allAlbumSongs: [songWithTrack],
            ),
          ),
        ),
      );

      // Disc 1 Track 7 -> 1007 % 1000 = 7 -> "07"
      expect(find.text('07'), findsOneWidget);
      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.text('4:19'), findsOneWidget);
    });
  });
}
