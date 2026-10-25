import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/playlists/library_playlist_tile.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_view.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/features/library/screens/library.dart';
import 'package:project_anima/features/playlist/components/playlist_cover_picker.dart';
import 'package:project_anima/features/playlist/components/playlist_detail_header.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_track_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';
import 'package:project_anima/features/playlist/screens/playlist_edit_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeSongDao extends Fake implements SongDao {
  final List<Song> songs;
  FakeSongDao(this.songs);

  @override
  Future<List<Song>> getAllSongs() async => songs;

  @override
  Future<List<ArtistDiscoveryItem>> getAllUniqueArtists({int limit = 1000}) async => [];

  @override
  Future<List<AlbumDiscoveryItem>> getAllUniqueAlbums({int limit = 1000}) async => [];

  @override
  Future<List<Song>> searchSongs(String query, {int limit = 20, int offset = 0}) async {
    final q = query.trim().toLowerCase();
    return songs.where((s) => s.title.toLowerCase().contains(q)).toList();
  }
}

class FakePlaylistDao extends Fake implements PlaylistDao {
  Playlist? lastCreated;
  final List<Song> playlistSongs;

  FakePlaylistDao({this.playlistSongs = const []});

  @override
  Future<Playlist> createPlaylist(
    String name, {
    String? coverPath,
    String? fontFamily,
    List<Song>? songs,
  }) async {
    lastCreated = Playlist(
      id: 99,
      name: name,
      coverPath: coverPath,
      fontFamily: fontFamily,
      songCount: songs?.length ?? 0,
      totalDuration: 230000,
      createdAt: 1000,
      updatedAt: 1000,
    );
    return lastCreated!;
  }

  @override
  Future<Playlist?> getPlaylistById(int id) async {
    return lastCreated ??
        Playlist(
          id: id,
          name: 'Road Trip',
          songCount: playlistSongs.length,
          totalDuration: 460000,
          createdAt: 100,
          updatedAt: 100,
        );
  }

