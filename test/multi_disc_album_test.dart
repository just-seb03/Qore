/// File: multi_disc_album_test.dart
/// Description: Comprehensive test suite validating multi-disc album SQL modeling,
/// natural disc/track ordering, backfill mechanisms, and UI disc partitioning in English.
///
/// Components / Classes / Functions:
/// - Multi-disc persistence and migration tests
/// - Multi-disc SongDao ordering tests
/// - AlbumTracksSection UI rendering tests (single-disc vs multi-disc)
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/album/components/album_tracks_section.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late SongDao songDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_multi_disc_test_');
    final dbPath = p.join(tempDir.path, 'test_anima_multi_disc.db');

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

  group('Multi-Disc SQL Schema & SongDao Ordering Tests', () {
    test('Song model accurately serializes and deserializes discNumber', () {
      final song = Song(
        mediaStoreId: 101,
        title: 'Shine On You Crazy Diamond (Pts. 1-5)',
        artist: 'Pink Floyd',
        album: 'Wish You Were Here',
        duration: 810000,
        path: '/music/disc1/01.mp3',
        trackNumber: 1,
        discNumber: 1,
        dateModified: 1000,
      );

      final map = song.toMap();
      expect(map['disc_number'], equals(1));

      final restored = Song.fromMap(map);
      expect(restored.discNumber, equals(1));
      expect(restored.trackNumber, equals(1));
    });

    test('getSongsByAlbum sorts primarily by disc_number and secondarily by track_number', () async {
      final db = await appDatabase.database;

      // Insert tracks belonging to a 2-disc album in scrambled order
      final d2t2 = Song(
        mediaStoreId: 202,
        title: 'Disc 2 Track 2',
        artist: 'The Smashing Pumpkins',
        album: 'Mellon Collie and the Infinite Sadness',
        duration: 200000,
        path: '/music/d2_02.mp3',
        trackNumber: 2,
        discNumber: 2,
        dateModified: 1000,
      );
      final d1t2 = Song(
        mediaStoreId: 102,
        title: 'Disc 1 Track 2',
        artist: 'The Smashing Pumpkins',
        album: 'Mellon Collie and the Infinite Sadness',
        duration: 210000,
        path: '/music/d1_02.mp3',
        trackNumber: 2,
        discNumber: 1,
        dateModified: 1000,
      );
      final d2t1 = Song(
        mediaStoreId: 201,
        title: 'Disc 2 Track 1',
        artist: 'The Smashing Pumpkins',
        album: 'Mellon Collie and the Infinite Sadness',
        duration: 220000,
        path: '/music/d2_01.mp3',
        trackNumber: 1,
        discNumber: 2,
        dateModified: 1000,
      );
      final d1t1 = Song(
        mediaStoreId: 101,
        title: 'Disc 1 Track 1',
        artist: 'The Smashing Pumpkins',
        album: 'Mellon Collie and the Infinite Sadness',
        duration: 230000,
        path: '/music/d1_01.mp3',
        trackNumber: 1,
        discNumber: 1,
        dateModified: 1000,
      );

      await db.insert('songs', d2t2.toMap());
      await db.insert('songs', d1t2.toMap());
      await db.insert('songs', d2t1.toMap());
      await db.insert('songs', d1t1.toMap());

      final results = await songDao.getSongsByAlbum('Mellon Collie and the Infinite Sadness');

      expect(results.length, equals(4));
      // Expected sequence: Disc 1 Track 1 -> Disc 1 Track 2 -> Disc 2 Track 1 -> Disc 2 Track 2
      expect(results[0].mediaStoreId, equals(101));
      expect(results[0].discNumber, equals(1));
      expect(results[0].trackNumber, equals(1));

      expect(results[1].mediaStoreId, equals(102));
      expect(results[1].discNumber, equals(1));
      expect(results[1].trackNumber, equals(2));

      expect(results[2].mediaStoreId, equals(201));
      expect(results[2].discNumber, equals(2));
      expect(results[2].trackNumber, equals(1));

      expect(results[3].mediaStoreId, equals(202));
      expect(results[3].discNumber, equals(2));
      expect(results[3].trackNumber, equals(2));
    });

    test('backfillDiscNumbers updates disc_number in bulk ACID transaction', () async {
      final db = await appDatabase.database;

      final songA = Song(
        mediaStoreId: 301,
        title: 'Track A',
        artist: 'Artist',
        album: 'Double Album',
        duration: 180000,
        path: '/music/01.mp3',
        trackNumber: 1,
        discNumber: null,
        dateModified: 1000,
      );
      final songB = Song(
        mediaStoreId: 302,
        title: 'Track B',
        artist: 'Artist',
        album: 'Double Album',
        duration: 190000,
        path: '/music/02.mp3',
        trackNumber: 1,
        discNumber: null,
        dateModified: 1000,
      );

      await db.insert('songs', songA.toMap());
      await db.insert('songs', songB.toMap());

      expect(await songDao.isDiscNumberBackfilled(), isFalse);

      await songDao.backfillDiscNumbers({
        301: 1,
        302: 2,
      });
      await songDao.markDiscNumberBackfilled();

      expect(await songDao.isDiscNumberBackfilled(), isTrue);

      final songs = await songDao.getSongsByAlbum('Double Album');
      expect(songs.length, equals(2));
      expect(songs.firstWhere((s) => s.mediaStoreId == 301).discNumber, equals(1));
      expect(songs.firstWhere((s) => s.mediaStoreId == 302).discNumber, equals(2));
    });
  });

  group('AlbumTracksSection Multi-Disc UI Partitioning Tests', () {
    testWidgets('Single-disc album renders standard TRACKS header without any DISC headers', (tester) async {
      final List<Song> singleDiscSongs = [
        Song(
          mediaStoreId: 401,
          title: 'Track One',
          artist: 'Solo Artist',
          album: 'Single Disc Album',
          duration: 200000,
          path: '/music/01.mp3',
          trackNumber: 1,
          discNumber: 1,
          dateModified: 1000,
        ),
        Song(
          mediaStoreId: 402,
          title: 'Track Two',
          artist: 'Solo Artist',
          album: 'Single Disc Album',
          duration: 210000,
          path: '/music/02.mp3',
          trackNumber: 2,
          discNumber: 1,
          dateModified: 1000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AlbumTracksSection(songs: singleDiscSongs),
            ),
          ),
        ),
      );

      // Must show standard TRACKS header
      expect(find.text('TRACKS'), findsOneWidget);

      // Must NOT show DISC headers
      expect(find.text('DISC 1'), findsNothing);
      expect(find.text('DISC 2'), findsNothing);
      expect(find.textContaining('disco', findRichText: true), findsNothing);
      expect(find.textContaining('Disco', findRichText: true), findsNothing);

      // Both tracks rendered
      expect(find.text('Track One'), findsOneWidget);
      expect(find.text('Track Two'), findsOneWidget);
    });

    testWidgets('Multi-disc album renders English DISC 1 and DISC 2 headers with clean separation', (tester) async {
      final List<Song> multiDiscSongs = [
        Song(
          mediaStoreId: 501,
          title: 'Disc One Track One',
          artist: 'Band',
          album: 'Double LP',
          duration: 200000,
          path: '/music/d1_01.mp3',
          trackNumber: 1,
          discNumber: 1,
          dateModified: 1000,
        ),
        Song(
          mediaStoreId: 502,
          title: 'Disc One Track Two',
          artist: 'Band',
          album: 'Double LP',
          duration: 210000,
          path: '/music/d1_02.mp3',
          trackNumber: 2,
          discNumber: 1,
          dateModified: 1000,
        ),
        Song(
          mediaStoreId: 503,
          title: 'Disc Two Track One',
          artist: 'Band',
          album: 'Double LP',
          duration: 220000,
          path: '/music/d2_01.mp3',
          trackNumber: 1,
          discNumber: 2,
          dateModified: 1000,
        ),
        Song(
          mediaStoreId: 504,
          title: 'Disc Two Track Two',
          artist: 'Band',
          album: 'Double LP',
          duration: 230000,
          path: '/music/d2_02.mp3',
          trackNumber: 2,
          discNumber: 2,
          dateModified: 1000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AlbumTracksSection(songs: multiDiscSongs),
            ),
          ),
        ),
      );

      // Must render DISC 1 and DISC 2 headers
      expect(find.text('DISC 1'), findsOneWidget);
      expect(find.text('DISC 2'), findsOneWidget);

      // Must NOT render Spanish words
      expect(find.textContaining('disco', findRichText: true), findsNothing);
      expect(find.textContaining('Disco', findRichText: true), findsNothing);

      // All tracks present under their respective discs
      expect(find.text('Disc One Track One'), findsOneWidget);
      expect(find.text('Disc One Track Two'), findsOneWidget);
      expect(find.text('Disc Two Track One'), findsOneWidget);
      expect(find.text('Disc Two Track Two'), findsOneWidget);
    });
  });
}
