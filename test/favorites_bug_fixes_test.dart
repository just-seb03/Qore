/// File: favorites_bug_fixes_test.dart
/// Description: Regression tests verifying Favorites apartado fixes:
/// 1) Picking a song inside Favorites does not overwrite/reconfigure the list with Recent/All songs
///    (distinct sentinel ID -3 vs Recientes -2 and ignored playbackHistoryRevision).
/// 2) Deleted songs are automatically pruned from Favorites (via syncDelta, deleteSong,
///    pruneOrphanedFavorites, getAllFavorites, and live Favorites screen reload).
/// 3) Large Favorites playlists virtualize tracks via SliverList.builder instead of eagerly
///    building every row simultaneously.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/playlist_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/playlist.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/navigation/app_route_tracker.dart';
import 'package:project_anima/core/playback/playback_controller.dart';
import 'package:project_anima/core/scanner/music_indexer.dart';
import 'package:project_anima/features/home/components/tiles/metro_favorites_tile.dart';
import 'package:project_anima/features/playlist/components/playlist_track_tile.dart';
import 'package:project_anima/features/playlist/screens/playlist_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  group('Favorites Sentinel Isolation, Deleted Pruning & Virtualization Tests', () {
    late Directory tempDbDir;
    late AppDatabase appDb;
    late SongDao songDao;

    Song makeSong(int id, String title, {String artist = 'Artist A'}) => Song(
          mediaStoreId: id,
          title: title,
          artist: artist,
          album: 'Album $id',
          albumId: id,
          duration: 180000,
          path: '/music/$id.mp3',
          dateModified: 1700000000 + id,
        );

    setUp(() async {
      tempDbDir = await Directory.systemTemp.createTemp('favorites_fixes_test_');
      appDb = AppDatabase.instance;
      await appDb.initDatabase(customPath: p.join(tempDbDir.path, 'fav_fixes.db'));
      await FavoriteSongsDao.instance.clearAll();
      songDao = SongDao(appDatabase: appDb);
      AppRouteTracker.instance.reset();
    });

    tearDown(() async {
      PlaybackController.instance.setQueueForTesting(const [], currentIndex: -1);
      await FavoriteSongsDao.instance.clearAll();
      await appDb.close();
      if (tempDbDir.existsSync()) {
        tempDbDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
        'opening Favorites from MetroFavoritesTile and selecting a song preserves Favorites instead of showing Recents/All songs',
        (tester) async {
      final favSong = makeSong(101, 'My Favorite Track');
      final nonFavRecentSong = makeSong(202, 'Non-Fav Recent Song');
      final otherLibrarySong = makeSong(303, 'Random Library Song');

      await songDao.syncDelta(
        toInsertOrUpdate: [favSong, nonFavRecentSong, otherLibrarySong],
        toDelete: const [],
      );
      await FavoriteSongsDao.instance.toggleFavorite(favSong);

      // Seed playback history with a non-favorite song
      final recentDbSong = await songDao.getSongByMediaStoreId(202);
      await songDao.recordPlayback(
        songId: recentDbSong!.id!,
        artist: recentDbSong.artist,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [AppRouteTracker.instance],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: MetroFavoritesTile(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(MetroFavoritesTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump();

      expect(find.byType(PlaylistDetailScreen), findsOneWidget);
      expect(
        AppRouteTracker.instance.routeNames.last,
        equals(
          AppRouteTracker.playlistRouteName(
            playlistId: PlaylistDetailScreen.favoritesPlaylistId,
            name: 'Favorites',
          ),
        ),
      );
      expect(find.text('My Favorite Track'), findsOneWidget);
      expect(find.text('Non-Fav Recent Song'), findsNothing);
      expect(find.text('Random Library Song'), findsNothing);

      // Select the song inside Favorites and trigger playback history update
      PlaybackController.instance.prepareQueueForSong(
        favSong,
        queue: [favSong],
        playlistId: PlaylistDetailScreen.favoritesPlaylistId,
      );
      await tester.runAsync(() async {
        final favDbSong = await songDao.getSongByMediaStoreId(101);
        await songDao.recordPlayback(
          songId: favDbSong!.id!,
          artist: favDbSong.artist,
        );
        SongDao.notifyPlaybackHistoryChanged();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Favorites must NEVER reconfigure into Recents/all songs
      expect(find.text('My Favorite Track'), findsOneWidget);
      expect(find.text('Non-Fav Recent Song'), findsNothing);
      expect(find.text('Random Library Song'), findsNothing);

      // Dispose tree cleanly before teardown closes DB
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    });

    test('deleted storage songs are pruned from favorite_songs and cache', () async {
      final keepSong = makeSong(10, 'Surviving Favorite');
      final deletedSong = makeSong(20, 'Deleted Favorite');
      final preOrphanSong = makeSong(30, 'Already Deleted Orphan');

      await songDao.syncDelta(
        toInsertOrUpdate: [keepSong, deletedSong],
        toDelete: const [],
      );
      await FavoriteSongsDao.instance.toggleFavorite(keepSong);
      await FavoriteSongsDao.instance.toggleFavorite(deletedSong);

      // Seed an orphan row directly in favorite_songs whose track no longer exists in songs
      await FavoriteSongsDao.instance.toggleFavorite(preOrphanSong);
      expect(FavoriteSongsDao.instance.isFavorite(30), isTrue);

      // Querying getAllFavorites while library is indexed immediately prunes orphan 30
      var favorites = await FavoriteSongsDao.instance.getAllFavorites();
      expect(favorites.map((s) => s.mediaStoreId).toSet(), equals({10, 20}));
      expect(FavoriteSongsDao.instance.isFavorite(30), isFalse);

      // Delta sync deleting track 20 removes it from favorite_songs too
      await songDao.syncDelta(
        toInsertOrUpdate: const [],
        toDelete: const [20],
      );
      favorites = await FavoriteSongsDao.instance.getAllFavorites();
      expect(favorites.map((s) => s.mediaStoreId).toList(), equals([10]));
      expect(FavoriteSongsDao.instance.isFavorite(20), isFalse);

      // When the last song on device is deleted (songs becomes empty), explicit prune removes all favorites
      await songDao.syncDelta(toInsertOrUpdate: const [], toDelete: const [10]);
      final remainingAfterLast = await FavoriteSongsDao.instance.getAllFavorites();
      expect(remainingAfterLast, isEmpty);

      // Even if a pre-existing orphan sits when songs is empty, pruneOrphanedFavorites cleans it
      await FavoriteSongsDao.instance.toggleFavorite(preOrphanSong);
      final pruned = await FavoriteSongsDao.instance.pruneOrphanedFavorites();
      expect(pruned, equals(1));
      expect(FavoriteSongsDao.instance.isFavorite(30), isFalse);
    });

    testWidgets('open Favorites screen refreshes and removes songs deleted during rescan',
        (tester) async {
      final keepSong = makeSong(11, 'Keep Me');
      final removeSong = makeSong(22, 'Delete Me From Storage');

      await songDao.syncDelta(
        toInsertOrUpdate: [keepSong, removeSong],
        toDelete: const [],
      );
      await FavoriteSongsDao.instance.toggleFavorite(keepSong);
      await FavoriteSongsDao.instance.toggleFavorite(removeSong);

      final favPlaylist = Playlist(
        id: PlaylistDetailScreen.favoritesPlaylistId,
        name: 'Favorites',
        createdAt: 100,
        updatedAt: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlaylistDetailScreen(
            playlist: favPlaylist,
            isEditable: false,
            showHeroCover: false,
            animateBounce: false,
          ),
        ),
      );

      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump();

      expect(find.text('Keep Me'), findsOneWidget);
      expect(find.text('Delete Me From Storage'), findsOneWidget);

      // Simulate background storage deletion detected by MusicIndexer
      await tester.runAsync(() async {
        await songDao.syncDelta(toInsertOrUpdate: const [], toDelete: const [22]);
        MusicIndexer.revision.value++;
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pump();

      expect(find.text('Keep Me'), findsOneWidget);
      expect(find.text('Delete Me From Storage'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    });

    testWidgets('PlaylistDetailScreen virtualizes large Favorites lists using SliverList instead of building all rows eagerly',
        (tester) async {
      final manySongs = List<Song>.generate(
        150,
        (i) => makeSong(5000 + i, 'Track $i'),
      );

      const favPlaylist = Playlist(
        id: PlaylistDetailScreen.favoritesPlaylistId,
        name: 'Favorites',
        createdAt: 100,
        updatedAt: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 700)),
            child: PlaylistDetailScreen(
              playlist: favPlaylist,
              initialSongs: manySongs,
              playlistDao: PlaylistDao(appDatabase: appDb),
              songDao: songDao,
              isEditable: false,
              showHeroCover: false,
              animateBounce: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);
      final builtTileCount = tester.widgetList(find.byType(PlaylistTrackTile)).length;
      expect(builtTileCount, greaterThan(0));
      expect(builtTileCount, lessThan(30));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