  @override
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    return playlistSongs;
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return lastCreated != null ? [lastCreated!] : [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late PlaylistDao playlistDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_playlist_test_');
    final dbPath = p.join(tempDir.path, 'test_anima_playlist.db');

    appDatabase = AppDatabase.instance;
    await appDatabase.initDatabase(customPath: dbPath);
    playlistDao = PlaylistDao(appDatabase: appDatabase);
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PlaylistDao Database & CRUD Tests', () {
    test('createPlaylist inserts playlist and songs with accurate aggregates', () async {
      final s1 = Song(
        mediaStoreId: 101,
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        duration: 240000,
        path: '/storage/m83.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 102,
        title: 'Reunion',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        duration: 220000,
        path: '/storage/reunion.mp3',
        dateModified: 100,
      );

      final db = await appDatabase.database;
      await db.insert('songs', s1.toMap());
      await db.insert('songs', s2.toMap());

      final created = await playlistDao.createPlaylist(
        'Synthwave Vibes',
        songs: [s1, s2],
      );

      expect(created.id, isNotNull);
      expect(created.name, 'Synthwave Vibes');
      expect(created.songCount, 2);
      expect(created.totalDuration, 460000);
      expect(created.firstMediaStoreId, 101);

      // Verify getPlaylists relational aggregation
      final all = await playlistDao.getPlaylists();
      expect(all.length, 1);
      expect(all.first.name, 'Synthwave Vibes');
      expect(all.first.songCount, 2);
      expect(all.first.totalDuration, 460000);
      expect(all.first.firstMediaStoreId, 101);

      // Verify getPlaylistSongs ordered sequence
      final songs = await playlistDao.getPlaylistSongs(created.id!);
      expect(songs.length, 2);
      expect(songs[0].mediaStoreId, 101);
      expect(songs[1].mediaStoreId, 102);
    });

    test('updatePlaylist updates name, cover, and reorders songs', () async {
      final s1 = Song(
        mediaStoreId: 201,
        title: 'Song A',
        artist: 'Artist A',
        duration: 100000,
        path: '/a.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 202,
        title: 'Song B',
        artist: 'Artist B',
        duration: 150000,
        path: '/b.mp3',
        dateModified: 100,
      );

      final db = await appDatabase.database;
      await db.insert('songs', s1.toMap());
      await db.insert('songs', s2.toMap());
      final p1 = await playlistDao.createPlaylist('Old Title', songs: [s1, s2]);

      // Reorder songs [s2, s1] and update title
      await playlistDao.updatePlaylist(
        p1.id!,
        name: 'New Title',
        coverPath: '/custom/cover.jpg',
        songs: [s2, s1],
      );

      final updated = await playlistDao.getPlaylistById(p1.id!);
      expect(updated, isNotNull);
      expect(updated!.name, 'New Title');
      expect(updated.coverPath, '/custom/cover.jpg');
      expect(updated.songCount, 2);
      expect(updated.firstMediaStoreId, 202);

      final songs = await playlistDao.getPlaylistSongs(p1.id!);
      expect(songs[0].mediaStoreId, 202);
      expect(songs[1].mediaStoreId, 201);

      // Delete playlist
      await playlistDao.deletePlaylist(p1.id!);
      final remaining = await playlistDao.getPlaylists();
      expect(remaining.isEmpty, isTrue);
    });

    test('createPlaylist and updatePlaylist persist and update fontFamily', () async {
      final created = await playlistDao.createPlaylist(
        'Cinematic Soundtracks',
        fontFamily: 'Cinzel',
      );
      expect(created.fontFamily, 'Cinzel');

      final fetched = await playlistDao.getPlaylistById(created.id!);
      expect(fetched?.fontFamily, 'Cinzel');

      await playlistDao.updatePlaylist(
        created.id!,
        fontFamily: 'Playfair Display',
      );
      final updated = await playlistDao.getPlaylistById(created.id!);
      expect(updated?.fontFamily, 'Playfair Display');
    });
  });

  group('Playlist Dialogs and Component Styling Tests', () {
    testWidgets('LibraryPlaylistCard renders hero banner with custom font and play trigger', (tester) async {
      bool playTapped = false;
      bool cardTapped = false;

      const p = Playlist(
        id: 77,
        name: 'Cyberpunk Odyssey',
        fontFamily: 'Space Grotesk',
        songCount: 8,
        totalDuration: 1800000,
        createdAt: 100,
        updatedAt: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: LibraryPlaylistCard(
                  playlist: p,
                  onTap: () => cardTapped = true,
                  onPlayTap: () => playTapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Cyberpunk Odyssey'), findsOneWidget);
      expect(find.text('8 songs • 30 min'), findsNothing);
      expect(find.byKey(const ValueKey('library_playlist_play_77')), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);

      // Verify rounded styling (ClipRRect used)
      expect(find.byType(ClipRRect), findsWidgets);

      final aspectRatioFinder = find.byWidgetPredicate(
        (w) => w is AspectRatio && (w.aspectRatio - (1920 / 620)).abs() < 0.01,
      );
      expect(aspectRatioFinder, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('library_playlist_play_77')));
      await tester.pump();
      expect(playTapped, isTrue);
      expect(cardTapped, isFalse);

      await tester.tap(find.text('Cyberpunk Odyssey'));
      await tester.pump();
      expect(cardTapped, isTrue);
    });

    testWidgets('LibraryPlaylistsView reactively reloads upon PlaylistDao.playlistRevision', (tester) async {
      final fakeDao = FakePlaylistDao();
      fakeDao.lastCreated = const Playlist(
        id: 1,
        name: 'Initial Name',
        createdAt: 100,
        updatedAt: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryPlaylistsView(
              playlistDao: fakeDao,
              songDao: FakeSongDao([]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial Name'), findsOneWidget);

      // Simulate editing playlist name and font in database
      fakeDao.lastCreated = const Playlist(
        id: 1,
        name: 'Updated Name Live',
        fontFamily: 'Lobster',
        createdAt: 100,
        updatedAt: 200,
      );

      // Trigger reactive revision notification
      PlaylistDao.notifyPlaylistsChanged();
      await tester.pumpAndSettle();

      // Verified: Immediately updated without app restart!
      expect(find.text('Updated Name Live'), findsOneWidget);
      expect(find.text('Initial Name'), findsNothing);
    });
    testWidgets('PlaylistDiscardDialog renders M3 Expressive confirmation dialog', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await PlaylistDiscardDialog.show(context);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Discard playlist?'), findsOneWidget);
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('PlaylistCoverPicker displays generic icon placeholder when no cover set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistCoverPicker(
              coverPath: null,
              onCoverPicked: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Symbols.queue_music_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });
  });

  group('PlaylistEditScreen Functionality Tests', () {
    testWidgets('renders generic cover, editable name, search bar, and floating Save button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistEditScreen(
            playlistDao: FakePlaylistDao(),
            songDao: FakeSongDao([]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      // Top dismiss arrow indicator
      expect(find.byType(ModalDismissIndicator), findsOneWidget);

      // Generic cover picker
      expect(find.byType(PlaylistCoverPicker), findsOneWidget);

      // Name input field
      expect(find.byType(TextField), findsNWidgets(2)); // Name + Search
      expect(find.text('What song do you want to add?'), findsOneWidget);

      // Floating Save button
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('search bar queries songs and quick add inserts into reorderable list', (tester) async {
      final s1 = Song(
        mediaStoreId: 301,
        title: 'Starboy',
        artist: 'The Weeknd',
        duration: 230000,
        path: '/starboy.mp3',
        dateModified: 100,
      );
      final fakeSongDao = FakeSongDao([s1]);
      final fakePlaylistDao = FakePlaylistDao();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  PlaylistEditScreen.route(
                    playlistDao: fakePlaylistDao,
                    songDao: fakeSongDao,
                    animateBounce: false,
                  ),
                ),
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Editor'));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.widgetWithText(TextField, 'What song do you want to add?'), 'Star');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify search result appears
      expect(find.text('Starboy'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);

      // Tap + button to add
      await tester.ensureVisible(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify song is in the playlist list and has a drag handle
      expect(find.byIcon(Icons.drag_indicator_rounded), findsOneWidget);

      // Save playlist
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakePlaylistDao.lastCreated, isNotNull);
      expect(fakePlaylistDao.lastCreated!.songCount, 1);
    });

    testWidgets('PlaylistEditScreen allows selecting a custom typography font for playlist title', (tester) async {
      final fakePlaylistDao = FakePlaylistDao();

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistEditScreen(
            playlistDao: fakePlaylistDao,
            songDao: FakeSongDao([]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TYPOGRAPHY'), findsOneWidget);
      expect(find.text('Cinzel'), findsOneWidget);
      expect(find.text('Outfit'), findsOneWidget);

      // Tap on 'Cinzel' font chip
      await tester.tap(find.text('Cinzel'));
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(find.widgetWithText(TextField, 'Playlist Name'), 'Roman Epic');
      await tester.pump();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fakePlaylistDao.lastCreated, isNotNull);
      expect(fakePlaylistDao.lastCreated!.name, 'Roman Epic');
      expect(fakePlaylistDao.lastCreated!.fontFamily, 'Cinzel');
    });
  });

  group('LibraryScreen Integration & Dynamic FAB Tests', () {
    testWidgets('shows floating create playlist button ONLY in Playlists tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LibraryScreen(
            showBottomNav: true,
            initialFilter: LibraryFilter.albums,
            initialAlbums: const [],
            initialArtists: const [],
            initialPlaylists: const [],
            playlistDao: FakePlaylistDao(),
            songDao: FakeSongDao([]),
          ),
        ),
      );
      await tester.pump();

      // Albums tab active: FAB should NOT be present
      expect(find.byKey(const ValueKey('library_create_playlist_fab')), findsNothing);

      // Switch to Artists: FAB should NOT be present
      await tester.tap(find.text('Artists'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_create_playlist_fab')), findsNothing);

      // Switch to Playlists: FAB MUST be present above nav
      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_create_playlist_fab')), findsOneWidget);

      // Switch back to Albums: FAB must disappear
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_create_playlist_fab')), findsNothing);
    });

    testWidgets('LibraryPlaylistsView displays 2-per-row grid of playlists and taps open PlaylistDetailScreen', (tester) async {
      const p1 = Playlist(
        id: 1,
        name: 'Road Trip',
        songCount: 5,
        totalDuration: 1200000,
        createdAt: 100,
        updatedAt: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LibraryScreen(
            showBottomNav: false,
            initialFilter: LibraryFilter.playlists,
            initialAlbums: const [],
            initialArtists: const [],
            initialPlaylists: const [p1],
            playlistDao: FakePlaylistDao(),
            songDao: FakeSongDao([]),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Road Trip'), findsOneWidget);
      expect(find.text('5 songs • 20 min'), findsNothing);
      expect(find.byKey(const ValueKey('library_playlists_grid')), findsOneWidget);
      expect(find.byType(LibraryPlaylistTile), findsOneWidget);

      // Tap on playlist card should open PlaylistDetailScreen
      await tester.tap(find.text('Road Trip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('playlist_detail_shuffle_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('playlist_detail_play_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('playlist_detail_edit_button')), findsOneWidget);
    });
  });

  group('PlaylistDetailScreen Layout & Controls Tests', () {
    testWidgets('renders unrounded square artwork, left Shuffle, center metadata, right Play, and Edit button', (tester) async {
      const playlist = Playlist(
        id: 42,
        name: 'Chill Vibes',
        songCount: 2,
        totalDuration: 300000,
        createdAt: 100,
        updatedAt: 100,
      );

      final s1 = Song(
        mediaStoreId: 501,
        title: 'Song One',
        artist: 'Artist One',
        duration: 150000,
        path: '/one.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 502,
        title: 'Song Two',
        artist: 'Artist Two',
        duration: 150000,
        path: '/two.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistDetailScreen(
            playlist: playlist,
            initialSongs: [s1, s2],
            playlistDao: FakePlaylistDao(playlistSongs: [s1, s2]),
            songDao: FakeSongDao([s1, s2]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      // Top dismiss indicator
      expect(find.byType(ModalDismissIndicator), findsOneWidget);

      // Header component
      expect(find.byType(PlaylistDetailHeader), findsOneWidget);

      // Left Shuffle button
      expect(find.byKey(const ValueKey('playlist_detail_shuffle_button')), findsOneWidget);

      // Center title and metadata
      expect(find.text('Chill Vibes'), findsOneWidget);
      expect(find.text('2 songs • 5 mins'), findsOneWidget);

      // Right Play button
      expect(find.byKey(const ValueKey('playlist_detail_play_button')), findsOneWidget);

      // Edit Playlist button
      expect(find.byKey(const ValueKey('playlist_detail_edit_button')), findsOneWidget);

      // Tracks section with sequential indices
      expect(find.text('TRACKS'), findsOneWidget);
      expect(find.byType(PlaylistTrackTile), findsNWidgets(2));
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Song Two'), findsOneWidget);
    });
  });

  group('PlaylistEditScreen Dictionary Search Tests', () {
    testWidgets('uses typo-tolerant dictionary search to find songs by artist or typo', (tester) async {
      final s1 = Song(
        mediaStoreId: 601,
        title: 'Midnight City',
        artist: 'M83',
        duration: 240000,
        path: '/m83.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 602,
        title: 'Starboy',
        artist: 'The Weeknd',
        duration: 230000,
        path: '/starboy.mp3',
        dateModified: 100,
      );

      final fakeSongDao = FakeSongDao([s1, s2]);

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistEditScreen(
            playlistDao: FakePlaylistDao(),
            songDao: fakeSongDao,
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      // Type slightly misspelled query "Strby" (fuzzy match for Starboy)
      await tester.enterText(find.widgetWithText(TextField, 'What song do you want to add?'), 'Strby');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should match Starboy via FuzzySearchEngine
      expect(find.text('Starboy'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);

      // Clear search
      await tester.ensureVisible(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      // Search by artist "M83"
      await tester.enterText(find.widgetWithText(TextField, 'What song do you want to add?'), 'M83');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should match Midnight City
      expect(find.text('Midnight City'), findsOneWidget);
    });
  });
}
