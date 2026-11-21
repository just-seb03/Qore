import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/playlists/library_playlist_tile.dart';
import 'package:project_anima/features/library/components/playlists/library_playlists_view.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/search/fuzzy_search_engine.dart';
import 'package:project_anima/features/library/screens/library.dart';
import 'package:project_anima/features/playlist/components/playlist_cover_picker.dart';
import 'package:project_anima/features/playlist/components/playlist_detail_header.dart';
import 'package:project_anima/features/playlist/components/playlist_discard_dialog.dart';
import 'package:project_anima/features/playlist/components/playlist_text_banner.dart';
import 'package:project_anima/features/playlist/components/playlist_track_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';
import 'package:project_anima/features/playlist/screens/playlist_edit_screen.dart';
import 'package:project_anima/core/artwork/widgets/anima_artwork_image.dart';
import 'package:project_anima/features/playlist/components/playlist_delete_dialog.dart';
import 'package:project_anima/features/playlist/screens/playlist_tracks_edit_screen.dart';
import 'package:project_anima/features/player/components/player_metadata_view.dart';
import 'package:project_anima/features/player/components/song_context_sheet.dart';
import 'package:project_anima/features/player/components/song_delete_dialog.dart';
import 'package:project_anima/features/player/components/song_playlist_picker_sheet.dart';
import 'package:project_anima/components/song_options_pill.dart';
import 'package:project_anima/features/player/components/playback_queue_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeSongDao extends Fake implements SongDao {
  final List<Song> songs;
  bool songDeleted = false;
  FakeSongDao(this.songs);

  @override
  Future<List<Song>> getAllSongs() async => songs;

  @override
  Future<List<SongArtworkMeta>> getSongArtworkMetadata() async => songs
      .map((s) => SongArtworkMeta(
            mediaStoreId: s.mediaStoreId,
            albumId: s.albumId,
            album: s.album,
            artist: s.artist,
            albumArtist: s.albumArtist,
            path: s.path,
          ))
      .toList();

  @override
  Future<List<Song>> getSearchDictionarySongs() async => songs;

  @override
  Future<List<ArtistDiscoveryItem>> getAllUniqueArtists({int limit = 1000}) async => [];

  @override
  Future<List<AlbumDiscoveryItem>> getAllUniqueAlbums({int limit = 1000}) async => [];

  @override
  Future<List<Song>> searchSongs(String query, {int limit = 20, int offset = 0}) async {
    final q = query.trim().toLowerCase();
    return songs.where((s) => s.title.toLowerCase().contains(q)).toList();
  }

  @override
  Future<void> deleteSong(int mediaStoreId) async {
    songDeleted = true;
    songs.removeWhere((s) => s.mediaStoreId == mediaStoreId);
  }
}

class FakePlaylistDao extends Fake implements PlaylistDao {
  Playlist? lastCreated;
  List<Song> playlistSongs;
  final Set<int> songsInPlaylist = <int>{};

  FakePlaylistDao({List<Song> playlistSongs = const []})
      : playlistSongs = List.of(playlistSongs);

  @override
  Future<Playlist> createPlaylist(
    String name, {
    String? coverPath,
    String? fontFamily,
    double textAlignX = 0.0,
    double textAlignY = 0.0,
    int textColor = 0xFFFFFFFF,
    int? textGradientColor,
    double fontSize = 26.0,
    String textEffect = 'none',
    List<Song>? songs,
  }) async {
    lastCreated = Playlist(
      id: 99,
      name: name,
      coverPath: coverPath,
      fontFamily: fontFamily,
      textAlignX: textAlignX,
      textAlignY: textAlignY,
      textColor: textColor,
      textGradientColor: textGradientColor,
      fontSize: fontSize,
      textEffect: textEffect,
      songCount: songs?.length ?? 0,
      totalDuration: 230000,
      createdAt: 1000,
      updatedAt: 1000,
    );
    return lastCreated!;
  }

