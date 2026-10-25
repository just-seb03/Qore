import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/artist/components/artist_assorted_songs_section.dart';
import 'package:project_anima/features/artist/components/artist_discography_section.dart';
import 'package:project_anima/features/artist/components/artist_header_view.dart';
import 'package:project_anima/features/artist/components/artist_photo_options_sheet.dart';
import 'package:project_anima/features/artist/components/artist_top_tracks_section.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late SongDao songDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_test_');
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

  group('SongDao Artist Queries Tests', () {
    test('getTopSongsByArtist returns top 3 tracks based on playback history', () async {
      final db = await appDatabase.database;

      final song1 = Song(
        mediaStoreId: 101,
        title: 'One More Time',
        artist: 'Daft Punk',
        album: 'Discovery',
        duration: 320000,
        path: '/storage/one_more_time.mp3',
        dateAdded: 1000,
        dateModified: 2000,
      );
      final song2 = Song(
        mediaStoreId: 102,
        title: 'Harder, Better, Faster, Stronger',
        artist: 'Daft Punk',
        album: 'Discovery',
        duration: 224000,
        path: '/storage/harder.mp3',
        dateAdded: 1010,
        dateModified: 2010,
      );
      final song3 = Song(
        mediaStoreId: 103,
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: 360000,
        path: '/storage/get_lucky.mp3',
        dateAdded: 1020,
        dateModified: 2020,
      );
      final song4 = Song(
        mediaStoreId: 104,
        title: 'Around The World',
        artist: 'Daft Punk',
        album: 'Homework',
        duration: 420000,
        path: '/storage/around_the_world.mp3',
        dateAdded: 1030,
        dateModified: 2030,
      );

      final id1 = await db.insert('songs', song1.toMap());
      await db.insert('songs', song2.toMap());
      final id3 = await db.insert('songs', song3.toMap());
      final id4 = await db.insert('songs', song4.toMap());

      // song3 (Get Lucky): 10 plays
      // song1 (One More Time): 5 plays
      // song4 (Around The World): 2 plays
      // song2: 0 plays
      for (int i = 0; i < 10; i++) {
        await db.insert('playback_history', {
          'song_id': id3,
          'artist': 'Daft Punk',
          'played_at': 10000 + i,
        });
      }
      for (int i = 0; i < 5; i++) {
        await db.insert('playback_history', {
          'song_id': id1,
          'artist': 'Daft Punk',
          'played_at': 20000 + i,
        });
      }
      for (int i = 0; i < 2; i++) {
        await db.insert('playback_history', {
          'song_id': id4,
          'artist': 'Daft Punk',
          'played_at': 30000 + i,
        });
      }

      final topSongs = await songDao.getTopSongsByArtist('Daft Punk', limit: 3);

      expect(topSongs.length, 3);
      expect(topSongs[0].title, 'Get Lucky');
      expect(topSongs[1].title, 'One More Time');
      expect(topSongs[2].title, 'Around The World');
    });

    test('getAlbumsByArtist groups distinct albums and counts songs', () async {
      final db = await appDatabase.database;

      final s1 = Song(
        mediaStoreId: 201,
        title: 'Track A',
        artist: 'Radiohead',
        album: 'OK Computer',
        albumId: 10,
        duration: 180000,
        path: '/storage/a.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 202,
        title: 'Track B',
        artist: 'Radiohead',
        album: 'OK Computer',
        albumId: 10,
        duration: 200000,
        path: '/storage/b.mp3',
        dateModified: 100,
      );
      final s3 = Song(
        mediaStoreId: 203,
        title: 'Track C',
        artist: 'Radiohead',
        album: 'Kid A',
        albumId: 20,
        duration: 210000,
        path: '/storage/c.mp3',
        dateModified: 100,
      );

      for (final s in [s1, s2, s3]) {
        await db.insert('songs', s.toMap());
      }

      final albums = await songDao.getAlbumsByArtist('Radiohead');

      expect(albums.length, 2);
      final okComputer = albums.firstWhere((a) => a.name == 'OK Computer');
      expect(okComputer.songCount, 2);
      expect(okComputer.albumId, 10);

      final kidA = albums.firstWhere((a) => a.name == 'Kid A');
      expect(kidA.songCount, 1);
      expect(kidA.albumId, 20);
    });

    test('getAlbumsByArtist accurately counts songs without inflation even when playback history contains multiple plays', () async {
      final db = await appDatabase.database;

      final s1Id = await db.insert('songs', Song(
        mediaStoreId: 501,
        title: 'Airbag',
        artist: 'Radiohead',
        album: 'OK Computer Redux',
        albumId: 50,
        duration: 180000,
        path: '/storage/airbag.mp3',
        dateModified: 100,
      ).toMap());

      final s2Id = await db.insert('songs', Song(
        mediaStoreId: 502,
        title: 'Paranoid Android',
        artist: 'Radiohead',
        album: 'OK Computer Redux',
        albumId: 50,
        duration: 200000,
        path: '/storage/paranoid.mp3',
        dateModified: 100,
      ).toMap());

      // Simulate multiple playback events for s1
      for (int i = 0; i < 7; i++) {
        await songDao.recordPlayback(songId: s1Id, artist: 'Radiohead', timestampSeconds: 1000 + i);
      }
      // Simulate playback events for s2
      for (int i = 0; i < 3; i++) {
        await songDao.recordPlayback(songId: s2Id, artist: 'Radiohead', timestampSeconds: 2000 + i);
      }

      final albums = await songDao.getAlbumsByArtist('Radiohead');
      final okComputerRedux = albums.firstWhere((a) => a.name == 'OK Computer Redux');

      // Crucial: Must be exactly 2 songs, NOT 2 + 7 + 3 = 12 songs!
      expect(okComputerRedux.songCount, 2);
      expect(okComputerRedux.totalDuration, 180000 + 200000);
      expect(okComputerRedux.lastPlayed, isNotNull);
    });

    test('getAssortedSongsByArtist returns up to limit ordered by date', () async {
      final db = await appDatabase.database;

      final songs = List.generate(
        15,
        (i) => Song(
          mediaStoreId: 300 + i,
          title: 'Song $i',
          artist: 'Gorillaz',
          album: 'Demon Days',
          duration: 150000,
          path: '/storage/song_$i.mp3',
          dateModified: 1000 + i,
          dateAdded: 500 + i,
        ),
      );

      for (final s in songs) {
        await db.insert('songs', s.toMap());
      }

      final assorted = await songDao.getAssortedSongsByArtist('Gorillaz', limit: 10);

      expect(assorted.length, 10);
      // Descending order by dateModified:
      expect(assorted.first.title, 'Song 14');
      expect(assorted.last.title, 'Song 5');
    });
  });

  group('ArtworkService Custom Artist Avatar Tests', () {
    test('can set, retrieve, and remove custom artist avatar', () async {
      final service = ArtworkService.instance;
      await service.initialize(baseDir: tempDir);
      const artist = 'The Strokes';

      // 1. Initially null or removed
      await service.removeCustomArtistAvatar(artist);
      expect(service.getCustomArtistAvatar(artist), isNull);

      // 2. Set custom avatar bytes
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final savedPath = await service.setCustomArtistAvatar(artist, testBytes);
      final savedFile = File(savedPath);

      expect(savedFile.existsSync(), isTrue);
      expect(savedFile.readAsBytesSync(), testBytes);

      // 3. In-memory and on-disk lookup returns file path
      final retrieved = service.getCustomArtistAvatar(artist);
      expect(retrieved, isNotNull);
      expect(retrieved, savedPath);

      // Case insensitivity & trimming test
      final retrievedCaseInsensitive = service.getCustomArtistAvatar(' the strokes ');
      expect(retrievedCaseInsensitive, isNotNull);
      expect(retrievedCaseInsensitive, savedPath);

      // 4. Remove custom avatar
      await service.removeCustomArtistAvatar(artist);
      expect(service.getCustomArtistAvatar(artist), isNull);
      expect(savedFile.existsSync(), isFalse);
    });
  });

  group('Artist Components & Screen Layout Tests', () {
    testWidgets('ArtistHeaderView renders artist avatar, name, and invokes edit tap', (tester) async {
      bool editTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistHeaderView(
              artistName: 'Daft Punk',
              onEditTap: () => editTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pump();

      expect(editTapped, isTrue);
    });

    testWidgets('ArtistTopTracksSection renders FEATURED header and tracks', (tester) async {
      final songs = [
        Song(
          mediaStoreId: 101,
          title: 'One More Time',
          artist: 'Daft Punk',
          album: 'Discovery',
          duration: 320000,
          path: '/test.mp3',
          dateModified: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistTopTracksSection(
              topSongs: songs,
              allArtistSongs: songs,
            ),
          ),
        ),
      );

      expect(find.text('FEATURED'), findsOneWidget);
      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
    });

    testWidgets('ArtistDiscographySection renders DISCOGRAPHY header and album cards', (tester) async {
      const albums = [
        AlbumDiscoveryItem(
          name: 'Discovery',
          artist: 'Daft Punk',
          representativeSongId: 101,
          songCount: 14,
          totalDuration: 3600000,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistDiscographySection(albums: albums),
          ),
        ),
      );

      expect(find.text('DISCOGRAPHY'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('14 songs'), findsOneWidget);
    });

    testWidgets('ArtistAssortedSongsSection renders SONGS header and compact track tile', (tester) async {
      final songs = [
        Song(
          mediaStoreId: 102,
          title: 'Aerodynamic',
          artist: 'Daft Punk',
          album: 'Discovery',
          duration: 210000,
          path: '/test2.mp3',
          dateModified: 100,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistAssortedSongsSection(
              songs: songs,
              allArtistSongs: songs,
            ),
          ),
        ),
      );

      expect(find.text('SONGS'), findsOneWidget);
      expect(find.text('Aerodynamic'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
    });

    testWidgets('ArtistPhotoOptionsSheet renders options and triggers callbacks', (tester) async {
      bool changeTriggered = false;
      bool removeTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistPhotoOptionsSheet(
              onChangePhoto: () => changeTriggered = true,
              onRemovePhoto: () => removeTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Change artist photo'), findsOneWidget);
      expect(find.text('Remove custom photo'), findsOneWidget);

      await tester.tap(find.text('Change artist photo'));
      await tester.pump();
      expect(changeTriggered, isTrue);

      await tester.tap(find.text('Remove custom photo'));
      await tester.pump();
      expect(removeTriggered, isTrue);
    });
  });
}
