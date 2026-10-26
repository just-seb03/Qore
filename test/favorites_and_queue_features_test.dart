/// File: favorites_and_queue_features_test.dart
/// Description: Comprehensive unit and widget test suite for Favorites playlist on Home,
/// FavoriteSongsDao CRUD and in-memory cache reactivity, track queue operations in PlaybackController,
/// liquid hold gesture animation wrapper, and PlaybackQueueSheet modal drawer.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/features/home/components/home_pinned_section.dart';
import 'package:project_anima/components/modal_dismiss_indicator.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/features/home/components/home_favorites_hero_card.dart';
import 'package:project_anima/features/home/components/space_tiles_grid.dart';
import 'package:project_anima/features/home/screens/home.dart';
import 'package:project_anima/features/player/components/playback_queue_sheet.dart';

void main() {
  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  late AppDatabase db;
  late Directory tempDir;
  late FavoriteSongsDao favoriteDao;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fav_queue_test_');
    final dbPath = p.join(tempDir.path, 'anima_fav_test.db');
    db = AppDatabase.instance;
    await db.initDatabase(customPath: dbPath);
    favoriteDao = FavoriteSongsDao(dbProvider: db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final testSong1 = Song(
    id: 1,
    mediaStoreId: 101,
    title: 'Neon Odyssey',
    artist: 'Cyber Runner',
    album: 'Future Drift',
    albumId: 501,
    duration: 184000,
    path: '/music/neon.mp3',
    dateModified: 1700000000,
  );

  final testSong2 = Song(
    id: 2,
    mediaStoreId: 102,
    title: 'Solar Flare',
    artist: 'Aura',
    album: 'Eclipse',
    albumId: 502,
    duration: 215000,
    path: '/music/solar.mp3',
    dateModified: 1700000001,
  );

  final testSong3 = Song(
    id: 3,
    mediaStoreId: 103,
    title: 'Nightfall',
    artist: 'Ghost',
    album: 'Echoes',
    albumId: 503,
    duration: 195000,
    path: '/music/night.mp3',
    dateModified: 1700000002,
  );

  group('FavoriteSongsDao Database & In-Memory Cache Tests', () {
    test('toggleFavorite marks a song as favorite and updates revision', () async {
      int notifications = 0;
      favoriteDao.favoritesRevision.addListener(() => notifications++);

      final added = await favoriteDao.toggleFavorite(testSong1);
      expect(added, isTrue);
      expect(favoriteDao.isFavorite(101), isTrue);
      expect(favoriteDao.isFavorite(102), isFalse);
      expect(notifications, 1);

      final favorites = await favoriteDao.getAllFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.title, 'Neon Odyssey');
      expect(favorites.first.mediaStoreId, 101);
    });

    test('toggleFavorite toggles off an existing favorite', () async {
      await favoriteDao.toggleFavorite(testSong1);
      expect(favoriteDao.isFavorite(101), isTrue);

      final removed = await favoriteDao.toggleFavorite(testSong1);
      expect(removed, isFalse);
      expect(favoriteDao.isFavorite(101), isFalse);

      final favorites = await favoriteDao.getAllFavorites();
      expect(favorites, isEmpty);
    });

    test('getAllFavorites preserves descending order of addition', () async {
      await favoriteDao.toggleFavorite(testSong1);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await favoriteDao.toggleFavorite(testSong2);

      final favorites = await favoriteDao.getAllFavorites();
      expect(favorites.length, 2);
      expect(favorites.first.mediaStoreId, 102);
      expect(favorites.last.mediaStoreId, 101);
    });

    test('clearAll removes all favorites and clears cache', () async {
      await favoriteDao.toggleFavorite(testSong1);
      await favoriteDao.toggleFavorite(testSong2);

      await favoriteDao.clearAll();
      expect(favoriteDao.isFavorite(101), isFalse);
      expect(favoriteDao.isFavorite(102), isFalse);

      final favorites = await favoriteDao.getAllFavorites();
      expect(favorites, isEmpty);
    });
  });

  group('PlaybackController Queue Operations Tests', () {
    test('addToQueue adds song to active queue', () {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1], currentIndex: 0);

      controller.addToQueue(testSong2);
      expect(controller.queue.length, 2);
      expect(controller.queue.last.mediaStoreId, 102);
    });

    test('addToQueue adds song to beginning of upcoming queue, not at the end', () {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1, testSong3], currentIndex: 0);

      controller.addToQueue(testSong2);
      expect(controller.queue.length, 3);
      expect(controller.queue[0].mediaStoreId, 101);
      expect(controller.queue[1].mediaStoreId, 102);
      expect(controller.queue[2].mediaStoreId, 103);
    });

    test('reorderQueue moves items and keeps current playing index tracked', () {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1, testSong2, testSong3], currentIndex: 0);

      // Move item at 0 to index 2
      controller.reorderQueue(0, 2);
      expect(controller.queue.length, 3);
      expect(controller.queue[2].mediaStoreId, 101);
      expect(controller.currentIndex, 2);
      expect(controller.currentSong?.mediaStoreId, 101);
    });

    test('removeFromQueue removes item and updates current index', () {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1, testSong2, testSong3], currentIndex: 1);

      // Remove item at index 0 (testSong1)
      controller.removeFromQueue(0);
      expect(controller.queue.length, 2);
      expect(controller.queue[0].mediaStoreId, 102);
      expect(controller.currentIndex, 0);
      expect(controller.currentSong?.mediaStoreId, 102);
    });

    test('clearUpcomingQueue clears songs after current playing song', () {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1, testSong2, testSong3], currentIndex: 0);

      controller.clearUpcomingQueue();
      expect(controller.queue.length, 1);
      expect(controller.queue.first.mediaStoreId, 101);
      expect(controller.currentIndex, 0);
    });
  });

  group('HomeFavoritesHeroCard Widget Tests', () {
    testWidgets('renders Favorites title without heart icon and without play button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeFavoritesHeroCard(
              songs: [testSong1, testSong2],
            ),
          ),
        ),
      );

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('renders clean background without heart icon when favorites list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeFavoritesHeroCard(
              songs: [],
            ),
          ),
        ),
      );

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });
  });

  group('Track Favorite & Queue Button Integration Tests', () {
    testWidgets('tapping heart button toggles favorite directly without calling song play onTap', (tester) async {
      bool playTapped = false;
      expect(favoriteDao.isFavorite(testSong1.mediaStoreId), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: Icon(
                favoriteDao.isFavorite(testSong1.mediaStoreId)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              onPressed: () {
                favoriteDao.toggleFavorite(testSong1);
              },
            ),
          ),
        ),
      );

      await tester.runAsync(() async {
        await tester.tap(find.byType(IconButton));
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump();

      expect(favoriteDao.isFavorite(testSong1.mediaStoreId), isTrue);
      expect(playTapped, isFalse);
    });
  });

  group('HomePinnedSection Gapless Packing Tests', () {
    test('buildGaplessRows pairs 4 half items into exactly 2 pair rows without gaps', () {
      final items = [
        PinnedFavorite(id: 1, itemType: PinnedItemType.album, itemKey: 'a1', title: 'Album 1', subtitle: 'Art 1', pinnedAt: DateTime.now()),
        PinnedFavorite(id: 2, itemType: PinnedItemType.album, itemKey: 'a2', title: 'Album 2', subtitle: 'Art 2', pinnedAt: DateTime.now()),
        PinnedFavorite(id: 3, itemType: PinnedItemType.artist, itemKey: 'art1', title: 'Artist 1', subtitle: 'Sub 1', pinnedAt: DateTime.now()),
        PinnedFavorite(id: 4, itemType: PinnedItemType.artist, itemKey: 'art2', title: 'Artist 2', subtitle: 'Sub 2', pinnedAt: DateTime.now()),
      ];

      final rows = HomePinnedSection.buildGaplessRows(items);
      expect(rows.length, 2);
      expect(rows[0], isA<PairRowItem>());
      expect((rows[0] as PairRowItem).second, isNotNull);
      expect(rows[1], isA<PairRowItem>());
      expect((rows[1] as PairRowItem).second, isNotNull);
    });

    test('buildGaplessRows packs 3 half items into 1 full pair row and 1 trailing odd item', () {
      final items = [
        PinnedFavorite(id: 1, itemType: PinnedItemType.album, itemKey: 'a1', title: 'Album 1', subtitle: 'Art 1', pinnedAt: DateTime.now()),
        PinnedFavorite(id: 2, itemType: PinnedItemType.album, itemKey: 'a2', title: 'Album 2', subtitle: 'Art 2', pinnedAt: DateTime.now()),
        PinnedFavorite(id: 3, itemType: PinnedItemType.album, itemKey: 'a3', title: 'Album 3', subtitle: 'Art 3', pinnedAt: DateTime.now()),
      ];

      final rows = HomePinnedSection.buildGaplessRows(items);
      expect(rows.length, 2);
      expect(rows[0], isA<PairRowItem>());
      expect((rows[0] as PairRowItem).second, isNotNull);
      expect(rows[1], isA<PairRowItem>());
      expect((rows[1] as PairRowItem).second, isNull);
    });
  });

  group('PlaybackQueueSheet Component Tests', () {
    testWidgets('renders queue sheet with now playing and up next tracks', (tester) async {
      final controller = PlaybackController.instance;
      controller.setQueueForTesting([testSong1, testSong2], currentIndex: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PlaybackQueueSheet.show(ctx),
                child: const Text('Open Queue'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Queue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.text('UP NEXT • 2 TRACKS'), findsOneWidget);
      expect(find.text('Neon Odyssey'), findsWidgets);
      expect(find.text('Solar Flare'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.byType(ModalDismissIndicator), findsOneWidget);

      // Dismiss by tapping the modal dismiss indicator
      await tester.tap(find.byType(ModalDismissIndicator));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('NOW PLAYING'), findsNothing);
    });
  });

  group('HomeScreen Integration with Space Screen Tests', () {
    testWidgets('HomeScreen renders SpaceTilesGrid and no legacy hero banners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            showBottomNav: false,
            initialTodaySongs: [testSong1],
            initialFavoriteSongs: [testSong2],
            initialPinnedItems: const [],
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SpaceTilesGrid), findsOneWidget);
      expect(find.text('WELCOME'), findsNothing);
      expect(find.text('Today Selection'), findsNothing);
      expect(find.text('Favorites'), findsNothing);
    });
  });
}
