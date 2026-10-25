import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Album-Artist Priority and Multi-Artist Aggregation Tests', () {
    late Directory tempDir;
    late AppDatabase appDatabase;
    late SongDao songDao;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('anima_album_priority_test_');
      final dbPath = p.join(tempDir.path, 'test_album_priority.db');

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

    test('getLibraryAlbums groups collaborative tracks into 1 album under album_artist and never splits', () async {
      final db = await appDatabase.database;

      // Album "Random Access Memories" by "Daft Punk" with 3 distinct track artists
      final t1 = Song(
        mediaStoreId: 101,
        title: 'Give Life Back to Music',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        albumArtist: 'Daft Punk',
        albumId: 42,
        duration: 274000,
        path: '/storage/01.mp3',
        dateModified: 100,
      );
      final t2 = Song(
        mediaStoreId: 102,
        title: 'Instant Crush',
        artist: 'Julian Casablancas',
        album: 'Random Access Memories',
        albumArtist: 'Daft Punk',
        albumId: 42,
        duration: 337000,
        path: '/storage/02.mp3',
        dateModified: 100,
      );
      final t3 = Song(
        mediaStoreId: 103,
        title: 'Get Lucky',
        artist: 'Pharrell Williams',
        album: 'Random Access Memories',
        albumArtist: 'Daft Punk',
        albumId: 42,
        duration: 369000,
        path: '/storage/03.mp3',
        dateModified: 100,
      );

      for (final s in [t1, t2, t3]) {
        await db.insert('songs', s.toMap());
      }

      final libraryAlbums = await songDao.getLibraryAlbums();

      // Must be grouped into exactly 1 album
      expect(libraryAlbums.length, 1);
      final ram = libraryAlbums.first;
      expect(ram.name, 'Random Access Memories');
      expect(ram.artist, 'Daft Punk');
      expect(ram.songCount, 3);

      // getSongsByAlbum returns all 3 tracks
      final ramSongs = await songDao.getSongsByAlbum('Random Access Memories', artist: 'Daft Punk', albumId: 42);
      expect(ramSongs.length, 3);
      expect(ramSongs.map((s) => s.title), containsAll(['Give Life Back to Music', 'Instant Crush', 'Get Lucky']));
    });

    test('getLibraryAlbums unifies album when some tracks have album_artist and some have null tag', () async {
      final db = await appDatabase.database;

      // Album where track 1 has album_artist, but track 2 has null album_artist
      final t1 = Song(
        mediaStoreId: 201,
        title: 'Track With Tag',
        artist: 'Producer X feat. Singer A',
        album: 'Unified Album',
        albumArtist: 'Producer X',
        albumId: 88,
        duration: 200000,
        path: '/storage/u1.mp3',
        dateModified: 100,
      );
      final t2 = Song(
        mediaStoreId: 202,
        title: 'Track Without Tag',
        artist: 'Singer B',
        album: 'Unified Album',
        albumArtist: null,
        albumId: 88,
        duration: 210000,
        path: '/storage/u2.mp3',
        dateModified: 100,
      );

      for (final s in [t1, t2]) {
        await db.insert('songs', s.toMap());
      }

      final libraryAlbums = await songDao.getLibraryAlbums();
      expect(libraryAlbums.length, 1);
      expect(libraryAlbums.first.name, 'Unified Album');
      expect(libraryAlbums.first.artist, 'Producer X');
      expect(libraryAlbums.first.songCount, 2);

      // Verify no songs disappear when querying album
      final songs = await songDao.getSongsByAlbum('Unified Album', artist: 'Producer X', albumId: 88);
      expect(songs.length, 2);
    });

    test('Accessing album through featured artist returns the complete album of album_artist', () async {
      final db = await appDatabase.database;

      final t1 = Song(
        mediaStoreId: 301,
        title: 'Starboy',
        artist: 'The Weeknd feat. Daft Punk',
        album: 'Starboy',
        albumArtist: 'The Weeknd',
        albumId: 99,
        duration: 230000,
        path: '/storage/sb1.mp3',
        dateModified: 100,
      );
      final t2 = Song(
        mediaStoreId: 302,
        title: 'Party Monster',
        artist: 'The Weeknd',
        album: 'Starboy',
        albumArtist: 'The Weeknd',
        albumId: 99,
        duration: 240000,
        path: '/storage/sb2.mp3',
        dateModified: 100,
      );
      final t3 = Song(
        mediaStoreId: 303,
        title: 'I Feel It Coming',
        artist: 'The Weeknd feat. Daft Punk',
        album: 'Starboy',
        albumArtist: 'The Weeknd',
        albumId: 99,
        duration: 269000,
        path: '/storage/sb3.mp3',
        dateModified: 100,
      );

      for (final s in [t1, t2, t3]) {
        await db.insert('songs', s.toMap());
      }

      // 1. Primary album_artist discography returns album with total count and album_artist
      final theWeekndAlbums = await songDao.getAlbumsByArtist('The Weeknd');
      expect(theWeekndAlbums.isNotEmpty, isTrue);
      final starboyInWeeknd = theWeekndAlbums.firstWhere((a) => a.name == 'Starboy');
      expect(starboyInWeeknd.artist, 'The Weeknd');
      expect(starboyInWeeknd.songCount, 3); // Full 3 tracks

      // Featured artist discography must NOT claim the parent artist's album
      final daftPunkAlbums = await songDao.getAlbumsByArtist('Daft Punk');
      expect(daftPunkAlbums.any((a) => a.name == 'Starboy'), isFalse);

      // 2. Querying album even with featured artist name resolves to full album of album_artist
      final songsAccessedViaFeature = await songDao.getSongsByAlbum(
        'Starboy',
        artist: 'Daft Punk',
        albumId: 99,
      );
      expect(songsAccessedViaFeature.length, 3);
      expect(songsAccessedViaFeature.map((s) => s.title), containsAll(['Starboy', 'Party Monster', 'I Feel It Coming']));
    });

    test('Albums without album_artist fall back to track artist cleanly', () async {
      final db = await appDatabase.database;

      final s1 = Song(
        mediaStoreId: 401,
        title: 'Track 1',
        artist: 'Solo Artist',
        album: 'No Tag Album',
        albumArtist: null,
        albumId: 12,
        duration: 180000,
        path: '/storage/nt1.mp3',
        dateModified: 100,
      );
      await db.insert('songs', s1.toMap());

      final albums = await songDao.getLibraryAlbums();
      expect(albums.length, 1);
      expect(albums.first.name, 'No Tag Album');
      expect(albums.first.artist, 'Solo Artist');
      expect(albums.first.songCount, 1);
    });
  });
}
