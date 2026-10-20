/// File: album_artist_grouping_test.dart
/// Description: Unit tests verifying album artist grouping, song counting for collaborative
/// albums, fallback to track artist when album_artist is absent, and batch backfill operations.
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppDatabase.initializeFfiIfNeeded();

  late AppDatabase appDatabase;
  late SongDao songDao;
  late String testDbPath;

  setUp(() async {
    testDbPath = '${Directory.systemTemp.path}/test_anima_${DateTime.now().microsecondsSinceEpoch}.db';
    appDatabase = AppDatabase();
    await appDatabase.initDatabase(customPath: testDbPath);
    songDao = SongDao(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    final file = File(testDbPath);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  });

  group('Album Artist Grouping & Song Count Tests', () {
    test('Collaborative album tracks with different track artists but same album_artist are grouped as 1 album with full song count', () async {
      final songs = [
        Song(
          mediaStoreId: 101,
          title: 'Jail',
          artist: 'Kanye West ft. Jay-Z',
          album: 'Donda',
          albumArtist: 'Kanye West',
          albumId: 10,
          duration: 297000,
          path: '/music/donda_01.mp3',
          dateModified: 1000,
        ),
        Song(
          mediaStoreId: 102,
          title: 'Moon',
          artist: 'Kanye West ft. Kid Cudi',
          album: 'Donda',
          albumArtist: 'Kanye West',
          albumId: 10,
          duration: 156000,
          path: '/music/donda_02.mp3',
          dateModified: 1001,
        ),
        Song(
          mediaStoreId: 103,
          title: 'Hurricane',
          artist: 'Kanye West ft. The Weeknd & Lil Baby',
          album: 'Donda',
          albumArtist: 'Kanye West',
          albumId: 10,
          duration: 243000,
          path: '/music/donda_03.mp3',
          dateModified: 1002,
        ),
      ];

      await songDao.syncDelta(toInsertOrUpdate: songs, toDelete: []);

      final albums = await songDao.getDiscoveryAlbums(limit: 10);

      expect(albums.length, equals(1),
          reason: 'All collaborative tracks belonging to Kanye West must group into 1 single album');
      expect(albums.first.name, equals('Donda'));
      expect(albums.first.artist, equals('Kanye West'),
          reason: 'Album artist must take precedence over track artist');
      expect(albums.first.songCount, equals(3),
          reason: 'All 3 songs must be counted together, not split into 1-song albums');
    });

    test('Album with NO album_artist falls back to track artist', () async {
      final songs = [
        Song(
          mediaStoreId: 201,
          title: 'Bohemian Rhapsody',
          artist: 'Queen',
          album: 'A Night at the Opera',
          albumArtist: null,
          albumId: 20,
          duration: 354000,
          path: '/music/queen_01.mp3',
          dateModified: 2000,
        ),
        Song(
          mediaStoreId: 202,
          title: 'Love of My Life',
          artist: 'Queen',
          album: 'A Night at the Opera',
          albumArtist: null,
          albumId: 20,
          duration: 219000,
          path: '/music/queen_02.mp3',
          dateModified: 2001,
        ),
      ];

      await songDao.syncDelta(toInsertOrUpdate: songs, toDelete: []);

      final albums = await songDao.getDiscoveryAlbums(limit: 10);

      expect(albums.length, equals(1));
      expect(albums.first.name, equals('A Night at the Opera'));
      expect(albums.first.artist, equals('Queen'),
          reason: 'Must fallback to track artist when album_artist is null');
      expect(albums.first.songCount, equals(2));
    });

    test('Partially tagged album resolves to album_artist and counts all tracks', () async {
      final songs = [
        Song(
          mediaStoreId: 301,
          title: 'Champagne Poetry',
          artist: 'Drake',
          album: 'Certified Lover Boy',
          albumArtist: 'Drake',
          albumId: 30,
          duration: 336000,
          path: '/music/clb_01.mp3',
          dateModified: 3000,
        ),
        Song(
          mediaStoreId: 302,
          title: 'Knife Talk',
          artist: 'Drake ft. 21 Savage & Project Pat',
          album: 'Certified Lover Boy',
          albumArtist: null, // Untagged on this specific track
          albumId: 30,
          duration: 242000,
          path: '/music/clb_02.mp3',
          dateModified: 3001,
        ),
      ];

      await songDao.syncDelta(toInsertOrUpdate: songs, toDelete: []);

      final albums = await songDao.getDiscoveryAlbums(limit: 10);

      expect(albums.length, equals(1));
      expect(albums.first.name, equals('Certified Lover Boy'));
      expect(albums.first.artist, equals('Drake'));
      expect(albums.first.songCount, equals(2),
          reason: 'Even untagged tracks in the same album resolve to the album owner and count together');
    });

    test('getSongsByAlbum retrieves all collaborative tracks when scoped by album_artist', () async {
      final songs = [
        Song(
          mediaStoreId: 401,
          title: 'SICKO MODE',
          artist: 'Travis Scott ft. Drake',
          album: 'ASTROWORLD',
          albumArtist: 'Travis Scott',
          albumId: 40,
          duration: 312000,
          path: '/music/astroworld_01.mp3',
          dateModified: 4000,
        ),
        Song(
          mediaStoreId: 402,
          title: 'STARGAZING',
          artist: 'Travis Scott',
          album: 'ASTROWORLD',
          albumArtist: 'Travis Scott',
          albumId: 40,
          duration: 270000,
          path: '/music/astroworld_02.mp3',
          dateModified: 4001,
        ),
      ];

      await songDao.syncDelta(toInsertOrUpdate: songs, toDelete: []);

      final albumTracks = await songDao.getSongsByAlbum('ASTROWORLD', artist: 'Travis Scott');

      expect(albumTracks.length, equals(2),
          reason: 'All tracks under ASTROWORLD by Travis Scott must be returned, including features');
    });

    test('One-time backfill populates missing album_artist on cached songs', () async {
      // Simulate tracks indexed in database v1 without album_artist
      final songs = [
        Song(
          mediaStoreId: 501,
          title: 'Track A',
          artist: 'Guest ft. Host',
          album: 'Collab Album',
          albumArtist: null,
          albumId: 50,
          duration: 180000,
          path: '/music/collab_01.mp3',
          dateModified: 5000,
        ),
      ];

      await songDao.syncDelta(toInsertOrUpdate: songs, toDelete: []);

      expect(await songDao.isAlbumArtistBackfilled(), isFalse);

      // Execute batch backfill from projection map
      final backfillMap = {501: 'Host Artist'};
      await songDao.backfillAlbumArtists(backfillMap);
      await songDao.markAlbumArtistBackfilled();

      expect(await songDao.isAlbumArtistBackfilled(), isTrue);

      final updatedSongs = await songDao.getAllSongs();
      expect(updatedSongs.first.albumArtist, equals('Host Artist'));

      final albums = await songDao.getDiscoveryAlbums(limit: 10);
      expect(albums.first.artist, equals('Host Artist'));
    });

    test('FuzzySearchEngine returns collaborative songs for album top result', () async {
      final songs = [
        Song(
          mediaStoreId: 601,
          title: 'Ultralight Beam',
          artist: 'Kanye West ft. The-Dream & Kelly Price',
          album: 'The Life of Pablo',
          albumArtist: 'Kanye West',
          albumId: 60,
          duration: 320000,
          path: '/music/tlop_01.mp3',
          dateModified: 6000,
        ),
        Song(
          mediaStoreId: 602,
          title: 'Famous',
          artist: 'Kanye West ft. Rihanna',
          album: 'The Life of Pablo',
          albumArtist: 'Kanye West',
          albumId: 60,
          duration: 196000,
          path: '/music/tlop_02.mp3',
          dateModified: 6001,
        ),
      ];

      await songDao.syncDelta(toInsertOrUpdate: songs, toDelete: []);

      final searchEngine = FuzzySearchEngine(songDao: songDao);
      await searchEngine.reloadDictionary();

      final results = await searchEngine.search('Life of Pablo');

      expect(results.topResult?.type, equals(SearchEntityType.album));
      expect(results.topResult?.album?.name, equals('The Life of Pablo'));
      expect(results.topResult?.album?.artist, equals('Kanye West'));
      expect(results.topResult?.album?.songCount, equals(2),
          reason: 'Album top result must count all collaborative tracks');
      expect(results.matchedSongs.length, equals(2));
    });
  });
}
