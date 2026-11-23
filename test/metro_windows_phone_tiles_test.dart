/// File: metro_windows_phone_tiles_test.dart
/// Description: Comprehensive test suite for Windows Phone Metro Live Tiles in Space:
/// 3D perspective flips (horizontal for squares, vertical for rectangles), zero padding,
/// zero elevation shadows, sharp corners, square artist & album covers, and top-left Favorites tile.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/home/components/metro_live_tile.dart';
import 'package:project_anima/features/home/components/space_tiles_grid.dart';
import 'package:project_anima/features/home/components/tiles/metro_album_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_artist_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_favorites_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_playlist_tile.dart';
import 'package:project_anima/features/home/components/tiles/metro_tile_glass_back.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

Song createMockSong({
  required int id,
  required String title,
  required String artist,
  required String album,
  required int mediaStoreId,
}) {
  return Song(
    id: id,
    mediaStoreId: mediaStoreId,
    title: title,
    artist: artist,
    album: album,
    duration: 210000,
    path: '/storage/emulated/0/Music/$title.mp3',
    dateAdded: 1700000000,
    dateModified: 1700000000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetroLiveTile 3D Animation Tests', () {
    testWidgets('renders front widget initially and rotates on axis', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 150,
                child: MetroLiveTile(
                  initialDelay: const Duration(milliseconds: 100),
                  flipAxis: MetroFlipAxis.horizontal,
                  front: const Text('FRONT_SIDE'),
                  back: const Text('BACK_SIDE'),
                ),
              ),
            ),
          ),
        ),
      );

      // Initially displays front
      expect(find.text('FRONT_SIDE'), findsOneWidget);
      expect(find.text('BACK_SIDE'), findsNothing);

      // Trigger animation timer
      await tester.pump(const Duration(milliseconds: 150));
      // Mid-flip
      await tester.pump(const Duration(milliseconds: 400));
      // Settled on back
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('BACK_SIDE'), findsOneWidget);

      // Back side stays for half a second (500ms) then reverses
      await tester.pump(const Duration(milliseconds: 600));
      // Mid-reversal
      await tester.pump(const Duration(milliseconds: 400));
      // Settled on front
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('FRONT_SIDE'), findsOneWidget);
    });

    testWidgets('vertical flip configures Matrix4 rotationX', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 150,
                child: MetroLiveTile(
                  initialDelay: const Duration(milliseconds: 100),
                  flipAxis: MetroFlipAxis.vertical,
                  front: const Text('FRONT_RECT'),
                  back: const Text('BACK_RECT'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('FRONT_RECT'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('BACK_RECT'), findsOneWidget);
    });

    testWidgets('cancels local flips when TickerMode is disabled and flips via external trigger when enabled',
        (tester) async {
      final trigger = ValueNotifier<int?>(null);
      addTearDown(trigger.dispose);

      Widget buildTile({required bool tickerEnabled}) {
        return MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: tickerEnabled,
              child: Center(
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: MetroLiveTile(
                    flipTrigger: trigger,
                    flipSlot: 2,
                    front: const Text('COORD_FRONT'),
                    back: const Text('COORD_BACK'),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTile(tickerEnabled: false));
      trigger.value = 2;
      await tester.pump(const Duration(milliseconds: 800));
      // Must stay on front when TickerMode is disabled
      expect(find.text('COORD_FRONT'), findsOneWidget);
      expect(find.text('COORD_BACK'), findsNothing);

      // Enable TickerMode and fire another slot trigger first (ignored)
      await tester.pumpWidget(buildTile(tickerEnabled: true));
      trigger.value = 1;
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('COORD_FRONT'), findsOneWidget);

      // Fire matching slot trigger (flips smoothly)
      trigger.value = 2;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('COORD_BACK'), findsOneWidget);

      // Cleanly settle back to front
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('COORD_FRONT'), findsOneWidget);
    });
  });

  group('MetroFavoritesTile Widget Tests', () {
    testWidgets('renders large filled heart in theme accent color and handles tap',
        (tester) async {
      final mockSongs = [
        createMockSong(id: 1, title: 'Starboy', artist: 'The Weeknd', album: 'Starboy', mediaStoreId: 101),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 180,
              child: MetroFavoritesTile(
                initialSongs: mockSongs,
              ),
            ),
          ),
        ),
      );

      // Verify large filled heart icon
      final iconFinder = find.byIcon(Icons.favorite_rounded);
      expect(iconFinder, findsOneWidget);
      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.size, equals(64.0));
      expect(iconWidget.color, equals(AppColors.accent));

      // Verify label
      expect(find.text('FAVORITOS'), findsOneWidget);

      // Tap to open favorites detail screen
      await tester.tap(find.byType(MetroFavoritesTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    });
  });

  group('MetroArtistTile Widget Tests', () {
    testWidgets('renders square tile with silhouette and large bold artist name when no custom photo',
        (tester) async {
      final artist = PinnedFavorite(
        id: 1,
        itemKey: 'artist::the weeknd',
        itemType: PinnedItemType.artist,
        title: 'The Weeknd',
        pinnedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 180,
              child: MetroArtistTile(
                artist: artist,
              ),
            ),
          ),
        ),
      );

      expect(find.text('The Weeknd'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      final Text nameText = tester.widget(find.text('The Weeknd'));
      expect(nameText.style?.fontWeight, equals(FontWeight.w800));
      expect(nameText.style?.fontSize, equals(16.0));
    });

    testWidgets('renders custom saved artist square photo when coverPath exists',
        (tester) async {
      final tempFile = File('${Directory.systemTemp.path}/test_artist_avatar.png');
      tempFile.writeAsBytesSync([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      addTearDown(() {
        if (tempFile.existsSync()) tempFile.deleteSync();
      });

      final artist = PinnedFavorite(
        id: 1,
        itemKey: 'artist::the weeknd',
        itemType: PinnedItemType.artist,
        title: 'The Weeknd',
        coverPath: tempFile.path,
        pinnedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 180,
              child: MetroArtistTile(
                artist: artist,
              ),
            ),
          ),
        ),
      );

      expect(find.text('The Weeknd'), findsOneWidget);
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.image, isA<FileImage>());

      final Text nameText = tester.widget(find.text('The Weeknd'));
      expect(nameText.style?.fontWeight, equals(FontWeight.w800));
      expect(nameText.style?.fontSize, equals(16.0));
    });
  });

  group('MetroTileGlassBack Widget Tests', () {
    testWidgets('renders solid surfaceContainerHigh background without glass or BackdropFilter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              height: 150,
              child: MetroTileGlassBack(
                icon: Icons.album_rounded,
                label: 'ÁLBUM',
              ),
            ),
          ),
        ),
      );

      expect(find.text('ÁLBUM'), findsOneWidget);
      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == AppColors.surfaceContainerHigh,
        ),
        findsOneWidget,
      );
    });
  });

  group('MetroAlbumTile Widget Tests', () {
    testWidgets('renders square full-bleed HD artwork and album title', (tester) async {
      final album = PinnedFavorite(
        id: 2,
        itemKey: 'album::after hours::the weeknd',
        itemType: PinnedItemType.album,
        title: 'After Hours',
        subtitle: 'The Weeknd',
        pinnedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 180,
              child: MetroAlbumTile(
                album: album,
              ),
            ),
          ),
        ),
      );

      expect(find.text('After Hours'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);
      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
    });
  });

  group('MetroPlaylistTile Widget Tests', () {
    testWidgets('renders rectangular 2:1 tile with custom font and vertical flip',
        (tester) async {
      final playlist = PinnedFavorite(
        id: 3,
        itemKey: 'playlist::10',
        itemType: PinnedItemType.playlist,
        playlistId: 10,
        title: 'Night Drive',
        fontFamily: 'Pacifico',
        pinnedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 180,
              child: MetroPlaylistTile(
                playlistItem: playlist,
              ),
            ),
          ),
        ),
      );

      // Front has user custom title overlay and no subtitle
      expect(find.text('Night Drive'), findsOneWidget);
      expect(find.text('PLAYLIST'), findsNothing);

      // Trigger flip to back face
      await tester.pump(const Duration(seconds: 49));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('PLAYLIST'), findsOneWidget);
    });
  });

  group('SpaceTilesGrid Layout & Windows Phone Structure Tests', () {
    testWidgets('arranges top-left Favorites and paired items with zero gap',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final pinned = [
        PinnedFavorite(
          id: 1,
          itemKey: 'album::discovery::daft punk',
          itemType: PinnedItemType.album,
          title: 'Discovery',
          subtitle: 'Daft Punk',
          pinnedAt: DateTime.now(),
        ),
        PinnedFavorite(
          id: 2,
          itemKey: 'artist::justice',
          itemType: PinnedItemType.artist,
          title: 'Justice',
          pinnedAt: DateTime.now(),
        ),
        PinnedFavorite(
          id: 3,
          itemKey: 'playlist::42',
          itemType: PinnedItemType.playlist,
          playlistId: 42,
          title: 'French Touch',
          pinnedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceTilesGrid(
              initialPinnedItems: pinned,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Favorites is always in the top row
      expect(find.byType(MetroFavoritesTile), findsOneWidget);

      // Discovery album is paired in top row
      expect(find.text('Discovery'), findsOneWidget);

      // French Touch playlist is full width
      expect(find.text('French Touch'), findsOneWidget);

      // Justice artist is present
      expect(find.text('Justice'), findsOneWidget);
    });

    testWidgets('long press on tile opens unpin confirmation dialog', (tester) async {
      final pinned = [
        PinnedFavorite(
          id: 1,
          itemKey: 'album::discovery::daft punk',
          itemType: PinnedItemType.album,
          title: 'Discovery',
          subtitle: 'Daft Punk',
          pinnedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpaceTilesGrid(
              initialPinnedItems: pinned,
            ),
          ),
        ),
      );
      await tester.pump();

      // Long press the Discovery album tile
      await tester.longPress(find.text('Discovery'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify unpin dialog appears
      expect(find.text('Desanclar de Space'), findsOneWidget);
      expect(find.text('¿Deseas desanclar "Discovery" de Space?'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);
      expect(find.text('DESANCLAR'), findsOneWidget);

      // Tap cancel
      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(find.text('Desanclar de Space'), findsNothing);
    });
  });

  group('AppFonts Segoe UI Windows Metro Typography Tests', () {
    test('AppFonts provides Segoe UI as primary font family and valid fallbacks', () {
      expect(AppFonts.segoeUi, equals('Segoe UI'));
      expect(AppFonts.fallbackChain, contains('Segoe UI'));
      expect(AppFonts.fallbackChain, contains('Selawik'));
      expect(AppFonts.fallbackChain, contains('sans-serif'));

      final style = AppFonts.segoe(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      );

      expect(style.fontFamily, equals('Segoe UI'));
      expect(style.fontSize, equals(16.0));
      expect(style.fontWeight, equals(FontWeight.w600));
      expect(style.letterSpacing, equals(0.5));
      expect(style.fontFamilyFallback, contains('Selawik'));
    });

    test('ThemeData toThemeData applies Segoe UI across primary typography', () {
      final theme = AppTheme.theme;
      expect(theme.navigationBarTheme.labelTextStyle?.resolve({})?.fontFamily, equals('Segoe UI'));
      expect(theme.textTheme.bodyMedium?.fontFamily, equals('Segoe UI'));
    });
  });
}
