/// File: explore_metro_feature_test.dart
/// Description: Comprehensive widget and unit tests for the Windows Phone Metro Explore screen,
/// validating authentic Metro design (sharp 90-degree corners, zero drop shadows, square artist tiles,
/// Segoe UI Light pivot typography) and ambient particles simulation backdrop integration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/explore/explore.dart';

void main() {
  const testDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  final testSong1 = Song(
    id: 1,
    mediaStoreId: 101,
    title: 'Metro Track 1',
    artist: 'Metro Artist 1',
    album: 'Metro Album 1',
    path: '/music/track1.mp3',
    duration: 180000,
    dateAdded: 1000,
    dateModified: 1000,
  );

  final testSong2 = Song(
    id: 2,
    mediaStoreId: 102,
    title: 'Metro Track 2',
    artist: 'Metro Artist 2',
    album: 'Metro Album 2',
    path: '/music/track2.mp3',
    duration: 210000,
    dateAdded: 1100,
    dateModified: 1100,
  );

  const testAlbum = AlbumDiscoveryItem(
    name: 'Metro Album 1',
    artist: 'Metro Artist 1',
    albumId: 1,
    representativeSongId: 101,
    songCount: 8,
    totalDuration: 1440000,
  );

  const testArtist = ArtistDiscoveryItem(
    name: 'Metro Artist 1',
    songCount: 8,
    albumCount: 1,
    representativeSongId: 101,
  );

  group('Windows Phone Metro Explore UI Widget Tests', () {
    testWidgets('ExploreScreen integrates AmbientParticlesCanvas backdrop and ExploreMetroView',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: ExploreScreen(showBottomNav: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 1. Ambient particles simulation backdrop is mounted
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);

      // 2. ExploreHeader with Metro pivot typography is mounted
      expect(find.byType(ExploreHeader), findsOneWidget);
      expect(find.text('MÚSICA'), findsOneWidget);
      expect(find.text('explorar'), findsOneWidget);

      // 3. Discovery view with backward-compatible key is mounted
      expect(find.byKey(const ValueKey('explore_discovery_view')), findsOneWidget);
    });

    testWidgets('ExploreMetroTile features sharp 90-degree corners and zero drop shadows',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 160.0,
                height: 160.0,
                child: ExploreMetroTile(
                  title: 'Today Selection',
                  subtitle: '24 canciones',
                  songs: [testSong1, testSong2],
                  icon: Icons.today_rounded,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check title and subtitle in Segoe UI
      expect(find.text('Today Selection'), findsOneWidget);
      expect(find.text('24 canciones'), findsOneWidget);
      expect(find.byIcon(Icons.today_rounded), findsOneWidget);

      // Authentic Metro verification: Zero border radius, zero drop shadows
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ExploreMetroTile),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.zero);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('ExploreMetroAlbumTile renders with sharp square corners and zero drop shadows',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            body: Center(
              child: ExploreMetroAlbumTile(
                album: testAlbum,
                size: 135.0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Metro Album 1'), findsOneWidget);
      expect(find.text('Metro Artist 1'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ExploreMetroAlbumTile),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.zero);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('ExploreMetroArtistTile enforces "People tiles are square" (no circles, zero shadows)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            body: Center(
              child: ExploreMetroArtistTile(
                artist: testArtist,
                size: 135.0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Metro Artist 1'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ExploreMetroArtistTile),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.zero);
      expect(decoration.boxShadow, isNull);
      expect(decoration.shape, BoxShape.rectangle);
    });

    testWidgets('ExploreMetroView renders featured live tiles, newest albums, and artist tiles',
        (tester) async {
      AlbumDiscoveryItem? tappedAlbum;
      ArtistDiscoveryItem? tappedArtist;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: ExploreMetroView(
              initialSongCount: 10,
              initialAlbums: const [testAlbum],
              initialArtists: const [testArtist],
              initialTodaySongs: [testSong1],
              initialRecentSongs: [testSong2],
              onAlbumTap: (a) => tappedAlbum = a,
              onArtistTap: (ar) => tappedArtist = ar,
            ),
          ),
        ),
      );
      await tester.pump();

      // Featured Live Tiles
      expect(find.byType(ExploreMetroTile), findsNWidgets(2));
      expect(find.text('Today Selection'), findsOneWidget);
      expect(find.text('Recientes'), findsOneWidget);

      // Metro Album Tile
      expect(find.byType(ExploreMetroAlbumTile), findsOneWidget);
      expect(find.text('Metro Album 1'), findsOneWidget);

      // Metro Artist Tile
      expect(find.byType(ExploreMetroArtistTile), findsOneWidget);
      expect(find.text('Metro Artist 1'), findsNWidgets(2)); // in album and in artist

      // Tap album
      await tester.tap(find.byType(ExploreMetroAlbumTile));
      await tester.pump();
      expect(tappedAlbum?.name, 'Metro Album 1');

      // Scroll to artist tile and tap
      await tester.ensureVisible(find.byType(ExploreMetroArtistTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExploreMetroArtistTile));
      await tester.pump();
      expect(tappedArtist?.name, 'Metro Artist 1');
    });

    testWidgets('ExploreMetroView returns SizedBox.shrink when song count is 0',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            body: ExploreMetroView(
              initialSongCount: 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ExploreMetroTile), findsNothing);
      expect(find.byType(ExploreMetroAlbumTile), findsNothing);
      expect(find.byType(ExploreMetroArtistTile), findsNothing);
    });
  });
}