  @override
  Future<void> updatePlaylist(
    int playlistId, {
    String? name,
    String? coverPath,
    String? fontFamily,
    double? textAlignX,
    double? textAlignY,
    int? textColor,
    int? textGradientColor,
    double? fontSize,
    String? textEffect,
    bool clearGradient = false,
    List<Song>? songs,
  }) async {
    if (songs != null) {
      playlistSongs = List.of(songs);
    }
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

  bool wasDeleted = false;

  @override
  Future<void> deletePlaylist(int playlistId) async {
    wasDeleted = true;
    lastCreated = null;
    PlaylistDao.notifyPlaylistsChanged();
  }

  @override
  Future<List<int>> getPlaylistIdsContainingSong(int mediaStoreId) async {
    return songsInPlaylist.contains(mediaStoreId) && lastCreated?.id != null
        ? [lastCreated!.id!]
        : [];
  }

  @override
  Future<void> addSongToPlaylist(int playlistId, Song song) async {
    songsInPlaylist.add(song.mediaStoreId);
    if (!playlistSongs.any((s) => s.mediaStoreId == song.mediaStoreId)) {
      playlistSongs.add(song);
    }
    PlaylistDao.notifyPlaylistsChanged();
  }

  @override
  Future<void> removeSongFromPlaylist(int playlistId, int mediaStoreId) async {
    songsInPlaylist.remove(mediaStoreId);
    playlistSongs.removeWhere((s) => s.mediaStoreId == mediaStoreId);
    PlaylistDao.notifyPlaylistsChanged();
  }

  @override
  Future<bool> isSongInPlaylist(int playlistId, int mediaStoreId) async {
    return songsInPlaylist.contains(mediaStoreId);
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

    test('createPlaylist and updatePlaylist persist and retrieve custom typography alignment, colors, fontSize and notifies pinnedFavorites', () async {
      int pinnedRevisionNotified = 0;
      void listener() => pinnedRevisionNotified++;
      PinnedFavoritesDao.revision.addListener(listener);

      final created = await playlistDao.createPlaylist(
        'Vaporwave Sunset',
        fontFamily: 'Splash',
        textAlignX: -0.75,
        textAlignY: 0.65,
        textColor: 0xFFFF0055,
        textGradientColor: 0xFF00E5FF,
        fontSize: 32.0,
        textEffect: 'neon',
      );

      final fetched = await playlistDao.getPlaylistById(created.id!);
      expect(fetched?.name, 'Vaporwave Sunset');
      expect(fetched?.fontFamily, 'Splash');
      expect(fetched?.textAlignX, -0.75);
      expect(fetched?.textAlignY, 0.65);
      expect(fetched?.textColor, 0xFFFF0055);
      expect(fetched?.textGradientColor, 0xFF00E5FF);
      expect(fetched?.fontSize, 32.0);
      expect(fetched?.textEffect, 'neon');

      final all = await playlistDao.getPlaylists();
      final itemInAll = all.firstWhere((p) => p.id == created.id);
      expect(itemInAll.textAlignX, -0.75);
      expect(itemInAll.textAlignY, 0.65);
      expect(itemInAll.textColor, 0xFFFF0055);
      expect(itemInAll.textGradientColor, 0xFF00E5FF);
      expect(itemInAll.fontSize, 32.0);
      expect(itemInAll.textEffect, 'neon');

      await playlistDao.updatePlaylist(
        created.id!,
        textAlignX: 0.85,
        textAlignY: -0.85,
        textColor: 0xFFFFFF00,
        fontSize: 28.0,
        textEffect: 'glitch',
      );

      final updated = await playlistDao.getPlaylistById(created.id!);
      expect(updated?.textAlignX, 0.85);
      expect(updated?.textAlignY, -0.85);
      expect(updated?.textColor, 0xFFFFFF00);
      expect(updated?.fontSize, 28.0);
      expect(updated?.textEffect, 'glitch');
      expect(pinnedRevisionNotified, greaterThan(0));

      PinnedFavoritesDao.revision.removeListener(listener);
    });
  });

