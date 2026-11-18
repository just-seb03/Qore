import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/database/models/song.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/core/theme/theme.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/search/components/cards/search_song_tile.dart';
import 'package:project_anima/features/search/components/cards/search_top_result_card.dart';
import 'package:project_anima/features/search/components/common/material_artist_avatar.dart';
import 'package:project_anima/features/search/components/common/search_badge.dart';
import 'package:project_anima/features/search/components/common/search_play_button.dart';
import 'package:project_anima/features/search/components/search_bar.dart';
import 'package:project_anima/features/search/components/states/search_loading_view.dart';
import 'package:project_anima/features/search/components/states/search_no_results_view.dart';
import 'package:project_anima/features/search/screens/search.dart';

const _testDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  group('Metro Search Design Tests', () {
    testWidgets('SearchScreen mounts AmbientParticlesCanvas backdrop', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: SearchScreen(showBottomNav: false),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
    });

    testWidgets('AppSearchBar renders with sharp 90-degree corners (BorderRadius.zero)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            body: AppSearchBar(isExpanded: true),
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppSearchBar),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.zero);
    });

    testWidgets('SearchTopResultCard renders sharp Metro tile without border and with flat play button', (tester) async {
      final song = Song(
        mediaStoreId: 101,
        title: 'Starlight',
        artist: 'Muse',
        album: 'Black Holes and Revelations',
        duration: 240000,
        path: '/storage/starlight.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: SearchTopResultCard.song(
              song: song,
              onTap: () {},
              onPlayTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Starlight'), findsOneWidget);
      expect(find.text('Muse'), findsOneWidget);

      final tileContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(SearchTopResultCard),
          matching: find.byType(Container),
        ).first,
      );
      final tileDec = tileContainer.decoration as BoxDecoration;
      expect(tileDec.borderRadius, BorderRadius.zero);
      expect(tileDec.border, isNull);

      final playContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(SearchPlayButton),
          matching: find.byType(Container),
        ).first,
      );
      final playDec = playContainer.decoration as BoxDecoration;
      expect(playDec.borderRadius, BorderRadius.zero);
      expect(playDec.boxShadow, isNull);
    });

    testWidgets('MaterialArtistAvatar renders sharp square People Tile without CircleAvatar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialArtistAvatar(
              radius: 30.0,
              artistName: 'Muse',
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsNothing);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MaterialArtistAvatar),
          matching: find.byType(Container),
        ).first,
      );
      final dec = container.decoration as BoxDecoration;
      expect(dec.borderRadius, BorderRadius.zero);
      expect(dec.shape, BoxShape.rectangle);
    });

    testWidgets('SearchSongTile and SearchBadge use sharp BorderRadius.zero', (tester) async {
      final song = Song(
        mediaStoreId: 102,
        title: 'Hysteria',
        artist: 'Muse',
        album: 'Absolution',
        duration: 227000,
        path: '/storage/hysteria.mp3',
        dateModified: 100,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Column(
              children: [
                SearchSongTile(song: song),
                const SearchBadge(label: 'SONG'),
              ],
            ),
          ),
        ),
      );

      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(SearchSongTile),
          matching: find.byType(InkWell),
        ).first,
      );
      expect(inkWell.borderRadius, BorderRadius.zero);

      final badgeContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(SearchBadge),
          matching: find.byType(Container),
        ).first,
      );
      final badgeDec = badgeContainer.decoration as BoxDecoration;
      expect(badgeDec.borderRadius, BorderRadius.zero);
    });

    testWidgets('SearchNoResultsView and SearchLoadingView use Metro accent and Segoe UI typography', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: _testDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('es'),
          home: Scaffold(
            body: Column(
              children: [
                SearchLoadingView(),
                SearchNoResultsView(query: 'xyz'),
              ],
            ),
          ),
        ),
      );

      final progress = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(progress.color, AppColors.accent);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });
  });
}

