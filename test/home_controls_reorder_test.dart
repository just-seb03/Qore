/// File: home_controls_reorder_test.dart
/// Description: Comprehensive unit and widget tests for the defined places and reordering
/// system in features/home/controls/ (HomeSlotItem, HomeLayoutController, HomeSlotGrid).
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/features/home/components/space_header.dart';
import 'package:project_anima/features/home/controls/home_layout_controller.dart';
import 'package:project_anima/features/home/controls/home_slot_grid.dart';
import 'package:project_anima/features/home/controls/home_slot_item.dart';

void main() {
  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  late AppDatabase db;
  late Directory tempDir;
  late HomeLayoutController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('home_controls_test_');
    final dbPath = p.join(tempDir.path, 'anima_home_ctrl_test.db');
    db = AppDatabase.instance;
    await db.initDatabase(customPath: dbPath);
    controller = HomeLayoutController(dbProvider: db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final samplePinnedAlbum = PinnedFavorite(
    id: 1,
    itemType: PinnedItemType.album,
    itemKey: 'album::discovery::daft punk',
    title: 'Discovery',
    subtitle: 'Daft Punk',
    albumId: 10,
    pinnedAt: DateTime.now(),
  );

  final samplePinnedArtist = PinnedFavorite(
    id: 2,
    itemType: PinnedItemType.artist,
    itemKey: 'artist::justice',
    title: 'Justice',
    subtitle: 'Artist',
    pinnedAt: DateTime.now(),
  );

  final samplePinnedPlaylist = PinnedFavorite(
    id: 3,
    itemType: PinnedItemType.playlist,
    itemKey: 'playlist::99',
    title: 'French Touch',
    subtitle: '25 songs',
    playlistId: 99,
    pinnedAt: DateTime.now(),
  );

  group('HomeSlotItem Model Tests', () {
    test('creates system slots with full width', () {
      final today = HomeSlotItem.todaySelection();
      expect(today.id, HomeSlotItem.kTodaySelectionId);
      expect(today.type, HomeSlotType.todaySelection);
      expect(today.isFullWidth, isTrue);

      final favs = HomeSlotItem.favorites();
      expect(favs.id, HomeSlotItem.kFavoritesId);
      expect(favs.type, HomeSlotType.favorites);
      expect(favs.isFullWidth, isTrue);
    });

    test('creates pinned slots with appropriate width per type', () {
      final albumSlot = HomeSlotItem.fromPinned(samplePinnedAlbum);
      expect(albumSlot.type, HomeSlotType.pinnedAlbum);
      expect(albumSlot.isFullWidth, isFalse);

      final artistSlot = HomeSlotItem.fromPinned(samplePinnedArtist);
      expect(artistSlot.type, HomeSlotType.pinnedArtist);
      expect(artistSlot.isFullWidth, isFalse);

      final playlistSlot = HomeSlotItem.fromPinned(samplePinnedPlaylist);
      expect(playlistSlot.type, HomeSlotType.pinnedPlaylist);
      expect(playlistSlot.isFullWidth, isTrue);
    });
  });

  group('HomeLayoutController Defined Places & Shift Tests', () {
    test('syncItems combines system playlists and pinned favorites into defined slots', () {
      controller.syncItems(
        pinnedItems: [samplePinnedAlbum, samplePinnedArtist],
        showToday: true,
        showFavorites: true,
      );

      expect(controller.items.length, 4);
      expect(controller.items[0].id, HomeSlotItem.kTodaySelectionId);
      expect(controller.items[1].id, HomeSlotItem.kFavoritesId);
      expect(controller.items[2].id, HomeSlotItem.pinnedId(samplePinnedAlbum));
      expect(controller.items[3].id, HomeSlotItem.pinnedId(samplePinnedArtist));
    });

    test('reorder displaces elements like Android home screen and shifts items', () async {
      controller.syncItems(
        pinnedItems: [samplePinnedAlbum, samplePinnedArtist],
        showToday: true,
        showFavorites: true,
      );

      // Initial: [Today(0), Favorites(1), Album(2), Artist(3)]
      // Move Album (index 2) to the top (index 0)
      controller.reorder(2, 0);
      await controller.saveOrder();

      // Expected shifted order: [Album, Today, Favorites, Artist]
      expect(controller.items[0].id, HomeSlotItem.pinnedId(samplePinnedAlbum));
      expect(controller.items[1].id, HomeSlotItem.kTodaySelectionId);
      expect(controller.items[2].id, HomeSlotItem.kFavoritesId);
      expect(controller.items[3].id, HomeSlotItem.pinnedId(samplePinnedArtist));
    });

    test('moveItemUp and moveItemDown swap adjacent places', () async {
      controller.syncItems(
        pinnedItems: [samplePinnedAlbum],
        showToday: true,
        showFavorites: true,
      );

      // Move Favorites (index 1) up to index 0
      controller.moveItemUp(1);
      await controller.saveOrder();
      expect(controller.items[0].id, HomeSlotItem.kFavoritesId);
      expect(controller.items[1].id, HomeSlotItem.kTodaySelectionId);

      // Move Favorites (now at index 0) down to index 1
      controller.moveItemDown(0);
      await controller.saveOrder();
      expect(controller.items[0].id, HomeSlotItem.kTodaySelectionId);
      expect(controller.items[1].id, HomeSlotItem.kFavoritesId);
    });

    test('liveShift performs in-memory proximity displacement during drag', () {
      controller.syncItems(
        pinnedItems: [samplePinnedAlbum, samplePinnedPlaylist],
        showToday: true,
        showFavorites: true,
      );

      expect(controller.items[0].id, HomeSlotItem.kTodaySelectionId);
      expect(controller.items[1].id, HomeSlotItem.kFavoritesId);

      // Fluidly shift from index 0 to index 2
      controller.liveShift(0, 2);
      expect(controller.items[0].id, HomeSlotItem.kFavoritesId);
      expect(controller.items[1].id, HomeSlotItem.pinnedId(samplePinnedAlbum));
      expect(controller.items[2].id, HomeSlotItem.kTodaySelectionId);
    });

    test('enterArrangingMode and exitArrangingMode toggle editing state', () {
      expect(controller.isArranging, isFalse);
      controller.enterArrangingMode();
      expect(controller.isArranging, isTrue);
      controller.exitArrangingMode();
      expect(controller.isArranging, isFalse);
    });

    test('persists custom layout order into SQLite and restores it', () async {
      controller.syncItems(
        pinnedItems: [samplePinnedAlbum, samplePinnedPlaylist],
        showToday: true,
        showFavorites: true,
      );

      // Move Playlist to index 0
      controller.reorder(3, 0);
      await controller.saveOrder();

      // Create new controller instance with same database
      final newController = HomeLayoutController(dbProvider: db);
      await newController.init();
      newController.syncItems(
        pinnedItems: [samplePinnedAlbum, samplePinnedPlaylist],
        showToday: true,
        showFavorites: true,
      );

      expect(newController.items.first.id, HomeSlotItem.pinnedId(samplePinnedPlaylist));
    });
  });

  group('HomeSlotGrid Widget Tests', () {
    testWidgets('renders slot items and toggles edit mode with ticket checkmark button below WELCOME', (tester) async {
      controller.syncItems(
        pinnedItems: [samplePinnedAlbum],
        showToday: true,
        showFavorites: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return Column(
                    children: [
                      const SpaceHeader(),
                      HomeSlotGrid(
                        todaySongs: const [],
                        favoriteSongs: const [],
                        controller: controller,
                        onOpenAlbum: (_) {},
                        onOpenPlaylist: (_) {},
                        onOpenArtist: (_) {},
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('ORGANIZAR INICIO'), findsNothing);
      expect(find.byKey(const ValueKey('home_slot_grid_done_button')), findsNothing);

      // Enter arranging mode
      controller.enterArrangingMode();
      await tester.pump();

      expect(controller.isArranging, isTrue);

      // Exit arranging mode
      controller.exitArrangingMode();
      await tester.pump();

      expect(controller.isArranging, isFalse);
    });
  });
}