  group('Playlist Dialogs and Component Styling Tests', () {
    testWidgets('LibraryPlaylistCard renders hero banner with custom font and play trigger', (tester) async {
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
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Cyberpunk Odyssey'), findsOneWidget);
      expect(find.text('8 songs • 30 min'), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

      // Verify unrounded 2:1 styling matching Space
      final aspectRatioFinder = find.byWidgetPredicate(
        (w) => w is AspectRatio && (w.aspectRatio - 2.0).abs() < 0.01,
      );
      expect(aspectRatioFinder, findsWidgets);

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
    testWidgets('renders 2:1 Metro banner, name input, song search input, and Save button', (tester) async {
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

      // 2:1 Metro cover banner
      expect(find.byType(PlaylistTextBanner), findsOneWidget);

      // Name input and integrated song search input
      expect(find.byKey(const ValueKey('playlist_name_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('playlist_edit_song_search')), findsOneWidget);

      // Save button
      expect(find.byKey(const ValueKey('playlist_edit_save_button')), findsOneWidget);

      // Obsolete typography/effect/gradient controls should not exist
      expect(find.text('TYPOGRAPHY'), findsNothing);
      expect(find.text('EFECTOS DE TEXTO'), findsNothing);
      expect(find.text('GRADIENTE'), findsNothing);
    });

    testWidgets('search bar filters songs and toggling rows saves selected songs', (tester) async {
      final s1 = Song(
        mediaStoreId: 301,
        title: 'Starboy',
        artist: 'The Weeknd',
        duration: 230000,
        path: '/starboy.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 302,
        title: 'Midnight City',
        artist: 'M83',
        duration: 243000,
        path: '/midnight.mp3',
        dateModified: 101,
      );
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeSongDao = FakeSongDao([s1, s2]);
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

      // Enter playlist name
      await tester.enterText(
        find.byKey(const ValueKey('playlist_name_input')),
        'Cyber Sunset',
      );
      await tester.pump();

      // Library songs are not dumped upfront before searching
      expect(find.byKey(const ValueKey('playlist_pick_row_301')), findsNothing);
      expect(find.byKey(const ValueKey('playlist_pick_row_302')), findsNothing);

      // Filter songs via AppSearchBar
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('playlist_edit_song_search')),
          matching: find.byType(TextField),
        ),
        'Starboy',
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('playlist_pick_row_301')), findsOneWidget);
      expect(find.byKey(const ValueKey('playlist_pick_row_302')), findsNothing);

      // Toggle song 301 into playlist
      await tester.tap(find.byKey(const ValueKey('playlist_pick_row_301')));
      await tester.pump();

      // Save playlist
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('playlist_edit_save_button')));
      await tester.pumpAndSettle();

      expect(fakePlaylistDao.lastCreated, isNotNull);
      expect(fakePlaylistDao.lastCreated!.name, 'Cyber Sunset');
      expect(fakePlaylistDao.lastCreated!.songCount, 1);
    });

    testWidgets('editing playlist with custom cover shows remove cover action', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final existing = Playlist(
        id: 12,
        name: 'Night Drive',
        coverPath: '/tmp/nonexistent_cover.jpg',
        songCount: 0,
        totalDuration: 0,
        createdAt: 100,
        updatedAt: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistEditScreen(
            initialPlaylist: existing,
            playlistDao: FakePlaylistDao(),
            songDao: FakeSongDao([]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsNothing);
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
      await tester.tap(find.byKey(const ValueKey('library_category_artists')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_create_playlist_fab')), findsNothing);

      // Switch to Playlists: FAB MUST be present above nav
      await tester.tap(find.byKey(const ValueKey('library_category_playlists')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('library_create_playlist_fab')), findsOneWidget);

      // Switch back to Albums: FAB must disappear
      await tester.tap(find.byKey(const ValueKey('library_category_albums')));
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

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Tracks section with sequential indices and covers on the left
      expect(find.text('TRACKS'), findsOneWidget);
      expect(find.byType(PlaylistTrackTile), findsNWidgets(2));
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('Song One'), findsOneWidget);
      expect(find.text('Song Two'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlaylistTrackTile),
          matching: find.byType(AnimaArtworkImage),
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('tapping hero banner in PlaylistDetailScreen triggers PlaylistEditScreen navigation', (tester) async {
      const playlist = Playlist(
        id: 42,
        name: 'Chill Vibes',
        songCount: 1,
        totalDuration: 150000,
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

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistDetailScreen(
            playlist: playlist,
            initialSongs: [s1],
            playlistDao: FakePlaylistDao(playlistSongs: [s1]),
            songDao: FakeSongDao([s1]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      // Tap hero banner trigger
      await tester.tap(find.byKey(const ValueKey('playlist_detail_banner_edit_trigger')));
      await tester.pumpAndSettle();

      // PlaylistEditScreen is mounted
      expect(find.byType(PlaylistEditScreen), findsOneWidget);
    });

    testWidgets('tapping edit pencil in tracks section opens PlaylistTracksEditScreen', (tester) async {
      const playlist = Playlist(
        id: 42,
        name: 'Chill Vibes',
        songCount: 1,
        totalDuration: 150000,
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

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistDetailScreen(
            playlist: playlist,
            initialSongs: [s1],
            playlistDao: FakePlaylistDao(playlistSongs: [s1]),
            songDao: FakeSongDao([s1]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      // Tap pencil icon next to TRACKS
      await tester.tap(find.byKey(const ValueKey('playlist_detail_edit_button')));
      await tester.pumpAndSettle();

      // PlaylistTracksEditScreen is mounted
      expect(find.byType(PlaylistTracksEditScreen), findsOneWidget);
      expect(find.text('EDITAR CANCIONES'), findsOneWidget);
    });
  });

  group('PlaylistTracksEditScreen and Deletion Confirmation Tests', () {
    testWidgets('PlaylistTracksEditScreen renders drag handles, cover thumbnails, native trash icon, and handles remove and save', (tester) async {
      const playlist = Playlist(
        id: 42,
        name: 'Workout Mix',
        songCount: 2,
        totalDuration: 300000,
        createdAt: 100,
        updatedAt: 100,
      );

      final s1 = Song(
        mediaStoreId: 701,
        title: 'Track Alpha',
        artist: 'Artist Alpha',
        duration: 150000,
        path: '/alpha.mp3',
        dateModified: 100,
      );
      final s2 = Song(
        mediaStoreId: 702,
        title: 'Track Beta',
        artist: 'Artist Beta',
        duration: 150000,
        path: '/beta.mp3',
        dateModified: 100,
      );

      final fakePlaylistDao = FakePlaylistDao(playlistSongs: [s1, s2]);

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistTracksEditScreen(
            playlist: playlist,
            initialSongs: [s1, s2],
            playlistDao: fakePlaylistDao,
            songDao: FakeSongDao([s1, s2]),
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('EDITAR CANCIONES'), findsOneWidget);
      expect(find.text('Track Alpha'), findsOneWidget);
      expect(find.text('Track Beta'), findsOneWidget);

      // Artwork covers on the left
      expect(find.byType(AnimaArtworkImage), findsNWidgets(2));

      // Native trash icons to discard tracks
      expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));

      // Drag handles
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));

      // Remove Track Alpha using trash icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pump();

      expect(find.text('Track Alpha'), findsNothing);
      expect(find.text('Track Beta'), findsOneWidget);

      // Save tracks
      await tester.tap(find.byKey(const ValueKey('playlist_tracks_save_button')));
      await tester.pumpAndSettle();

      expect(fakePlaylistDao.playlistSongs.length, 1);
      expect(fakePlaylistDao.playlistSongs.first.title, 'Track Beta');
    });

    testWidgets('PlaylistDeleteDialog displays warning and confirms or cancels deletion', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await PlaylistDeleteDialog.show(
                  context,
                  playlistName: 'My Awesome Playlist',
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar playlist'), findsOneWidget);
      expect(find.textContaining('My Awesome Playlist'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      // Open again and confirm
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('confirm_delete_playlist_button')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('LibraryPlaylistsView long-press triggers PlaylistDeleteDialog and confirms deletion', (tester) async {
      const playlist = Playlist(
        id: 99,
        name: 'Summer Hits',
        songCount: 1,
        totalDuration: 100,
        createdAt: 100,
        updatedAt: 100,
      );

      final fakePlaylistDao = FakePlaylistDao(playlistSongs: []);
      fakePlaylistDao.lastCreated = playlist;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LibraryPlaylistsView(
              playlists: [playlist],
              playlistDao: fakePlaylistDao,
              songDao: FakeSongDao([]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Summer Hits'), findsOneWidget);

      // Long press playlist card for 1 second
      await tester.longPress(find.text('Summer Hits'));
      await tester.pumpAndSettle();

      // Deletion dialog is shown
      expect(find.text('Eliminar playlist'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PlaylistDeleteDialog),
          matching: find.textContaining('Summer Hits'),
        ),
        findsOneWidget,
      );

      // Confirm delete
      await tester.tap(find.byKey(const ValueKey('confirm_delete_playlist_button')));
      await tester.pumpAndSettle();

      expect(fakePlaylistDao.wasDeleted, isTrue);
    });
  });

  group('FuzzySearchEngine Dictionary Search Tests', () {
    test('uses typo-tolerant dictionary search to find songs by artist or typo', () async {
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
      final searchEngine = FuzzySearchEngine(songDao: fakeSongDao);

      // Type slightly misspelled query "Strby" (fuzzy match for Starboy)
      final results1 = await searchEngine.searchOnlySongs('Strby', limit: 10);
      expect(results1.any((s) => s.title == 'Starboy'), isTrue);

      // Search by artist "M83"
      final results2 = await searchEngine.searchOnlySongs('M83', limit: 10);
      expect(results2.any((s) => s.title == 'Midnight City'), isTrue);
    });
  });

  group('SongContextSheet and Space Playlist Picker Tests', () {
    final testSong = Song(
      mediaStoreId: 888,
      title: 'Starlight',
      artist: 'Muse',
      album: 'Black Holes and Revelations',
      duration: 240000,
      path: '/music/starlight.flac',
      dateModified: 100,
      size: 25165824, // 24.0 MB
    );

    testWidgets('PlayerMetadataView title is interactive and invokes onTitleTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerMetadataView(
              song: testSong,
              onTitleTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Starlight'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('player_metadata_title_button')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('SongContextSheet displays 3 action buttons and audio technical specification card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SongContextSheet(
              song: testSong,
              songDao: FakeSongDao([testSong]),
              playlistDao: FakePlaylistDao(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Top action buttons
      expect(find.byKey(const ValueKey('context_add_to_playlist_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('context_toggle_favorite_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('context_delete_song_button')), findsOneWidget);

      // Audio specification card metrics
      expect(find.text('FORMATO'), findsOneWidget);
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.text('CALIDAD'), findsOneWidget);
      expect(find.text('44.1 kHz'), findsOneWidget);
      expect(find.text('PESO'), findsOneWidget);
      expect(find.text('24.0 MB'), findsOneWidget);
    });

    testWidgets('SongContextSheet delete button opens SongDeleteDialog and deletes song on confirmation', (tester) async {
      final fakeSongDao = FakeSongDao([testSong]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SongContextSheet(
              song: testSong,
              songDao: fakeSongDao,
              playlistDao: FakePlaylistDao(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap delete action button
      await tester.tap(find.byKey(const ValueKey('context_delete_song_button')));
      await tester.pumpAndSettle();

      // Delete confirmation dialog is visible
      expect(find.text('Eliminar canción'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SongDeleteDialog),
          matching: find.textContaining('Starlight'),
        ),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.byKey(const ValueKey('confirm_delete_song_button')));
      await tester.pumpAndSettle();

      expect(fakeSongDao.songDeleted, isTrue);
    });

    testWidgets('SongPlaylistPickerSheet renders Space 2:1 tiles and dims/undims on toggle', (tester) async {
      const p1 = Playlist(
        id: 101,
        name: 'Rock Classics',
        songCount: 0,
        totalDuration: 0,
        createdAt: 100,
        updatedAt: 100,
      );

      final fakePlaylistDao = FakePlaylistDao();
      fakePlaylistDao.lastCreated = p1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SongPlaylistPickerSheet(
              song: testSong,
              playlistDao: fakePlaylistDao,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AÑADIR A PLAYLIST'), findsOneWidget);
      expect(find.text('Rock Classics'), findsOneWidget);

      // Initially not in playlist
      expect(find.text('EN PLAYLIST'), findsNothing);

      // Tap playlist card -> adds song and dims with EN PLAYLIST badge
      await tester.tap(find.byKey(const ValueKey('playlist_picker_tile_101')));
      await tester.pump();

      expect(find.text('EN PLAYLIST'), findsOneWidget);
      expect(fakePlaylistDao.songsInPlaylist.contains(888), isTrue);

      // Tap again -> removes song and undims
      await tester.tap(find.byKey(const ValueKey('playlist_picker_tile_101')));
      await tester.pump();

      expect(find.text('EN PLAYLIST'), findsNothing);
      expect(fakePlaylistDao.songsInPlaylist.contains(888), isFalse);
    });
  });

  group('SongOptionsPill and Optimized Queue Tests', () {
    final testSong = Song(
      mediaStoreId: 999,
      title: 'Quantum Horizon',
      artist: 'Starlight Echoes',
      album: 'Cosmic Dreams',
      duration: 215000,
      path: '/path/quantum.mp3',
      dateAdded: 100,
      dateModified: 200,
    );

    testWidgets('SongOptionsPill renders 3 dots and duration, tapping expands horizontal pill with 4 action icons without text', (tester) async {
      bool playlistAdded = false;
      bool queueFirstCalled = false;
      bool queueEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SongOptionsPill(
                song: testSong,
                durationText: '3:35',
                onPlaylistAdd: () => playlistAdded = true,
                onQueueFirst: () => queueFirstCalled = true,
                onQueueEnd: () => queueEndCalled = true,
              ),
            ),
          ),
        ),
      );

      // Initially duration and 3-dots trigger are visible
      expect(find.text('3:35'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);

      // Tap 3 dots to expand pill horizontally
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      // Close icon morphs in
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // The 4 action icons are present without text
      expect(find.byKey(const ValueKey('song_pill_playlist_999')), findsOneWidget);
      expect(find.byKey(const ValueKey('song_pill_favorite_999')), findsOneWidget);
      expect(find.byKey(const ValueKey('song_pill_queue_first_999')), findsOneWidget);
      expect(find.byKey(const ValueKey('song_pill_queue_end_999')), findsOneWidget);

      // Verify actions
      await tester.tap(find.byKey(const ValueKey('song_pill_playlist_999')));
      await tester.pumpAndSettle();
      expect(playlistAdded, isTrue);

      // Verify collapsed after action
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add_rounded), findsNothing);

      // Re-expand and tap queue first
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('song_pill_queue_first_999')));
      await tester.pumpAndSettle();
      expect(queueFirstCalled, isTrue);

      // Re-expand and tap queue end
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('song_pill_queue_end_999')));
      await tester.pumpAndSettle();
      expect(queueEndCalled, isTrue);
    });

    testWidgets('SongOptionsPillCoordinator ensures strictly only ONE pill is open across songs', (tester) async {
      SongOptionsPillCoordinator.instance.reset();

      final song1 = Song(
        mediaStoreId: 101,
        title: 'Song One',
        artist: 'Artist A',
        album: 'Album A',
        duration: 180000,
        path: '/song1.mp3',
        dateAdded: 1,
        dateModified: 2,
      );

      final song2 = Song(
        mediaStoreId: 102,
        title: 'Song Two',
        artist: 'Artist B',
        album: 'Album B',
        duration: 200000,
        path: '/song2.mp3',
        dateAdded: 3,
        dateModified: 4,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SongOptionsPill(song: song1, durationText: '3:00'),
                SongOptionsPill(song: song2, durationText: '3:20'),
              ],
            ),
          ),
        ),
      );

      // Initially both pills are collapsed
      expect(find.byKey(const ValueKey('song_options_button_101')), findsOneWidget);
      expect(find.byKey(const ValueKey('song_options_button_102')), findsOneWidget);
      expect(SongOptionsPillCoordinator.instance.activeSongMediaStoreId, isNull);

      // Open pill for song 1
      await tester.tap(find.byKey(const ValueKey('song_options_button_101')));
      await tester.pumpAndSettle();

      expect(SongOptionsPillCoordinator.instance.isExpanded(101), isTrue);
      expect(SongOptionsPillCoordinator.instance.isExpanded(102), isFalse);
      expect(find.byKey(const ValueKey('song_pill_playlist_101')), findsOneWidget);
      expect(find.byKey(const ValueKey('song_pill_playlist_102')), findsNothing);

      // Now open pill for song 2 -> song 1 must close automatically
      await tester.tap(find.byKey(const ValueKey('song_options_button_102')));
      await tester.pumpAndSettle();

      expect(SongOptionsPillCoordinator.instance.isExpanded(101), isFalse);
      expect(SongOptionsPillCoordinator.instance.isExpanded(102), isTrue);
      expect(find.byKey(const ValueKey('song_pill_playlist_101')), findsNothing);
      expect(find.byKey(const ValueKey('song_pill_playlist_102')), findsOneWidget);

      // Tap song 2's close button -> closes pill
      await tester.tap(find.byKey(const ValueKey('song_options_button_102')));
      await tester.pumpAndSettle();

      expect(SongOptionsPillCoordinator.instance.activeSongMediaStoreId, isNull);
      expect(find.byKey(const ValueKey('song_pill_playlist_102')), findsNothing);
    });

    testWidgets('Playing a song automatically closes any open SongOptionsPill', (tester) async {
      SongOptionsPillCoordinator.instance.reset();

      final song = Song(
        mediaStoreId: 201,
        title: 'Playing Track',
        artist: 'Artist',
        album: 'Album',
        duration: 150000,
        path: '/track.mp3',
        dateAdded: 1,
        dateModified: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SongOptionsPill(song: song, durationText: '2:30'),
            ),
          ),
        ),
      );

      // Open the pill
      await tester.tap(find.byKey(const ValueKey('song_options_button_201')));
      await tester.pumpAndSettle();
      expect(SongOptionsPillCoordinator.instance.isExpanded(201), isTrue);

      // Simulate playback starting/changing
      PlaybackController.instance.playSong(song);
      await tester.pumpAndSettle();

      // Pill must now be closed
      expect(SongOptionsPillCoordinator.instance.isExpanded(201), isFalse);
      expect(find.byKey(const ValueKey('song_pill_playlist_201')), findsNothing);
    });

    test('Playlist track tile renders unrounded sharp cover (borderRadius: 0.0)', () {
      final tile = PlaylistTrackTile(
        song: testSong,
        trackIndex: 1,
        allPlaylistSongs: [testSong],
      );
      expect(tile.trackIndex, 1);
    });

    testWidgets('PlaybackQueueSheet renders only upcoming tracks after currently playing song without BackdropFilter blur', (tester) async {
      final songA = Song(
        mediaStoreId: 1,
        title: 'Song A (Past)',
        artist: 'Artist',
        album: 'Album',
        duration: 180000,
        path: '/a.mp3',
        dateAdded: 1,
        dateModified: 1,
      );
      final songB = Song(
        mediaStoreId: 2,
        title: 'Song B (Now Playing)',
        artist: 'Artist',
        album: 'Album',
        duration: 200000,
        path: '/b.mp3',
        dateAdded: 1,
        dateModified: 1,
      );
      final songC = Song(
        mediaStoreId: 3,
        title: 'Song C (Next 1)',
        artist: 'Artist',
        album: 'Album',
        duration: 220000,
        path: '/c.mp3',
        dateAdded: 1,
        dateModified: 1,
      );
      final songD = Song(
        mediaStoreId: 4,
        title: 'Song D (Next 2)',
        artist: 'Artist',
        album: 'Album',
        duration: 240000,
        path: '/d.mp3',
        dateAdded: 1,
        dateModified: 1,
      );

      final controller = PlaybackController.instance;
      // Active is songB at index 1 in queue [songA, songB, songC, songD]
      controller.setQueueForTesting([songA, songB, songC, songD], currentIndex: 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PlaybackQueueSheet.show(ctx),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Zero BackdropFilter blur in tree
      expect(find.byType(BackdropFilter), findsNothing);

      // Now playing shows Song B
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('Song B (Now Playing)'), findsOneWidget);

      // Upcoming count is 2 (Song C and Song D)
      expect(find.text('UP NEXT • 2 TRACKS'), findsOneWidget);

      // Song A (past) is not in the upcoming list
      expect(find.text('Song A (Past)'), findsNothing);

      // Song C and Song D are listed with indices 1 and 2
      expect(find.text('Song C (Next 1)'), findsOneWidget);
      expect(find.text('Song D (Next 2)'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
