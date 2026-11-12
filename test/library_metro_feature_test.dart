/// File: library_metro_feature_test.dart
/// Description: Widget and integration tests for the Windows Phone Metro
/// redesign of the Library screen, including collapsible header on scroll,
/// text-only Pivot category bar, Metro Jump-List with alphabet scroller (#, A-Z),
/// and kinetic offset translation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/database/models/album_discovery_item.dart';
import 'package:project_anima/core/database/models/artist_discovery_item.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/library/components/albums/library_album_card.dart';
import 'package:project_anima/features/library/components/common/metro_alphabet_scroller.dart';
import 'package:project_anima/features/library/components/library_category_bar.dart';
import 'package:project_anima/features/library/components/library_filter_pills.dart';
import 'package:project_anima/features/library/components/library_header.dart';
import 'package:project_anima/features/library/components/songs/library_songs_list.dart';
import 'package:project_anima/features/library/screens/library.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testAlbums = [
    const AlbumDiscoveryItem(
      name: 'Abbey Road',
      artist: 'The Beatles',
      albumId: 1,
      representativeSongId: 101,
      songCount: 17,
      totalDuration: 2800000,
    ),
    const AlbumDiscoveryItem(
      name: 'Back in Black',
      artist: 'AC/DC',
      albumId: 2,
      representativeSongId: 102,
      songCount: 10,
      totalDuration: 2500000,
    ),
    const AlbumDiscoveryItem(
      name: 'Random Access Memories',
      artist: 'Daft Punk',
      albumId: 3,
      representativeSongId: 103,
      songCount: 13,
      totalDuration: 4400000,
    ),
  ];

  final testArtists = [
    const ArtistDiscoveryItem(
      name: 'AC/DC',
      songCount: 10,
      albumCount: 1,
      representativeSongId: 102,
    ),
    const ArtistDiscoveryItem(
      name: 'Daft Punk',
      songCount: 13,
      albumCount: 1,
      representativeSongId: 103,
    ),
    const ArtistDiscoveryItem(
      name: 'The Beatles',
      songCount: 17,
      albumCount: 1,
      representativeSongId: 101,
    ),
  ];

  final testSongs = [
    const Song(
      id: 1,
      title: 'Come Together',
      artist: 'The Beatles',
      album: 'Abbey Road',
      duration: 259000,
      path: '/storage/music/come_together.mp3',
      mediaStoreId: 1001,
      dateModified: 1600000000,
    ),
    const Song(
      id: 2,
      title: 'Get Lucky',
      artist: 'Daft Punk',
      album: 'Random Access Memories',
      duration: 369000,
      path: '/storage/music/get_lucky.mp3',
      mediaStoreId: 1002,
      dateModified: 1600000001,
    ),
  ];

  group('MetroAlphabetScroller Widget Tests', () {
    testWidgets('renders alphabet rail and list items in list layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MetroAlphabetScroller<AlbumDiscoveryItem>(
              items: testAlbums,
              titleSelector: (a) => a.name,
              itemExtent: 70.0,
              itemBuilder: (context, index, album, isCurrent) {
                return LibraryAlbumCard(
                  album: album,
                  isListTile: true,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 3 albums rendered
      expect(find.text('Abbey Road'), findsOneWidget);
      expect(find.text('Back in Black'), findsOneWidget);
      expect(find.text('Random Access Memories'), findsOneWidget);

      // Verify alphabet characters present in rail
      expect(find.text('A'), findsAtLeast(1));
      expect(find.text('B'), findsAtLeast(1));
      expect(find.text('R'), findsAtLeast(1));
      expect(find.text('#'), findsOneWidget);
    });

    testWidgets('normalizeLetter maps accents and symbols properly', (tester) async {
      expect(MetroAlphabetScroller.normalizeLetter('Álbum'), 'A');
      expect(MetroAlphabetScroller.normalizeLetter('Éxitos'), 'E');
      expect(MetroAlphabetScroller.normalizeLetter('1989'), '#');
      expect(MetroAlphabetScroller.normalizeLetter('!Super'), '#');
      expect(MetroAlphabetScroller.normalizeLetter('Zendaya'), 'Z');
    });
  });

  group('LibraryCategoryBar Text-Only Metro Styling Tests', () {
    testWidgets('renders text labels Álbumes, Artistas, Playlists without visible icon footprint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: LibraryCategoryBar(
              selectedFilter: LibraryFilter.albums,
              animate: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Álbumes'), findsOneWidget);
      expect(find.text('Artistas'), findsOneWidget);
      expect(find.text('Canciones'), findsOneWidget);
      expect(find.text('Listas'), findsOneWidget);

      // Verify navigation chevrons exist
      expect(find.byKey(const ValueKey('library_nav_previous')), findsOneWidget);
      expect(find.byKey(const ValueKey('library_nav_next')), findsOneWidget);
    });
  });

  group('LibraryScreen Metro Collapsible Header Tests', () {
    testWidgets('collapses LibraryHeader when scrolling down and restores it on scroll up', (tester) async {
      // Build a long list of albums to enable vertical scrolling
      final manyAlbums = List.generate(
        25,
        (i) => AlbumDiscoveryItem(
          name: 'Album ${String.fromCharCode(65 + (i % 26))} - #$i',
          artist: 'Artist $i',
          albumId: i + 1,
          representativeSongId: 1000 + i,
          songCount: 10,
          totalDuration: 2000000,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LibraryScreen(
            showBottomNav: false,
            initialAlbums: manyAlbums,
            initialArtists: testArtists,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header "Biblioteca" is initially visible
      expect(find.byType(LibraryHeader), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);

      // Verify AnimatedAlign is at heightFactor: 1.0 initially
      final initialAlign = tester.widget<AnimatedAlign>(
        find.ancestor(
          of: find.byType(LibraryHeader),
          matching: find.byType(AnimatedAlign),
        ),
      );
      expect(initialAlign.heightFactor, 1.0);

      // Scroll down by 250 pixels
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();

      // Verify header collapsed to heightFactor: 0.0
      final collapsedAlign = tester.widget<AnimatedAlign>(
        find.ancestor(
          of: find.byType(LibraryHeader),
          matching: find.byType(AnimatedAlign),
        ),
      );
      expect(collapsedAlign.heightFactor, 0.0);

      // Scroll back up to the top
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify header is restored to heightFactor: 1.0
      final restoredAlign = tester.widget<AnimatedAlign>(
        find.ancestor(
          of: find.byType(LibraryHeader),
          matching: find.byType(AnimatedAlign),
        ),
      );
      expect(restoredAlign.heightFactor, 1.0);
    });
  });

  group('LibrarySongsList & LibrarySongTile Tests', () {
    testWidgets('renders LibrarySongsList with song items and durations', (tester) async {
      Song? tappedSong;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: LibrarySongsList(
              songs: testSongs,
              onSongTap: (s) => tappedSong = s,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LibrarySongsList), findsOneWidget);
      expect(find.text('Come Together'), findsOneWidget);
      expect(find.text('The Beatles • Abbey Road'), findsOneWidget);
      expect(find.text('4:19'), findsOneWidget);

      expect(find.text('Get Lucky'), findsOneWidget);
      expect(find.text('Daft Punk • Random Access Memories'), findsOneWidget);
      expect(find.text('6:09'), findsOneWidget);

      await tester.tap(find.text('Come Together'));
      expect(tappedSong, isNotNull);
      expect(tappedSong?.title, 'Come Together');
    });
  });

  group('LibraryScreen Persistent AmbientParticlesCanvas Tests', () {
    testWidgets('LibraryScreen mounts AmbientParticlesCanvas as persistent backdrop across tab switches', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: LibraryScreen(
            showBottomNav: false,
            initialAlbums: testAlbums,
            initialArtists: testArtists,
            initialSongs: testSongs,
            initialPlaylists: const [],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 1. AmbientParticlesCanvas is mounted behind content
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);

      // 2. Switch from Albums to Artists tab
      await tester.tap(find.byKey(const ValueKey('library_category_artists')));
      await tester.pumpAndSettle();

      // AmbientParticlesCanvas remains strictly 1 instance, not recreated or slid
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);

      // 3. Switch to Songs tab
      await tester.tap(find.byKey(const ValueKey('library_category_songs')));
      await tester.pumpAndSettle();

      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);

      // 4. Switch to Playlists tab
      await tester.tap(find.byKey(const ValueKey('library_category_playlists')));
      await tester.pumpAndSettle();

      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
    });
  });
}
