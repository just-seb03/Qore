/// File: discovery_anti_n_plus_one_test.dart
/// Description: Unit tests for Module 4.2: Anti-N+1 Relational Discovery Queries.
/// Validates single-query relational SQL aggregations for artists, albums,
/// and playback history without Dart loop anti-patterns.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late SongDao songDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            media_store_id INTEGER UNIQUE,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            album_id INTEGER,
            duration INTEGER,
            path TEXT NOT NULL,
            date_modified INTEGER,
            date_added INTEGER,
            size INTEGER
          )
        ''');

        await d.execute('''
          CREATE TABLE playback_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER,
            artist TEXT,
            played_at INTEGER NOT NULL,
            FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
          )
        ''');

        await d.execute('CREATE INDEX idx_songs_artist ON songs (artist COLLATE NOCASE)');
        await d.execute('CREATE INDEX idx_songs_album ON songs (album COLLATE NOCASE)');
        await d.execute('CREATE INDEX idx_history_played_at ON playback_history (played_at DESC)');
        await d.execute('CREATE INDEX idx_history_artist ON playback_history (artist COLLATE NOCASE)');
      },
    );

    songDao = SongDao(appDatabase: _MockAppDatabase(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('Module 4.2: Anti-N+1 Relational Discovery Tests', () {
    test('getDiscoveryArtists aggregates artist stats in a single relational query', () async {
      // Insert test songs across multiple artists and albums
      await songDao.syncDelta(
        toInsertOrUpdate: [
          // Artist 1: Queen (3 songs across 2 albums)
          const Song(
            mediaStoreId: 101,
            title: 'Bohemian Rhapsody',
            artist: 'Queen',
            album: 'A Night at the Opera',
            albumId: 10,
            duration: 354000,
            path: '/music/queen_1.mp3',
            dateModified: 1000,
          ),
          const Song(
            mediaStoreId: 102,
            title: 'Love of My Life',
            artist: 'Queen',
            album: 'A Night at the Opera',
            albumId: 10,
            duration: 219000,
            path: '/music/queen_2.mp3',
            dateModified: 1000,
          ),
          const Song(
            mediaStoreId: 103,
            title: 'Radio Ga Ga',
            artist: 'Queen',
            album: 'The Works',
            albumId: 11,
            duration: 343000,
            path: '/music/queen_3.mp3',
            dateModified: 1000,
          ),
          // Artist 2: Pink Floyd (2 songs in 1 album)
          const Song(
            mediaStoreId: 104,
            title: 'Time',
            artist: 'Pink Floyd',
            album: 'The Dark Side of the Moon',
            albumId: 20,
            duration: 425000,
            path: '/music/pf_1.mp3',
            dateModified: 2000,
          ),
          const Song(
            mediaStoreId: 105,
            title: 'Money',
            artist: 'Pink Floyd',
            album: 'The Dark Side of the Moon',
            albumId: 20,
            duration: 382000,
            path: '/music/pf_2.mp3',
            dateModified: 2000,
          ),
          // Excluded: unknown artist
          const Song(
            mediaStoreId: 106,
            title: 'Unknown Track',
            artist: '<Desconocido>',
            album: 'Various',
            duration: 180000,
            path: '/music/unk.mp3',
            dateModified: 3000,
          ),
        ],
        toDelete: [],
      );

      // Record playback for Pink Floyd (so Pink Floyd has a recent play timestamp)
      final allSongs = await songDao.getAllSongs();
      final pfSong = allSongs.firstWhere((s) => s.artist == 'Pink Floyd');
      await songDao.recordPlayback(
        songId: pfSong.id!,
        artist: 'Pink Floyd',
        timestampSeconds: 1700000000,
      );

      // Execute single relational query (Rule 4.2)
      final artists = await songDao.getDiscoveryArtists(limit: 10);

      expect(artists.length, 2);

      // 1st: Pink Floyd (ordered by last_played DESC because it has a play history record)
      final first = artists[0];
      expect(first.name, 'Pink Floyd');
      expect(first.songCount, 2);
      expect(first.albumCount, 1);
      expect(first.lastPlayed, 1700000000);
      expect(first.representativeSongId, 104);

      // 2nd: Queen (songCount = 3, distinct albums = 2, no play history)
      final second = artists[1];
      expect(second.name, 'Queen');
      expect(second.songCount, 3);
      expect(second.albumCount, 2);
      expect(second.lastPlayed, isNull);
    });

    test('getDiscoveryAlbums aggregates album stats in a single relational query', () async {
      await songDao.syncDelta(
        toInsertOrUpdate: [
          const Song(
            mediaStoreId: 201,
            title: 'Track A',
            artist: 'Daft Punk',
            album: 'Discovery',
            albumId: 50,
            duration: 200000,
            path: '/music/dp_1.mp3',
            dateModified: 1000,
          ),
          const Song(
            mediaStoreId: 202,
            title: 'Track B',
            artist: 'Daft Punk',
            album: 'Discovery',
            albumId: 50,
            duration: 240000,
            path: '/music/dp_2.mp3',
            dateModified: 1000,
          ),
          const Song(
            mediaStoreId: 203,
            title: 'Get Lucky',
            artist: 'Daft Punk',
            album: 'Random Access Memories',
            albumId: 51,
            duration: 360000,
            path: '/music/dp_3.mp3',
            dateModified: 2000,
          ),
        ],
        toDelete: [],
      );

      final albums = await songDao.getDiscoveryAlbums(limit: 5);
      expect(albums.length, 2);

      // 1st album: 'Discovery' has 2 songs, duration 440,000 ms
      final discoveryAlbum = albums.firstWhere((a) => a.name == 'Discovery');
      expect(discoveryAlbum.artist, 'Daft Punk');
      expect(discoveryAlbum.albumId, 50);
      expect(discoveryAlbum.songCount, 2);
      expect(discoveryAlbum.totalDuration, 440000);
      expect(discoveryAlbum.representativeSongId, 201);

      // 2nd album: 'Random Access Memories' has 1 song, duration 360,000 ms
      final ramAlbum = albums.firstWhere((a) => a.name == 'Random Access Memories');
      expect(ramAlbum.artist, 'Daft Punk');
      expect(ramAlbum.albumId, 51);
      expect(ramAlbum.songCount, 1);
      expect(ramAlbum.totalDuration, 360000);
      expect(ramAlbum.representativeSongId, 203);
    });

    test('recordPlayback and getRecentlyPlayedSongs retrieves history in a single JOIN query', () async {
      await songDao.syncDelta(
        toInsertOrUpdate: [
          const Song(
            mediaStoreId: 301,
            title: 'Paranoid Android',
            artist: 'Radiohead',
            album: 'OK Computer',
            duration: 383000,
            path: '/music/rh.mp3',
            dateModified: 1000,
          ),
        ],
        toDelete: [],
      );

      final songs = await songDao.getAllSongs();
      final songId = songs.first.id!;

      await songDao.recordPlayback(
        songId: songId,
        artist: 'Radiohead',
        timestampSeconds: 1690000000,
      );

      final recent = await songDao.getRecentlyPlayedSongs(limit: 5);
      expect(recent.length, 1);
      expect(recent.first.title, 'Paranoid Android');
      expect(recent.first.artist, 'Radiohead');
    });
  });
}

class _MockAppDatabase implements AppDatabase {
  final Database _database;
  _MockAppDatabase(this._database);

  @override
  Future<Database> get database async => _database;

  @override
  Future<void> close() async => await _database.close();

  @override
  Future<Database> initDatabase({String? customPath}) async => _database;
}
