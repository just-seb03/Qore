/// File: navigation_space_notification_fixes_test.dart
/// Description: Regression tests verifying:
/// 1) Space orphaned pins pruning when songs are deleted from storage (syncDelta / deleteSong / pruneOrphanedPins)
/// 2) AnimaAudioHandler immediate MediaItem, queue, duration, and PlaybackState updates on track switches
/// 3) AppRouteTracker route stack deduplication for deep Player <-> Album <-> Artist navigation flows
/// 4) Root Back interception minimizing the app via MethodChannel instead of closing it (while yielding to Search focus/query)
library;

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/database/app_database.dart';
import 'package:project_anima/core/database/dao/favorite_songs_dao.dart';
import 'package:project_anima/core/database/dao/pinned_favorites_dao.dart';
import 'package:project_anima/core/database/dao/song_dao.dart';
import 'package:project_anima/core/database/models/pinned_favorite.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/navigation/app_route_tracker.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/core/playback/audio_handler.dart';
import 'package:project_anima/features/search/screens/search.dart';

class _FakeHandlerAudioPlayer implements AudioPlayer {
  final _playbackEventController = StreamController<PlaybackEvent>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();

  bool _playing = false;
  ProcessingState _processingState = ProcessingState.loading;
  Duration _position = Duration.zero;
  PlaybackEvent _lastEvent = PlaybackEvent();

  @override
  Stream<PlaybackEvent> get playbackEventStream => _playbackEventController.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  PlaybackEvent get playbackEvent => _lastEvent;

  @override
  bool get playing => _playing;

  @override
  ProcessingState get processingState => _processingState;

  @override
  Duration get position => _position;

  @override
  Duration get bufferedPosition => Duration.zero;

  @override
  double get speed => 1.0;

  void emitDuration(Duration? duration) {
    _durationController.add(duration);
  }

  void setState({
    bool? playing,
    ProcessingState? processingState,
    Duration? position,
  }) {
    if (playing != null) _playing = playing;
    if (processingState != null) _processingState = processingState;
    if (position != null) _position = position;
    _lastEvent = PlaybackEvent(processingState: _processingState);
    _playbackEventController.add(_lastEvent);
    _playerStateController.add(PlayerState(_playing, _processingState));
  }

  @override
  Future<void> play() async {
    setState(playing: true, processingState: ProcessingState.ready);
  }

  @override
  Future<void> pause() async {
    setState(playing: false);
  }

  @override
  Future<void> seek(Duration? position, {int? index}) async {
    _position = position ?? Duration.zero;
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _processingState = ProcessingState.idle;
  }

