import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/artwork/artwork_service.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/library/components/albums/library_album_card.dart';
import 'package:project_anima/features/library/components/albums/library_albums_grid.dart';
import 'package:project_anima/features/library/components/artists/library_artist_tile.dart';
import 'package:project_anima/features/library/components/artists/library_artists_list.dart';
import 'package:project_anima/features/library/components/library_category_bar.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_placeholder.dart';
import 'package:project_anima/features/library/components/songs/library_songs_list.dart';
import 'package:project_anima/features/library/controls/library_transition_controller.dart';
import 'package:project_anima/features/library/screens/library.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late SongDao songDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_library_test_');
    final dbPath = p.join(tempDir.path, 'test_anima_library.db');

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

  group('SongDao Library Queries & De-duplication Tests', () {
    test('getLibraryAlbums groups collaborative tracks into a single album without duplicates', () async {
      // Insert tracks of "Discovery" where some tracks have features
      final t1 = Song(
        mediaStoreId: 101,
        title: 'One More Time',
        artist: 'Daft Punk',
        album: 'Discovery',
        albumArtist: 'Daft Punk',
        duration: 320000,
        path: '/storage/01.mp3',
        dateModified: 100,
      );
      final t2 = Song(
        mediaStoreId: 102,
        title: 'Digital Love',
        artist: 'Daft Punk feat. DJ',
        album: 'Discovery',
        albumArtist: 'Daft Punk',
        duration: 300000,
        path: '/storage/02.mp3',
        dateModified: 100,
      );
      final t3 = Song(
        mediaStoreId: 103,
        title: 'Harder, Better, Faster, Stronger',
        artist: 'Daft Punk',
        album: 'Discovery',
        albumArtist: null, // missing album_artist on this track
        duration: 224000,
        path: '/storage/03.mp3',
        dateModified: 100,
      );

      // Insert another album to test alphabetical sorting
      final t4 = Song(
        mediaStoreId: 201,
        title: 'Come Together',
        artist: 'The Beatles',
        album: 'Abbey Road',
        albumArtist: 'The Beatles',
        duration: 259000,
        path: '/storage/abbey.mp3',
        dateModified: 100,
      );

      final db = await appDatabase.database;
      await db.insert('songs', t1.toMap());
      await db.insert('songs', t2.toMap());
      await db.insert('songs', t3.toMap());
      await db.insert('songs', t4.toMap());

      final albums = await songDao.getLibraryAlbums();

      // Exactly 2 distinct albums, NOT 4!
      expect(albums.length, 2);

      // Sorted alphabetically: Abbey Road first, Discovery second
      expect(albums[0].name, 'Abbey Road');
      expect(albums[0].artist, 'The Beatles');
      expect(albums[0].songCount, 1);

      expect(albums[1].name, 'Discovery');
      expect(albums[1].artist, 'Daft Punk');
      expect(albums[1].songCount, 3);
    });

    test('getLibraryAlbums correctly separates two distinct albums with identical titles', () async {
      final t1 = Song(
        mediaStoreId: 501,
        title: 'Thunderstruck (Live)',
        artist: 'AC/DC',
        album: 'Live',
        albumArtist: null,
        albumId: 777,
        duration: 300000,
        path: '/storage/acdc_live.mp3',
        dateModified: 100,
      );
      final t2 = Song(
        mediaStoreId: 502,
        title: 'Fear of the Dark (Live)',
        artist: 'Iron Maiden',
        album: 'Live',
        albumArtist: null,
        albumId: 777,
        duration: 400000,
        path: '/storage/maiden_live.mp3',
        dateModified: 100,
      );

      final db = await appDatabase.database;
      await db.insert('songs', t1.toMap());
      await db.insert('songs', t2.toMap());

      final albums = await songDao.getLibraryAlbums();

      expect(albums.length, 2);
      expect(albums.any((a) => a.name == 'Live' && a.artist == 'AC/DC' && a.representativeSongId == 501), isTrue);
      expect(albums.any((a) => a.name == 'Live' && a.artist == 'Iron Maiden' && a.representativeSongId == 502), isTrue);

      final acdcSongs = await songDao.getSongsByAlbum('Live', artist: 'AC/DC', albumId: 777);
      expect(acdcSongs.length, 1);
      expect(acdcSongs.first.artist, 'AC/DC');

      final maidenSongs = await songDao.getSongsByAlbum('Live', artist: 'Iron Maiden', albumId: 777);
      expect(maidenSongs.length, 1);
      expect(maidenSongs.first.artist, 'Iron Maiden');
    });

    test('getLibraryAlbums groups collaborative album with 10 features and no album_artist tag into 1 single album', () async {
      // 10 tracks of the same album without album_artist tag, each featuring different artists and mediaStore album_ids
      final tracks = [
        Song(mediaStoreId: 901, title: 'Track 1', artist: 'Metro Boomin', album: 'Heroes & Villains', albumArtist: null, albumId: 10, duration: 180000, path: '/01.mp3', dateModified: 100),
        Song(mediaStoreId: 902, title: 'Track 2', artist: 'Metro Boomin, Future & Chris Brown', album: 'Heroes & Villains', albumArtist: null, albumId: 11, duration: 190000, path: '/02.mp3', dateModified: 100),
        Song(mediaStoreId: 903, title: 'Track 3', artist: 'Metro Boomin feat. 21 Savage', album: 'Heroes & Villains', albumArtist: null, albumId: 12, duration: 200000, path: '/03.mp3', dateModified: 100),
        Song(mediaStoreId: 904, title: 'Track 4', artist: 'Metro Boomin ft. Young Thug', album: 'Heroes & Villains', albumArtist: null, albumId: 13, duration: 210000, path: '/04.mp3', dateModified: 100),
        Song(mediaStoreId: 905, title: 'Track 5', artist: 'Metro Boomin & Travis Scott', album: 'Heroes & Villains', albumArtist: null, albumId: 14, duration: 220000, path: '/05.mp3', dateModified: 100),
        Song(mediaStoreId: 906, title: 'Track 6', artist: 'Metro Boomin featuring John Legend', album: 'Heroes & Villains', albumArtist: null, albumId: 15, duration: 230000, path: '/06.mp3', dateModified: 100),
        Song(mediaStoreId: 907, title: 'Track 7', artist: 'Metro Boomin with The Weeknd', album: 'Heroes & Villains', albumArtist: null, albumId: 16, duration: 240000, path: '/07.mp3', dateModified: 100),
        Song(mediaStoreId: 908, title: 'Track 8', artist: 'Metro Boomin, Gunna', album: 'Heroes & Villains', albumArtist: null, albumId: 17, duration: 250000, path: '/08.mp3', dateModified: 100),
        Song(mediaStoreId: 909, title: 'Track 9', artist: 'Metro Boomin feat. Don Toliver', album: 'Heroes & Villains', albumArtist: null, albumId: 18, duration: 260000, path: '/09.mp3', dateModified: 100),
        Song(mediaStoreId: 910, title: 'Track 10', artist: 'Metro Boomin & A\$AP Rocky', album: 'Heroes & Villains', albumArtist: null, albumId: 19, duration: 270000, path: '/10.mp3', dateModified: 100),
      ];

      final db = await appDatabase.database;
      for (final t in tracks) {
        await db.insert('songs', t.toMap());
      }

      final albums = await songDao.getLibraryAlbums();
      // Must be grouped into exactly 1 album, NOT 10 albums!
      expect(albums.length, 1);
      expect(albums.first.name, 'Heroes & Villains');
      expect(albums.first.artist, 'Metro Boomin');
      expect(albums.first.songCount, 10);

      // getSongsByAlbum retrieves all 10 tracks
      final albumSongs = await songDao.getSongsByAlbum('Heroes & Villains', artist: 'Metro Boomin');
      expect(albumSongs.length, 10);
    });

    test('getLibraryArtists retrieves distinct artists ordered alphabetically', () async {
      final s1 = Song(
        mediaStoreId: 301,
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: 230000,
        path: '/storage/s1.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 302,
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'RAM',
        duration: 240000,
        path: '/storage/s2.mp3',
        dateModified: 100,
      );
      final s3 = Song(
        mediaStoreId: 303,
        title: 'Lose Yourself to Dance',
        artist: 'Daft Punk',
        album: 'RAM',
        duration: 250000,
        path: '/storage/s3.mp3',
        dateModified: 100,
      );

      final db = await appDatabase.database;
      await db.insert('songs', s1.toMap());
      await db.insert('songs', s2.toMap());
      await db.insert('songs', s3.toMap());

      final artists = await songDao.getLibraryArtists();

      expect(artists.length, 2);
      expect(artists[0].name, 'Daft Punk');
      expect(artists[0].songCount, 2);
      expect(artists[1].name, 'The Weeknd');
      expect(artists[1].songCount, 1);
    });
  });

  group('LibraryFilterPills Single Selection Tests', () {
    testWidgets('renders Albums selected by default', (tester) async {
      LibraryFilter selected = LibraryFilter.albums;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryFilterPills(
              selectedFilter: selected,
              onFilterChanged: (filter) {
                selected = filter;
              },
            ),
          ),
        ),
      );

      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);

      // Tap on Artists
      await tester.tap(find.text('Artists'));
      await tester.pump();

      expect(selected, LibraryFilter.artists);
    });
  });

  group('LibraryAlbumCard Styling Tests', () {
    testWidgets('renders sharp 0.0 border radius cover with shadow', (tester) async {
      const album = AlbumDiscoveryItem(
        name: 'Random Access Memories',
        artist: 'Daft Punk',
        representativeSongId: 101,
        songCount: 13,
        totalDuration: 4000000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 240,
              child: LibraryAlbumCard(album: album),
            ),
          ),
        ),
      );

      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);

      // Verify shadow decoration is present
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            ((widget.decoration as BoxDecoration).boxShadow?.isNotEmpty ?? false),
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('AnimaArtworkImage handles double.infinity width and height without toInt crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: AnimaArtworkImage(
                mediaStoreId: 9999,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0.0,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AnimaArtworkImage), findsOneWidget);
    });

    test('ArtworkService maintains independent covers for songs even if albums share identical titles', () async {
      final artworkDir = await Directory.systemTemp.createTemp('anima_art_test_');
      addTearDown(() {
        if (artworkDir.existsSync()) {
          artworkDir.deleteSync(recursive: true);
        }
      });

      ArtworkService.instance.reset();
      await ArtworkService.instance.initialize(baseDir: artworkDir);

      // Create fake cover files for song 501 and song 502
      final coversDir = Directory(p.join(artworkDir.path, 'anima_artworks', 'covers'));
      final acdcCover = File(p.join(coversDir.path, '501.jpg'));
      final maidenCover = File(p.join(coversDir.path, '502.jpg'));
      await acdcCover.writeAsBytes([1, 2, 3]);
      await maidenCover.writeAsBytes([4, 5, 6]);

      // Re-initialize so ArtworkService loads both into memory
      ArtworkService.instance.reset();
      await ArtworkService.instance.initialize(baseDir: artworkDir);

      expect(ArtworkService.instance.getCoverPath(501), acdcCover.path);
      expect(ArtworkService.instance.getCoverPath(502), maidenCover.path);
      expect(ArtworkService.instance.getCoverPath(501), isNot(equals(ArtworkService.instance.getCoverPath(502))));
      // albumId fallback does not collide
      expect(ArtworkService.instance.getCoverPath(501, albumId: 777), acdcCover.path);
      expect(ArtworkService.instance.getCoverPath(502, albumId: 777), maidenCover.path);
    });

    testWidgets('LibraryAlbumCard renders distinct covers for two albums with identical titles', (tester) async {
      ArtworkService.instance.reset();

      const albumA = AlbumDiscoveryItem(
        name: 'Live',
        artist: 'AC/DC',
        albumId: 777,
        representativeSongId: 501,
        songCount: 1,
        totalDuration: 300000,
      );
      const albumB = AlbumDiscoveryItem(
        name: 'Live',
        artist: 'Iron Maiden',
        albumId: 777,
        representativeSongId: 502,
        songCount: 1,
        totalDuration: 400000,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(width: 150, height: 240, child: LibraryAlbumCard(album: albumA)),
                SizedBox(width: 150, height: 240, child: LibraryAlbumCard(album: albumB)),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Live'), findsNWidgets(2));
      expect(find.text('AC/DC'), findsOneWidget);
      expect(find.text('Iron Maiden'), findsOneWidget);

      final artworkFinders = find.byType(AnimaArtworkImage);
      expect(artworkFinders, findsNWidgets(2));

      final imageA = tester.widget<AnimaArtworkImage>(artworkFinders.at(0));
      final imageB = tester.widget<AnimaArtworkImage>(artworkFinders.at(1));

      expect(imageA.mediaStoreId, 501);
      expect(imageB.mediaStoreId, 502);
      expect(imageA.albumId, isNull);
      expect(imageB.albumId, isNull);
      expect(imageA.mediaStoreId, isNot(equals(imageB.mediaStoreId)));
    });

    testWidgets(
      'AnimaArtworkImage only listens while cover path is unresolved and ignores unrelated updates',
      (tester) async {
        late Directory artworkDir;
        late Directory coversDir;

        await tester.runAsync(() async {
          artworkDir = await Directory.systemTemp.createTemp('anima_art_listener_test_');
          ArtworkService.instance.reset();
          await ArtworkService.instance.initialize(baseDir: artworkDir, songDao: songDao);
          coversDir = Directory(p.join(artworkDir.path, 'anima_artworks', 'covers'));
          await File(p.join(coversDir.path, '801.jpg')).writeAsBytes([1, 2, 3]);
          ArtworkService.instance.reset();
          await ArtworkService.instance.initialize(baseDir: artworkDir, songDao: songDao);
        });

        addTearDown(() {
          ArtworkService.instance.reset();
          if (artworkDir.existsSync()) {
            artworkDir.deleteSync(recursive: true);
          }
        });

        // 1. Resolved artwork skips listening to ArtworkService altogether.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AnimaArtworkImage(
                mediaStoreId: 801,
                isThumbnail: false,
              ),
            ),
          ),
        );
        expect(find.byType(Image), findsOneWidget);
        expect(ArtworkService.instance.debugHasListeners, isFalse);

        // 2. Switching to unresolved artwork attaches listener and renders fallback.
        int fallbackBuilds = 0;
        Widget buildUnresolved(int id) => MaterialApp(
              home: Scaffold(
                body: AnimaArtworkImage(
                  mediaStoreId: id,
                  isThumbnail: false,
                  fallback: Builder(
                    builder: (_) {
                      fallbackBuilds++;
                      return const Icon(Icons.music_note_rounded);
                    },
                  ),
                ),
              ),
            );

        await tester.pumpWidget(buildUnresolved(802));
        expect(ArtworkService.instance.debugHasListeners, isTrue);
        expect(fallbackBuilds, 1);

        // Unrelated notification should not trigger a fallback rebuild.
        ArtworkService.instance.evictSongs([99999]);
        await tester.pump();
        expect(fallbackBuilds, 1);
        expect(ArtworkService.instance.debugHasListeners, isTrue);

        // Once cover appears and service notifies, widget updates and detaches.
        await tester.runAsync(() async {
          await File(p.join(coversDir.path, '802.jpg')).writeAsBytes([4, 5, 6]);
          ArtworkService.instance.reset();
          await ArtworkService.instance.initialize(baseDir: artworkDir, songDao: songDao);
        });
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(ArtworkService.instance.debugHasListeners, isFalse);

        // 3. Unmounting an unresolved widget also detaches its listener.
        await tester.pumpWidget(buildUnresolved(803));
        expect(ArtworkService.instance.debugHasListeners, isTrue);
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        expect(ArtworkService.instance.debugHasListeners, isFalse);
      },
    );
  });

  group('LibraryArtistTile Styling Tests', () {
    testWidgets('renders artist name and circular avatar', (tester) async {
      const artist = ArtistDiscoveryItem(
        name: 'Daft Punk',
        songCount: 25,
        albumCount: 4,
        representativeSongId: 101,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LibraryArtistTile(artist: artist),
          ),
        ),
      );

      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
    });
  });

  group('LibraryScreen Integration & View Switching Tests', () {
    testWidgets('defaults to Albums grid, and switches views on pill tap', (tester) async {
      const album = AlbumDiscoveryItem(
        name: 'Discovery',
        artist: 'Daft Punk',
        representativeSongId: 101,
        songCount: 14,
        totalDuration: 3600000,
      );
      const artist = ArtistDiscoveryItem(
        name: 'Daft Punk',
        songCount: 14,
        albumCount: 1,
        representativeSongId: 101,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(
            showBottomNav: false,
            initialAlbums: [album],
            initialArtists: [artist],
            initialSongs: [],
            initialPlaylists: [],
          ),
        ),
      );
      await tester.pump();

      // 1. By default, Albums grid is visible, album icon is filled
      expect(find.byType(LibraryAlbumsGrid), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.byType(LibraryArtistsList), findsNothing);
      expect(find.byType(LibraryPlaylistsPlaceholder), findsNothing);
      expect(find.byKey(const ValueKey('albums_filled')), findsOneWidget);
      expect(find.byKey(const ValueKey('artists_outline')), findsOneWidget);

      // 2. Switch to Artists
      await tester.tap(find.byKey(const ValueKey('library_category_artists')));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryAlbumsGrid), findsNothing);
      expect(find.byType(LibraryArtistsList), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.byKey(const ValueKey('artists_filled')), findsOneWidget);
      expect(find.byKey(const ValueKey('albums_outline')), findsOneWidget);

      // 3. Switch to Playlists
      await tester.tap(find.byKey(const ValueKey('library_category_playlists')));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryArtistsList), findsNothing);
      expect(find.byType(LibraryPlaylistsPlaceholder), findsOneWidget);
      expect(find.text('NO PLAYLISTS YET'), findsOneWidget);
      expect(find.byKey(const ValueKey('playlists_filled')), findsOneWidget);
    });

    testWidgets('allows swiping left and right horizontally to switch between Albums, Artists, and Playlists', (tester) async {
      const album = AlbumDiscoveryItem(
        name: 'Discovery',
        artist: 'Daft Punk',
        representativeSongId: 101,
        songCount: 14,
        totalDuration: 3600000,
      );
      const artist = ArtistDiscoveryItem(
        name: 'Daft Punk',
        songCount: 14,
        albumCount: 1,
        representativeSongId: 101,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(
            showBottomNav: false,
            initialAlbums: [album],
            initialArtists: [artist],
            initialSongs: [],
            initialPlaylists: [],
          ),
        ),
      );
      await tester.pump();

      // Starts on Albums
      expect(find.byType(LibraryAlbumsGrid), findsOneWidget);
      expect(find.byType(LibraryArtistsList), findsNothing);

      // Swipe left (drag leftwards with finger) -> moves forward to Artists
      await tester.fling(find.byType(LibraryTransitionControl), const Offset(-500.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryAlbumsGrid), findsNothing);
      expect(find.byType(LibraryArtistsList), findsOneWidget);

      // Swipe left again -> moves to Songs
      await tester.fling(find.byType(LibraryTransitionControl), const Offset(-500.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryArtistsList), findsNothing);
      expect(find.byType(LibrarySongsList), findsOneWidget);

      // Swipe left again -> moves to Playlists
      await tester.fling(find.byType(LibraryTransitionControl), const Offset(-500.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySongsList), findsNothing);
      expect(find.byType(LibraryPlaylistsPlaceholder), findsOneWidget);

      // Swipe right -> moves backward to Songs
      await tester.fling(find.byType(LibraryTransitionControl), const Offset(500.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySongsList), findsOneWidget);
      expect(find.byType(LibraryPlaylistsPlaceholder), findsNothing);

      // Swipe right again -> moves backward to Artists
      await tester.fling(find.byType(LibraryTransitionControl), const Offset(500.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryArtistsList), findsOneWidget);
      expect(find.byType(LibrarySongsList), findsNothing);

      // Swipe right again -> moves backward to Albums
      await tester.fling(find.byType(LibraryTransitionControl), const Offset(500.0, 0.0), 1000.0);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryAlbumsGrid), findsOneWidget);
      expect(find.byType(LibraryArtistsList), findsNothing);
    });
  });

  group('LibraryTransitionController Unit Tests', () {
    test('initializes with default values and responds to directional transitions', () {
      final controller = LibraryTransitionController();

      expect(controller.currentFilter, LibraryFilter.albums);
      expect(controller.previousFilter, LibraryFilter.albums);
      expect(controller.currentIndex, 0);
      expect(controller.isForward, isTrue);
      expect(controller.isAnimating, isFalse);

      // Animate to Artists (forward)
      controller.animateTo(LibraryFilter.artists);
      expect(controller.currentFilter, LibraryFilter.artists);
      expect(controller.previousFilter, LibraryFilter.albums);
      expect(controller.direction, LibraryTransitionDirection.forward);
      expect(controller.isAnimating, isTrue);

      controller.notifyAnimationFinished();
      expect(controller.isAnimating, isFalse);

      // Animate next to Songs
      final nextToSongs = controller.animateToNext();
      expect(nextToSongs, isTrue);
      expect(controller.currentFilter, LibraryFilter.songs);
      expect(controller.direction, LibraryTransitionDirection.forward);

      // Animate next to Playlists
      final nextSuccess = controller.animateToNext();
      expect(nextSuccess, isTrue);
      expect(controller.currentFilter, LibraryFilter.playlists);
      expect(controller.direction, LibraryTransitionDirection.forward);

      // Attempting to animate past Playlists returns false
      expect(controller.animateToNext(), isFalse);

      // Animate previous back to Songs
      final prevSuccess = controller.animateToPrevious();
      expect(prevSuccess, isTrue);
      expect(controller.currentFilter, LibraryFilter.songs);
      expect(controller.direction, LibraryTransitionDirection.backward);

      // Reset
      controller.reset();
      expect(controller.currentFilter, LibraryFilter.albums);
      expect(controller.direction, LibraryTransitionDirection.forward);

      controller.dispose();
    });
  });

  group('LibraryCategoryBar Widget Tests', () {
    testWidgets('renders chevrons, album, enlarged artist, and playlist icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryBar(
              selectedFilter: LibraryFilter.albums,
              onFilterChanged: (_) {},
            ),
          ),
        ),
      );

      // Verify chevrons exist
      expect(find.byKey(const ValueKey('library_nav_previous')), findsOneWidget);
      expect(find.byKey(const ValueKey('library_nav_next')), findsOneWidget);

      // Verify category buttons exist
      expect(find.byKey(const ValueKey('library_category_albums')), findsOneWidget);
      expect(find.byKey(const ValueKey('library_category_artists')), findsOneWidget);
      expect(find.byKey(const ValueKey('library_category_playlists')), findsOneWidget);

      // Verify active album is filled and artist is outline
      expect(find.byKey(const ValueKey('albums_filled')), findsOneWidget);
      expect(find.byKey(const ValueKey('artists_outline')), findsOneWidget);
      expect(find.byKey(const ValueKey('playlists_outline')), findsOneWidget);

      // Verify artist icon is larger (32dp vs 26dp)
      final artistIcon = tester.widget<Icon>(find.byKey(const ValueKey('artists_outline')));
      final albumIcon = tester.widget<Icon>(find.byKey(const ValueKey('albums_filled')));
      expect(artistIcon.size, 32.0);
      expect(albumIcon.size, 26.0);
      expect(artistIcon.size!, greaterThan(albumIcon.size!));
    });

    testWidgets('taps on chevrons and category buttons fire correct callbacks', (tester) async {
      LibraryFilter? selected;
      bool prevTapped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryCategoryBar(
              selectedFilter: LibraryFilter.albums,
              onFilterChanged: (f) => selected = f,
              onPrevious: () => prevTapped = true,
              onNext: () => nextTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('library_nav_previous')));
      expect(prevTapped, isTrue);

      await tester.tap(find.byKey(const ValueKey('library_nav_next')));
      expect(nextTapped, isTrue);

      await tester.tap(find.byKey(const ValueKey('library_category_artists')));
      expect(selected, LibraryFilter.artists);

      await tester.tap(find.byKey(const ValueKey('library_category_playlists')));
      expect(selected, LibraryFilter.playlists);
    });
  });
}
