import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/artist/components/artist_compact_track_tile.dart';
import 'package:project_anima/features/artist/components/artist_discography_section.dart';
import 'package:project_anima/features/artist/components/artist_header_view.dart';
import 'package:project_anima/features/artist/components/artist_photo_options_sheet.dart';
import 'package:project_anima/features/artist/components/artist_top_track_tile.dart';
import 'package:project_anima/features/artist/screens/artist_detail_screen.dart';
import 'package:project_anima/features/artist_discography/controls/artist_discography_controller.dart';
import 'package:project_anima/features/artist_discography/screens/artist_discography_screen.dart';
import 'package:project_anima/features/artist_tracks/controls/artist_tracks_controller.dart';
import 'package:project_anima/features/artist_tracks/screens/artist_tracks_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeDiscographyController extends ArtistDiscographyController {
  final List<AlbumDiscoveryItem> fakeAlbums;
  _FakeDiscographyController(this.fakeAlbums) : super(artistName: 'Pink Floyd');

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
  _FakeTracksController(this.fakeSongs) : super(artistName: 'Pink Floyd');

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
    tempDir = await Directory.systemTemp.createTemp('anima_metro_test_');
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

  group('Metro Artist Profile Design Tests', () {
    testWidgets('ArtistDetailScreen renders AmbientParticlesCanvas in background', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArtistDetailScreen(
                artistName: 'Pink Floyd',
                songDao: songDao,
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 300));
      });

      await tester.pump();

      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
    });

    testWidgets('ArtistHeaderView renders sharp square Metro portrait with zero border radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistHeaderView(
              artistName: 'Pink Floyd',
              onEditTap: () {},
            ),
          ),
        ),
      );

      // Verify artist name is displayed
      final titleFinder = find.text('Pink Floyd');
      expect(titleFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.fontFamily, contains('Segoe UI'));

      // Check edit button icon exists and has sharp 0 radius
      final editIconFinder = find.byIcon(Icons.edit_rounded);
      expect(editIconFinder, findsOneWidget);

      final inkWellFinder = find.ancestor(of: editIconFinder, matching: find.byType(InkWell));
      expect(inkWellFinder, findsOneWidget);
      final inkWell = tester.widget<InkWell>(inkWellFinder);
      expect(inkWell.borderRadius, BorderRadius.zero);
    });

    testWidgets('ArtistTopTrackTile renders sharp corners and Segoe UI fonts', (tester) async {
      final song = Song(
        mediaStoreId: 101,
        title: 'Time',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        duration: 425000,
        path: '/storage/time.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistTopTrackTile(
              song: song,
              allArtistSongs: [song],
            ),
          ),
        ),
      );

      expect(find.text('Time'), findsOneWidget);
      expect(find.text('The Dark Side of the Moon'), findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(ArtistTopTrackTile), matching: find.byType(Material)).first,
      );
      expect(material.borderRadius, BorderRadius.zero);
    });

    testWidgets('ArtistDiscographySection renders album cards with zero border radius and flat elevation', (tester) async {
      const albums = [
        AlbumDiscoveryItem(
          name: 'The Dark Side of the Moon',
          artist: 'Pink Floyd',
          representativeSongId: 101,
          songCount: 10,
          totalDuration: 2570000,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistDiscographySection(albums: albums),
          ),
        ),
      );

      expect(find.text('The Dark Side of the Moon'), findsOneWidget);

      // Verify container with album artwork has flat elevation (no drop shadow)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final albumArtContainers = containers.where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.borderRadius == BorderRadius.zero && dec.boxShadow == null;
      });
      expect(albumArtContainers.isNotEmpty, isTrue);
    });

    testWidgets('ArtistCompactTrackTile renders sharp zero border radius', (tester) async {
      final song = Song(
        mediaStoreId: 102,
        title: 'Money',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        duration: 382000,
        path: '/storage/money.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistCompactTrackTile(
              song: song,
              allArtistSongs: [song],
            ),
          ),
        ),
      );

      expect(find.text('Money'), findsOneWidget);
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: find.byType(ArtistCompactTrackTile), matching: find.byType(InkWell)).first,
      );
      expect(inkWell.borderRadius, BorderRadius.zero);
    });

    testWidgets('ArtistPhotoOptionsSheet renders with Material accent border and Segoe UI fonts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistPhotoOptionsSheet(
              onChangePhoto: () {},
              onRemovePhoto: () {},
            ),
          ),
        ),
      );

      expect(find.text('Change artist photo'), findsOneWidget);
      expect(find.text('Remove custom photo'), findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(ArtistPhotoOptionsSheet), matching: find.byType(Material)).first,
      );
      expect(material.color, AppColors.bottomNavBackground);
      expect(material.shape, isA<Border>());
    });

    testWidgets('ArtistDiscographyScreen and ArtistTracksScreen mount AmbientParticlesCanvas', (tester) async {
      final fakeAlbum = const AlbumDiscoveryItem(
        name: 'The Dark Side of the Moon',
        artist: 'Pink Floyd',
        representativeSongId: 101,
        songCount: 10,
        totalDuration: 2570000,
      );
      final fakeSong = Song(
        mediaStoreId: 101,
        title: 'Time',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        duration: 425000,
        path: '/storage/time.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistDiscographyScreen(
              artistName: 'Pink Floyd',
              controller: _FakeDiscographyController([fakeAlbum]),
              animateBounce: false,
              showMiniPlayer: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistTracksScreen(
              artistName: 'Pink Floyd',
              controller: _FakeTracksController([fakeSong]),
              animateBounce: false,
              showMiniPlayer: false,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
    });
  });
}
