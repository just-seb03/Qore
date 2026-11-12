import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/recent_search_dao.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/search/models/recent_search_item.dart';
import 'package:project_anima/core/search/models/search_entity_type.dart';
import 'package:project_anima/core/search/models/search_results_group.dart';
import 'package:project_anima/core/search/models/search_top_result.dart';
import 'package:project_anima/core/search/music_search_controller.dart';
import 'package:project_anima/core/search/recent_search_controller.dart';
import 'package:project_anima/features/search/components/cards/search_top_result_card.dart';
import 'package:project_anima/features/search/components/cards/search_artist_card.dart';
import 'package:project_anima/features/search/components/common/search_play_button.dart';
import 'package:project_anima/features/search/components/search_bar.dart';
import 'package:project_anima/features/search/components/search_recent_list.dart';
import 'package:project_anima/features/search/components/search_results_list.dart';
import 'package:project_anima/features/search/components/states/search_empty_view.dart';
import 'package:project_anima/features/search/components/states/search_no_results_view.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  GoogleFonts.config.allowRuntimeFetching = false;

  late Directory tempDir;
  late AppDatabase appDatabase;
  late RecentSearchDao recentDao;
  late RecentSearchController recentController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anima_search_test_');
    final dbPath = p.join(tempDir.path, 'test_anima_search.db');

    appDatabase = AppDatabase.instance;
    await appDatabase.initDatabase(customPath: dbPath);
    recentDao = RecentSearchDao(appDatabase: appDatabase);
    recentController = RecentSearchController(dao: recentDao);
  });

  tearDown(() async {
    await appDatabase.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Recent Searches Capped at 10 Items Tests', () {
    test('RecentSearchController caps in-memory and SQLite items to 10', () async {
      await recentController.init();

      // Insert 15 songs
      for (int i = 1; i <= 15; i++) {
        final song = Song(
          mediaStoreId: 1000 + i,
          title: 'Song $i',
          artist: 'Artist $i',
          album: 'Album $i',
          duration: 180000,
          path: '/storage/music/song_$i.mp3',
          dateModified: 100,
        );
        await recentController.addSong(song);
      }

      // Memory should have at most 10 items
      expect(recentController.items.length, 10);
      // Most recent should be Song 15
      expect(recentController.items.first.title, 'Song 15');

      // Database should also have at most 10 items
      final dbItems = await recentDao.getRecentSearches(limit: 20);
      expect(dbItems.length, 10);
      expect(dbItems.first.title, 'Song 15');
    });

    test('RecentSearchItem subtitles format cleanly in English', () {
      final song = Song(
        mediaStoreId: 101,
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: 354000,
        path: '/storage/queen.mp3',
        dateModified: 100,
      );
      final songItem = RecentSearchItem.fromSong(song);
      expect(songItem.subtitle, 'Song • Queen');

      const album = AlbumDiscoveryItem(
        name: 'Abbey Road',
        artist: 'The Beatles',
        songCount: 17,
        totalDuration: 3000000,
        representativeSongId: 201,
      );
      final albumItem = RecentSearchItem.fromAlbum(album);
      expect(albumItem.subtitle, 'Album • The Beatles');

      const artist = ArtistDiscoveryItem(
        name: 'Daft Punk',
        songCount: 20,
        albumCount: 4,
        representativeSongId: 301,
      );
      final artistItem = RecentSearchItem.fromArtist(artist);
      expect(artistItem.subtitle, 'Artist');
    });

    test('RecentSearchItem cleanArtistName cleans artist accurately without prefixes', () {
      const album = AlbumDiscoveryItem(
        name: 'Chet Baker Sings',
        artist: 'Chet Baker',
        songCount: 14,
        totalDuration: 2600000,
        representativeSongId: 501,
      );
      final albumItem = RecentSearchItem.fromAlbum(album);
      expect(albumItem.cleanArtistName, 'Chet Baker');
      expect(albumItem.artistName, 'Chet Baker');

      final spanishAlbumItem = albumItem.copyWith(subtitle: 'Álbum • Chet Baker');
      expect(spanishAlbumItem.cleanArtistName, 'Chet Baker');

      final lowerAlbumItem = albumItem.copyWith(subtitle: 'album chet baker');
      expect(lowerAlbumItem.cleanArtistName, 'chet baker');

      final song = Song(
        mediaStoreId: 901,
        title: 'My Funny Valentine',
        artist: 'Chet Baker',
        album: 'Chet Baker Sings',
        duration: 140000,
        path: '/storage/chet.mp3',
        dateModified: 100,
      );
      final songItem = RecentSearchItem.fromSong(song);
      expect(songItem.cleanArtistName, 'Chet Baker');

      final plainArtistItem = RecentSearchItem(
        type: RecentSearchType.artist,
        entityKey: 'artist:chet baker',
        title: 'Chet Baker',
        subtitle: 'Artist',
        representativeSongId: 501,
        timestampSeconds: 100,
      );
      expect(plainArtistItem.cleanArtistName, 'Chet Baker');
    });
  });

  group('SearchRecentList English Localization Tests', () {
    testWidgets('renders RECENT SEARCHES and Clear all in English', (tester) async {
      final song = Song(
        mediaStoreId: 201,
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: 230000,
        path: '/storage/starboy.mp3',
        dateModified: 100,
      );
      await tester.runAsync(() async {
        await recentController.addSong(song);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchRecentList(controller: recentController),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('RECENT SEARCHES'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
      expect(find.text('Starboy'), findsOneWidget);
      expect(find.text('Song • The Weeknd'), findsOneWidget);
    });
  });

  group('SearchTopResultCard Minimal Layout Tests (No Badges)', () {
    testWidgets('artist top result renders only photo avatar and name', (tester) async {
      const artist = ArtistDiscoveryItem(
        name: 'Daft Punk',
        songCount: 24,
        albumCount: 4,
        representativeSongId: 301,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTopResultCard.artist(
              artist: artist,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TOP RESULT'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      // No badges!
      expect(find.text('ARTIST'), findsNothing);
      expect(find.text('Artista'), findsNothing);
    });

    testWidgets('album top result renders name, artist, and song count in English without badge', (tester) async {
      const album = AlbumDiscoveryItem(
        name: 'Random Access Memories',
        artist: 'Daft Punk',
        songCount: 13,
        totalDuration: 4000000,
        representativeSongId: 401,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTopResultCard.album(
              album: album,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TOP RESULT'), findsOneWidget);
      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('13 songs'), findsOneWidget);
      // No badge!
      expect(find.text('ALBUM'), findsNothing);
    });

    testWidgets('song top result renders title and artist without badge or secondary subtitle', (tester) async {
      final song = Song(
        mediaStoreId: 501,
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: 369000,
        path: '/storage/get_lucky.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTopResultCard.song(
              song: song,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('TOP RESULT'), findsOneWidget);
      expect(find.text('Get Lucky'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      // No badge!
      expect(find.text('SONG'), findsNothing);
    });

    testWidgets('tapping play button fires onPlayTap and does not fire card onTap', (tester) async {
      int cardTapCount = 0;
      int playTapCount = 0;

      final song = Song(
        mediaStoreId: 501,
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: 369000,
        path: '/storage/get_lucky.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTopResultCard.song(
              song: song,
              onTap: () => cardTapCount++,
              onPlayTap: () => playTapCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap on the play button
      await tester.tap(find.byType(SearchPlayButton));
      await tester.pump();

      expect(playTapCount, 1, reason: 'Play button callback should fire once');
      expect(cardTapCount, 0, reason: 'Card onTap must NOT fire when play button is tapped');

      // Tap on the card title (outside play button)
      await tester.tap(find.text('Get Lucky'));
      await tester.pump();

      expect(playTapCount, 1, reason: 'Play button callback should not fire again');
      expect(cardTapCount, 1, reason: 'Card onTap should fire when tapping the card body');
    });

    testWidgets('artist top result play button fires onPlayTap exclusively', (tester) async {
      int cardTapCount = 0;
      int playTapCount = 0;

      const artist = ArtistDiscoveryItem(
        name: 'Daft Punk',
        songCount: 24,
        albumCount: 4,
        representativeSongId: 301,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTopResultCard.artist(
              artist: artist,
              onTap: () => cardTapCount++,
              onPlayTap: () => playTapCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SearchPlayButton));
      await tester.pump();

      expect(playTapCount, 1);
      expect(cardTapCount, 0);

      await tester.tap(find.text('Daft Punk'));
      await tester.pump();

      expect(playTapCount, 1);
      expect(cardTapCount, 1);
    });

    testWidgets('album top result play button fires onPlayTap exclusively', (tester) async {
      int cardTapCount = 0;
      int playTapCount = 0;

      const album = AlbumDiscoveryItem(
        name: 'Random Access Memories',
        artist: 'Daft Punk',
        songCount: 13,
        totalDuration: 4000000,
        representativeSongId: 401,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchTopResultCard.album(
              album: album,
              onTap: () => cardTapCount++,
              onPlayTap: () => playTapCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(SearchPlayButton));
      await tester.pump();

      expect(playTapCount, 1);
      expect(cardTapCount, 0);

      await tester.tap(find.text('Random Access Memories'));
      await tester.pump();

      expect(playTapCount, 1);
      expect(cardTapCount, 1);
    });
  });

  group('English Localization & Hint Text Tests', () {
    testWidgets('AppSearchBar defaults to What do you want to listen to?', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppSearchBar(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('What do you want to listen to?'), findsOneWidget);
    });

    testWidgets('SearchEmptyView renders clean empty state without invitation texts when recent items is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchEmptyView(controller: recentController),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SEARCH YOUR LIBRARY'), findsNothing);
      expect(find.text('Indexed titles, artists, or albums'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('SearchNoResultsView renders in English', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchNoResultsView(query: 'NonExistentSong123'),
          ),
        ),
      );

      expect(find.text('NO RESULTS FOUND'), findsOneWidget);
      expect(find.text('No matches found for "NonExistentSong123"'), findsOneWidget);
    });

    testWidgets('SearchArtistCard subtitle renders Artist in English', (tester) async {
      const artist = ArtistDiscoveryItem(
        name: 'The Beatles',
        songCount: 50,
        albumCount: 10,
        representativeSongId: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchArtistCard(artist: artist),
          ),
        ),
      );

      expect(find.text('The Beatles'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('Artista'), findsNothing);
    });
  });

  group('SearchResultsList Top Result Play and Tap Interaction Tests', () {
    testWidgets('top result artist play button calls onArtistPlayTap, card calls onArtistTap', (tester) async {
      final fakeController = FakeMusicSearchController();
      const artist = ArtistDiscoveryItem(
        name: 'Pink Floyd',
        songCount: 15,
        albumCount: 3,
        representativeSongId: 10,
      );
      fakeController.query = 'Pink Floyd';
      fakeController.resultsGroup = SearchResultsGroup(
        query: 'Pink Floyd',
        primaryType: SearchEntityType.artist,
        topResult: SearchTopResult.artist(artist, 1.0),
        matchedArtists: [artist],
      );

      ArtistDiscoveryItem? tappedArtist;
      ArtistDiscoveryItem? playedArtist;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              controller: fakeController,
              recentSearchController: FakeRecentSearchController(),
              onArtistTap: (a) => tappedArtist = a,
              onArtistPlayTap: (a) => playedArtist = a,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pink Floyd'), findsWidgets);

      // Tap play button
      await tester.tap(find.byType(SearchPlayButton).first);
      await tester.pump();

      expect(playedArtist?.name, 'Pink Floyd');
      expect(tappedArtist, isNull);

      // Tap card body outside play button
      await tester.tap(find.text('Pink Floyd').first);
      await tester.pump();

      expect(tappedArtist?.name, 'Pink Floyd');
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('top result album play button calls onAlbumPlayTap, card calls onAlbumTap', (tester) async {
      final fakeController = FakeMusicSearchController();
      const album = AlbumDiscoveryItem(
        name: 'The Dark Side of the Moon',
        artist: 'Pink Floyd',
        songCount: 10,
        totalDuration: 2500000,
        representativeSongId: 11,
      );
      fakeController.query = 'The Dark Side';
      fakeController.resultsGroup = SearchResultsGroup(
        query: 'The Dark Side',
        primaryType: SearchEntityType.album,
        topResult: SearchTopResult.album(album, 1.0),
        matchedAlbums: [album],
      );

      AlbumDiscoveryItem? tappedAlbum;
      AlbumDiscoveryItem? playedAlbum;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              controller: fakeController,
              recentSearchController: FakeRecentSearchController(),
              onAlbumTap: (a) => tappedAlbum = a,
              onAlbumPlayTap: (a) => playedAlbum = a,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap play button
      await tester.tap(find.byType(SearchPlayButton).first);
      await tester.pump();

      expect(playedAlbum?.name, 'The Dark Side of the Moon');
      expect(tappedAlbum, isNull);

      // Tap card body outside play button
      await tester.tap(find.text('The Dark Side of the Moon').first);
      await tester.pump();

      expect(tappedAlbum?.name, 'The Dark Side of the Moon');
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('top result song play button calls onSongPlayTap, card body calls onTopSongCardTap', (tester) async {
      final fakeController = FakeMusicSearchController();
      final song = Song(
        mediaStoreId: 12,
        title: 'Time',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        duration: 413000,
        path: '/storage/time.mp3',
        dateModified: 100,
      );
      fakeController.query = 'Time';
      fakeController.resultsGroup = SearchResultsGroup(
        query: 'Time',
        primaryType: SearchEntityType.song,
        topResult: SearchTopResult.song(song, 1.0),
        matchedSongs: [song],
      );

      Song? playedSong;
      Song? navigatedAlbumSong;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              controller: fakeController,
              recentSearchController: FakeRecentSearchController(),
              onSongPlayTap: (s) => playedSong = s,
              onTopSongCardTap: (s) => navigatedAlbumSong = s,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap play button
      await tester.tap(find.byType(SearchPlayButton).first);
      await tester.pump();

      expect(playedSong?.title, 'Time');
      expect(navigatedAlbumSong, isNull);

      // Tap card body outside play button
      await tester.tap(find.text('Time').first);
      await tester.pump();

      expect(navigatedAlbumSong?.title, 'Time');
      expect(navigatedAlbumSong?.album, 'The Dark Side of the Moon');
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}

class FakeMusicSearchController extends ChangeNotifier implements MusicSearchController {
  @override
  String query = '';

  @override
  SearchResultsGroup resultsGroup = SearchResultsGroup.empty();

  @override
  bool isLoading = false;

  @override
  bool get hasResults => resultsGroup.isNotEmpty;

  @override
  List<Song> get results => resultsGroup.matchedSongs;

  @override
  SongDao get songDao => SongDao();

  @override
  void clear() {}

  @override
  void onQueryChanged(String newQuery) {}

  @override
  Future<void> reloadDictionary() async {}
}

class FakeRecentSearchController extends ChangeNotifier implements RecentSearchController {
  @override
  List<RecentSearchItem> items = [];

  @override
  bool isInitialized = true;

  @override
  Future<void> init() async {}

  @override
  Future<void> addSong(Song song) async {}

  @override
  Future<void> addAlbum(AlbumDiscoveryItem album) async {}

  @override
  Future<void> addArtist(ArtistDiscoveryItem artist) async {}

  @override
  Future<void> touchItem(RecentSearchItem item) async {}

  @override
  Future<void> removeItem(RecentSearchItem item) async {}

  @override
  Future<void> clearAll() async {}
}
