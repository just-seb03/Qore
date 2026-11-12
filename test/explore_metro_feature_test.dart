/// File: explore_metro_feature_test.dart
/// Description: Comprehensive widget and unit tests for the Windows Phone Metro Explore screen,
/// validating authentic Metro design (sharp 90-degree corners, zero drop shadows, square artist profile tiles,
/// capitalized section headers, wide Daily Mix tile, and recent songs tracklist) with ambient particles simulation.
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
    testWidgets('ExploreScreen integrates AmbientParticlesCanvas backdrop and ExploreMetroView without category overline',
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

      // 2. ExploreHeader with prominent Segoe UI Light typography is mounted (no MÚSICA overline)
      expect(find.byType(ExploreHeader), findsOneWidget);
      expect(find.text('MÚSICA'), findsNothing);
      expect(find.text('Explorar'), findsOneWidget);

      // 3. Discovery view with backward-compatible key is mounted
      expect(find.byKey(const ValueKey('explore_discovery_view')), findsOneWidget);
    });

    testWidgets('ExploreMetroTile features sharp 90-degree corners, zero drop shadows, and wide solid mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320.0,
                child: ExploreMetroTile(
                  title: 'Daily Mix',
                  subtitle: '24 canciones',
                  icon: Icons.today_rounded,
                  isSolid: true,
                  aspectRatio: 2.3,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check title and subtitle in Segoe UI
      expect(find.text('Daily Mix'), findsOneWidget);
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

    testWidgets('ExploreMetroArtistTile enforces artist profile rendering without album covers',
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
      // Renders person profile silhouette icon instead of album cover
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

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

    testWidgets('ExploreMetroView renders Daily Mix wide tile, albums, artists, and Recientes tracklist',
        (tester) async {
      AlbumDiscoveryItem? tappedAlbum;
      ArtistDiscoveryItem? tappedArtist;
      Song? tappedSong;

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
              onSongTap: (s) => tappedSong = s,
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. Featured Section: 1 wide Daily Mix tile (no Recientes in featured)
      expect(find.byType(ExploreMetroTile), findsOneWidget);
      expect(find.text('Daily Mix'), findsOneWidget);
      expect(find.text('Destacadas'), findsOneWidget);

      // 2. Metro Album Tile
      expect(find.text('Nuevos álbumes'), findsOneWidget);
      expect(find.byType(ExploreMetroAlbumTile), findsOneWidget);
      expect(find.text('Metro Album 1'), findsOneWidget);

      // 3. Metro Artist Tile
      expect(find.text('Artistas nuevos'), findsOneWidget);
      expect(find.byType(ExploreMetroArtistTile), findsOneWidget);

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

      // 4. Recientes Section: 10 recently played songs under artists
      await tester.ensureVisible(find.byType(ExploreMetroTrackTile));
      await tester.pumpAndSettle();
      expect(find.text('Recientes'), findsOneWidget);
      expect(find.byType(ExploreMetroTrackTile), findsOneWidget);
      expect(find.text('Metro Track 2'), findsOneWidget);

      // Tap recent track
      await tester.tap(find.byType(ExploreMetroTrackTile));
      await tester.pump();
      expect(tappedSong?.title, 'Metro Track 2');
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
      expect(find.byType(ExploreMetroTrackTile), findsNothing);
    });
  });
}
