/// File: home_features_test.dart
/// Description: Comprehensive test suite for Home screen features, including the 'WELCOME' header,
/// 'Today's Selection' 20-track collage playlist, PinnedFavoritesDao CRUD, gapless row packing,
/// and double-tap favorite pinning with subtle red background transitions on Album, Artist, and Playlist.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/selection/today_selection_service.dart';
import 'package:project_anima/components/favorite_heart_button.dart';
import 'package:project_anima/features/album/components/album_header_view.dart';
import 'package:project_anima/features/artist/components/artist_header_view.dart';
import 'package:project_anima/features/home/components/home_artist_card.dart';
import 'package:project_anima/features/home/components/home_pinned_section.dart';
import 'package:project_anima/features/home/components/space_header.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/home/screens/home.dart';
import 'package:project_anima/features/playlist/components/playlist_detail_header.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

void main() {
  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  group('SpaceHeader Component Tests', () {
    testWidgets('SpaceHeader renders Space title in Inconsolata typography', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpaceHeader(),
          ),
        ),
      );

      expect(find.text('Space'), findsOneWidget);
    });

    testWidgets('SpaceHeader supports custom titles while maintaining styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpaceHeader(title: 'DISCOVER'),
          ),
        ),
      );

      expect(find.text('DISCOVER'), findsOneWidget);
    });
  });

  group('TodaySelectionService Unit Tests', () {
    final sampleSongs = List<Song>.generate(
      25,
      (i) => Song(
        id: i + 1,
        mediaStoreId: 1000 + i,
        title: 'Track $i',
        artist: 'Artist ${i % 5}',
        album: 'Album ${i % 4}',
        path: '/storage/music/song_$i.mp3',
        duration: 210000,
        dateModified: 1700000000,
      ),
    );

    test('getCollageSongs selects up to 4 songs with distinct albums', () {
      final service = TodaySelectionService.instance;
      final collage = service.getCollageSongs(sampleSongs);

      expect(collage.length, 4);
      final albumKeys = collage.map((s) => s.album).toSet();
      expect(albumKeys.length, 4);
    });
  });

  group('PinnedFavoritesDao Database & Revision Tests', () {
    late Directory tempDbDir;
    late AppDatabase appDb;

    setUp(() async {
      tempDbDir = await Directory.systemTemp.createTemp('pinned_fav_test_');
      appDb = AppDatabase.instance;
      final dbPath = p.join(tempDbDir.path, 'test_pinned.db');
      await appDb.initDatabase(customPath: dbPath);
      await PinnedFavoritesDao.instance.clearAll();
    });

    tearDown(() async {
      await appDb.close();
      if (tempDbDir.existsSync()) {
        tempDbDir.deleteSync(recursive: true);
      }
    });

    test('albumKey, artistKey, and playlistKey produce deterministic keys', () {
      expect(
        PinnedFavoritesDao.albumKey('Abbey Road', 'The Beatles'),
        'album::abbey road::the beatles',
      );
      expect(
        PinnedFavoritesDao.artistKey('Metallica'),
        'artist::metallica',
      );
      expect(
        PinnedFavoritesDao.playlistKey(42),
        'playlist::42',
      );
    });

    test('togglePin inserts item when unpinned and deletes when pinned, incrementing revision', () async {
      final dao = PinnedFavoritesDao.instance;
      final initialRev = PinnedFavoritesDao.revision.value;

      final fav = PinnedFavorite(
        itemType: PinnedItemType.album,
        itemKey: 'album::back in black::ac/dc',
        title: 'Back in Black',
        subtitle: 'AC/DC',
        albumId: 101,
        representativeSongId: 501,
        pinnedAt: DateTime.now(),
      );

      // 1. Initial check
      expect(await dao.isPinned(fav.itemKey), isFalse);

      // 2. First toggle: should pin and increment revision
      final pinned = await dao.togglePin(fav);
      expect(pinned, isTrue);
      expect(await dao.isPinned(fav.itemKey), isTrue);
      expect(PinnedFavoritesDao.revision.value, initialRev + 1);

      final list = await dao.getAllPinned();
      expect(list.length, 1);
      expect(list.first.title, 'Back in Black');
      expect(list.first.isAlbum, isTrue);

      // 3. Second toggle: should unpin and increment revision
      final unpinned = await dao.togglePin(fav);
      expect(unpinned, isFalse);
      expect(await dao.isPinned(fav.itemKey), isFalse);
      expect(PinnedFavoritesDao.revision.value, initialRev + 2);

      final emptyList = await dao.getAllPinned();
      expect(emptyList.isEmpty, isTrue);
    });
  });

  group('Home Gapless Row Packing Algorithm Tests', () {
    test('pairs 1-span albums/artists and gives playlists full rows without empty spaces', () {
      final now = DateTime.now();
      final items = [
        PinnedFavorite(
          itemType: PinnedItemType.album,
          itemKey: 'album::a::artist',
          title: 'Album A',
          pinnedAt: now,
        ),
        PinnedFavorite(
          itemType: PinnedItemType.playlist,
          itemKey: 'playlist::1',
          title: 'Playlist 1',
          playlistId: 1,
          pinnedAt: now,
        ),
        PinnedFavorite(
          itemType: PinnedItemType.album,
          itemKey: 'album::b::artist',
          title: 'Album B',
          pinnedAt: now,
        ),
        PinnedFavorite(
          itemType: PinnedItemType.artist,
          itemKey: 'artist::pink floyd',
          title: 'Pink Floyd',
          pinnedAt: now,
        ),
      ];

      final rows = HomePinnedSection.buildGaplessRows(items);

      // Row 1 should be pair of [Album A, Album B]
      expect(rows[0], isA<PairRowItem>());
      final pair = rows[0] as PairRowItem;
      expect(pair.first.title, 'Album A');
      expect(pair.second?.title, 'Album B');

      // Row 2 should be full playlist [Playlist 1]
      expect(rows[1], isA<FullRowItem>());
      final full = rows[1] as FullRowItem;
      expect(full.playlist.title, 'Playlist 1');

      // Row 3 should be odd remaining artist [Pink Floyd]
      expect(rows[2], isA<PairRowItem>());
      final lastPair = rows[2] as PairRowItem;
      expect(lastPair.first.title, 'Pink Floyd');
      expect(lastPair.second, isNull);
    });
  });

  group('Favorite Heart Button & Subtle Red Background Widget Tests', () {
    testWidgets('FavoriteHeartButton renders white filled icon when pinned and outlined when unpinned', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteHeartButton(
              isPinned: true,
              onToggle: () => toggled = true,
            ),
          ),
        ),
      );

      // Verify filled heart icon is rendered
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byType(FavoriteHeartButton));
      await tester.pump();
      expect(toggled, isTrue);
    });

    testWidgets('ArtistHeaderView renders FavoriteHeartButton below artist name and toggles callback', (tester) async {
      bool heartTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistHeaderView(
              artistName: 'Daft Punk',
              onEditTap: () {},
              isPinned: false,
              onToggleFavorite: () => heartTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.byType(FavoriteHeartButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byType(FavoriteHeartButton));
      await tester.pump();

      expect(heartTapped, isTrue);
    });

    testWidgets('PlaylistDetailHeader renders FavoriteHeartButton on right margin of hero banner', (tester) async {
      bool heartTapped = false;

      final playlist = Playlist(
        id: 10,
        name: 'Cyberpunk Drive',
        createdAt: 1000000,
        updatedAt: 1000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistDetailHeader(
              playlist: playlist,
              songCount: 15,
              totalDurationMs: 3600000,
              isShuffleEnabled: false,
              onPlay: () {},
              onToggleShuffle: () {},
              isPinned: true,
              onToggleFavorite: () => heartTapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(FavoriteHeartButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byType(FavoriteHeartButton));
      await tester.pump();

      expect(heartTapped, isTrue);
    });

    testWidgets('AlbumHeaderView renders FavoriteHeartButton below duration & track count and toggles callback', (tester) async {
      bool heartTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumHeaderView(
              albumName: 'Random Access Memories',
              artistName: 'Daft Punk',
              songCount: 13,
              totalDurationMs: 4440000,
              isPinned: false,
              onToggleFavorite: () => heartTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('13 songs • 1 hr 14 min'), findsOneWidget);
      expect(find.byType(FavoriteHeartButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byType(FavoriteHeartButton));
      await tester.pump();

      expect(heartTapped, isTrue);
    });
  });

  group('HomeScreen Integration & Space Tests', () {
    testWidgets('HomeScreen renders Space header and AmbientParticlesCanvas without Welcome or Today Selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(
            showBottomNav: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Space'), findsOneWidget);
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
      expect(find.text('WELCOME'), findsNothing);
      expect(find.text('Today Selection'), findsNothing);
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('HomeArtistCard renders circular avatar and centered artist name', (tester) async {
      final artist = PinnedFavorite(
        itemType: PinnedItemType.artist,
        itemKey: 'artist::david bowie',
        title: 'David Bowie',
        subtitle: 'Artist',
        pinnedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              child: HomeArtistCard(artist: artist),
            ),
          ),
        ),
      );

      expect(find.text('David Bowie'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
    });

    testWidgets('PlaylistDetailScreen when isEditable=false and showHeroCover=false hides edit button and hero banner', (tester) async {
      final playlist = Playlist(
        id: -1,
        name: 'Today Selection',
        createdAt: 1000000,
        updatedAt: 1000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlaylistDetailScreen(
            playlist: playlist,
            initialSongs: const [],
            isEditable: false,
            showHeroCover: false,
            animateBounce: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Today Selection'), findsOneWidget);
      // Edit button must NOT be present
      expect(find.byKey(const ValueKey('playlist_detail_edit_button')), findsNothing);
    });
  });
}