  @override
  Future<void> dispose() async {
    await _playbackEventController.close();
    await _playerStateController.close();
    await _durationController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppDatabase.initializeFfiIfNeeded();
  });

  group('Space Orphaned Pins Pruning Tests', () {
    late Directory tempDbDir;
    late AppDatabase appDb;
    late SongDao songDao;

    setUp(() async {
      tempDbDir = await Directory.systemTemp.createTemp('space_prune_test_');
      appDb = AppDatabase.instance;
      await appDb.initDatabase(customPath: p.join(tempDbDir.path, 'space_prune.db'));
      await PinnedFavoritesDao.instance.clearAll();
      await FavoriteSongsDao.instance.refreshCache();
      songDao = SongDao(appDatabase: appDb);
    });

    tearDown(() async {
      await appDb.close();
      if (tempDbDir.existsSync()) {
        tempDbDir.deleteSync(recursive: true);
      }
    });

    test('syncDelta prunes deleted albums, artists, and orphaned playlists from Space while preserving active ones', () async {
      final albumOneSong = Song(
        mediaStoreId: 101,
        title: 'Keep Track',
        artist: 'Artist Alpha',
        album: 'Album One',
        albumId: 10,
        duration: 180000,
        path: '/music/alpha_keep.mp3',
        dateModified: 1700000000,
      );
      final albumTwoSong = Song(
        mediaStoreId: 202,
        title: 'Deleted Track',
        artist: 'Artist Beta',
        album: 'Album Two',
        albumId: 20,
        duration: 200000,
        path: '/music/beta_deleted.mp3',
        dateModified: 1700000001,
      );

      await songDao.syncDelta(
        toInsertOrUpdate: [albumOneSong, albumTwoSong],
        toDelete: const [],
      );

      final pins = PinnedFavoritesDao.instance;
      final now = DateTime.now();

      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.album,
          itemKey: PinnedFavoritesDao.albumKey('Album One', 'Artist Alpha'),
          title: 'Album One',
          subtitle: 'Artist Alpha',
          albumId: 10,
          representativeSongId: 101,
          pinnedAt: now,
        ),
      );
      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.album,
          itemKey: PinnedFavoritesDao.albumKey('Album Two', 'Artist Beta'),
          title: 'Album Two',
          subtitle: 'Artist Beta',
          albumId: 20,
          representativeSongId: 202,
          pinnedAt: now,
        ),
      );
      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.artist,
          itemKey: PinnedFavoritesDao.artistKey('Artist Alpha'),
          title: 'Artist Alpha',
          representativeSongId: 101,
          pinnedAt: now,
        ),
      );
      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.artist,
          itemKey: PinnedFavoritesDao.artistKey('Artist Beta'),
          title: 'Artist Beta',
          representativeSongId: 202,
          pinnedAt: now,
        ),
      );
      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.playlist,
          itemKey: PinnedFavoritesDao.playlistKey(999),
          title: 'Missing Playlist',
          playlistId: 999,
          pinnedAt: now,
        ),
      );

      final revBefore = PinnedFavoritesDao.revision.value;

      // Simulate storage deletion of Artist Beta / Album Two song
      await songDao.syncDelta(
        toInsertOrUpdate: const [],
        toDelete: const [202],
      );

      expect(PinnedFavoritesDao.revision.value, greaterThan(revBefore));
      final remaining = await pins.getAllPinned();
      final keys = remaining.map((e) => e.itemKey).toSet();

      expect(keys, contains(PinnedFavoritesDao.albumKey('Album One', 'Artist Alpha')));
      expect(keys, contains(PinnedFavoritesDao.artistKey('Artist Alpha')));
      expect(keys, isNot(contains(PinnedFavoritesDao.albumKey('Album Two', 'Artist Beta'))));
      expect(keys, isNot(contains(PinnedFavoritesDao.artistKey('Artist Beta'))));
      expect(keys, isNot(contains(PinnedFavoritesDao.playlistKey(999))));
    });

    test('deleteSong and pruneOrphanedPins clean up Space tiles even when triggered individually', () async {
      final track = Song(
        mediaStoreId: 303,
        title: 'Solo Track',
        artist: 'Solo Artist',
        album: 'Solo Album',
        albumId: 30,
        duration: 210000,
        path: '/music/solo.mp3',
        dateModified: 1700000002,
      );
      await songDao.syncDelta(toInsertOrUpdate: [track], toDelete: const []);

      final pins = PinnedFavoritesDao.instance;
      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.album,
          itemKey: PinnedFavoritesDao.albumKey('Solo Album', 'Solo Artist'),
          title: 'Solo Album',
          subtitle: 'Solo Artist',
          albumId: 30,
          representativeSongId: 303,
          pinnedAt: DateTime.now(),
        ),
      );

      // Delete the only track of Solo Album individually
      await songDao.deleteSong(303);
      expect(await pins.getAllPinned(), isEmpty);

      // Also verify direct pruneOrphanedPins clears pre-existing orphan rows when delta == 0
      await pins.togglePin(
        PinnedFavorite(
          itemType: PinnedItemType.artist,
          itemKey: PinnedFavoritesDao.artistKey('Ghost Artist'),
          title: 'Ghost Artist',
          pinnedAt: DateTime.now(),
        ),
      );
      final removed = await pins.pruneOrphanedPins();
      expect(removed, equals(1));
      expect(await pins.getAllPinned(), isEmpty);
    });
  });

  group('AnimaAudioHandler Media Notification Metadata Refresh Tests', () {
    late _FakeHandlerAudioPlayer fakePlayer;
    late AnimaAudioHandler handler;

    setUp(() {
      fakePlayer = _FakeHandlerAudioPlayer();
      handler = AnimaAudioHandler(
        fakePlayer,
        onSkipToNext: () async {},
        onSkipToPrevious: () async {},
      );
    });

    tearDown(() async {
      await handler.stop();
      await fakePlayer.dispose();
    });

    test('updateMetadata refreshes mediaItem, queue, and playing playbackState immediately on track transition', () async {
      const item1 = MediaItem(
        id: '101_0',
        title: 'First Track',
        artist: 'First Artist',
        album: 'First Album',
        duration: Duration(minutes: 3),
      );

      // Simulate just_audio still in loading/not-yet-playing state when skip is pressed
      handler.updateMetadata(item1, forcePlaying: true);
      await Future<void>.delayed(Duration.zero);

      expect(handler.mediaItem.value?.id, equals('101_0'));
      expect(handler.mediaItem.value?.title, equals('First Track'));
      expect(handler.queue.value.map((m) => m.id).toList(), equals(['101_0']));
      expect(handler.playbackState.value.playing, isTrue);
      expect(handler.playbackState.value.processingState, equals(AudioProcessingState.ready));
      expect(handler.playbackState.value.queueIndex, equals(0));

      const item2 = MediaItem(
        id: '202_1',
        title: 'Second Track',
        artist: 'Second Artist',
        album: 'Second Album',
        duration: Duration(minutes: 4),
      );
      handler.updateMetadata(item2, forcePlaying: true);
      await Future<void>.delayed(const Duration(milliseconds: 110));

      expect(handler.mediaItem.value?.id, equals('202_1'));
      expect(handler.mediaItem.value?.title, equals('Second Track'));
      expect(handler.queue.value.map((m) => m.id).toList(), equals(['202_1']));

      // Duration resolved asynchronously by player updates active MediaItem & queue
      fakePlayer.emitDuration(const Duration(minutes: 4, seconds: 12));
      await Future<void>.delayed(Duration.zero);

      expect(handler.mediaItem.value?.duration, equals(const Duration(minutes: 4, seconds: 12)));
      expect(handler.queue.value.first.duration, equals(const Duration(minutes: 4, seconds: 12)));
    });
  });

  group('AppRouteTracker Back Stack Deduplication Tests', () {
    setUp(() {
      AppRouteTracker.instance.reset();
    });

    Route<void> namedTestRoute(String routeName, String label) {
      return PageRouteBuilder<void>(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, _, _) => Scaffold(body: Center(child: Text(label))),
      );
    }

    testWidgets('deduplicates repeated Player -> Album -> Artist -> Player -> Artist sequence', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [AppRouteTracker.instance],
          home: const Scaffold(body: Center(child: Text('HomeRoot'))),
        ),
      );
      await tester.pumpAndSettle();

      final nav = navKey.currentState!;
      nav.push(namedTestRoute(AppRouteTracker.playerRouteName, 'PlayerView'));
      await tester.pumpAndSettle();

      nav.push(namedTestRoute(AppRouteTracker.albumRouteName('Discovery', 'Daft Punk'), 'AlbumDiscovery'));
      await tester.pumpAndSettle();

      nav.push(namedTestRoute(AppRouteTracker.artistRouteName('Daft Punk'), 'ArtistDaftPunk'));
      await tester.pumpAndSettle();

      nav.push(namedTestRoute(AppRouteTracker.playerRouteName, 'PlayerView'));
      await tester.pumpAndSettle();
      expect(AmbientParticlesController.instance.isExpandedPlayerVisible, isTrue);

      nav.push(namedTestRoute(AppRouteTracker.artistRouteName('Daft Punk'), 'ArtistDaftPunk'));
      await tester.pumpAndSettle();
      // Pushing Artist/Album from PlayerScreen unfreezes menu particles
      expect(AmbientParticlesController.instance.isExpandedPlayerVisible, isFalse);

      // Deduplicated stack from bottom to top:
      // ['/', album(discovery::daft punk), player, artist(daft punk)]
      expect(
        AppRouteTracker.instance.routeNames,
        equals([
          '/',
          AppRouteTracker.albumRouteName('Discovery', 'Daft Punk'),
          AppRouteTracker.playerRouteName,
          AppRouteTracker.artistRouteName('Daft Punk'),
        ]),
      );

      // Stepping backward visits each unique menu at most once
      expect(find.text('ArtistDaftPunk'), findsOneWidget);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('PlayerView'), findsOneWidget);
      expect(AmbientParticlesController.instance.isExpandedPlayerVisible, isTrue);

      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('AlbumDiscovery'), findsOneWidget);
      expect(AmbientParticlesController.instance.isExpandedPlayerVisible, isFalse);

      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('HomeRoot'), findsOneWidget);
    });
  });

  group('Root Back Button Background Minimize Tests', () {
    const channel = MethodChannel('project_anima/system_dimensions');
    final List<String> invokedMethods = [];
    late Directory tempDbDir;

    setUp(() async {
      invokedMethods.clear();
      tempDbDir = await Directory.systemTemp.createTemp('back_minimize_test_');
      await AppDatabase.instance.initDatabase(customPath: p.join(tempDbDir.path, 'back_min.db'));
      NavigationController.instance.reset();
      MenuTransitionController.instance.reset();
      AppRouteTracker.instance.reset();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        invokedMethods.add(call.method);
        if (call.method == 'moveToBackground') {
          return true;
        }
        return null;
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      NavigationController.instance.reset();
      MenuTransitionController.instance.reset();
      await AppDatabase.instance.close();
      if (tempDbDir.existsSync()) {
        tempDbDir.deleteSync(recursive: true);
      }
    });

    testWidgets('pressing back at root moves app to background instead of exiting, while yielding when Search has focus or query', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [AppRouteTracker.instance],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MenuTransitionControl(includeBottomNav: true),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));

      invokedMethods.clear();

      // 1. At root Space screen, system back moves app to background
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(invokedMethods, contains('moveToBackground'));
      invokedMethods.clear();

      // 2. With a pushed modal screen open, system back pops the screen and does NOT background the app
      navKey.currentState!.push(
        PageRouteBuilder<void>(
          settings: const RouteSettings(name: AppRouteTracker.playerRouteName),
          pageBuilder: (_, _, _) => const Scaffold(body: Center(child: Text('ModalPlayer'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ModalPlayer'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('ModalPlayer'), findsNothing);
      expect(invokedMethods, isNot(contains('moveToBackground')));

      // 3. On active Search tab with focused input / query, Search consumes Back and app stays in foreground
      NavigationController.instance.handleDestinationSelected(null, NavigationTab.search.index);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final searchField = find.descendant(
        of: find.byType(SearchScreen),
        matching: find.byType(TextField),
      );
      await tester.tap(searchField);
      await tester.pump();
      await tester.enterText(searchField, 'Daft');
      await tester.pump();

      // First back unfocuses keyboard (Search intercepts)
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(invokedMethods, isNot(contains('moveToBackground')));

      // Second back clears Search query (Search intercepts)
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(invokedMethods, isNot(contains('moveToBackground')));

      // Third back with unfocused empty Search sends app to background
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(invokedMethods, contains('moveToBackground'));

      // Allow any sqflite isolate queries triggered on tab switch to complete cleanly before teardown closes DB
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
