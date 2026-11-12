/// File: space_and_navigation_update_test.dart
/// Description: Comprehensive test suite validating the Space screen migration,
/// Search tab startup default, heart iconography, and exclusive ambient particle scoping.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_anima/components/bottom_nav.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/core/localization/app_localizations.dart';
import 'package:project_anima/features/ambient_particles/ambient_particles.dart';
import 'package:project_anima/features/explore/screens/explore.dart';
import 'package:project_anima/features/home/components/space_header.dart';
import 'package:project_anima/features/home/components/space_tiles_grid.dart';
import 'package:project_anima/features/home/screens/home.dart';
import 'package:project_anima/features/library/components/library_header.dart';
import 'package:project_anima/features/library/screens/library.dart';
import 'package:project_anima/features/profile/screens/profile.dart';
import 'package:project_anima/features/search/components/search_header.dart';
import 'package:project_anima/features/search/screens/search.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    NavigationController.instance.reset();
    MenuTransitionController.instance.reset();
  });

  group('SpaceHeader Typography & Alignment Tests', () {
    testWidgets('SpaceHeader matches exact font, size, and layout of LibraryHeader and SearchHeader',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Column(
              children: [
                SpaceHeader(),
                SearchHeader(),
                LibraryHeader(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final spaceTextFinder = find.text('Space');
      final searchTextFinder = find.text('Search');
      final libraryTextFinder = find.text('Library');

      expect(spaceTextFinder, findsOneWidget);
      expect(searchTextFinder, findsOneWidget);
      expect(libraryTextFinder, findsOneWidget);

      final Text spaceText = tester.widget(spaceTextFinder);
      final Text searchText = tester.widget(searchTextFinder);
      final Text libraryText = tester.widget(libraryTextFinder);

      expect(spaceText.textAlign, TextAlign.center);
      expect(searchText.textAlign, TextAlign.center);
      expect(libraryText.textAlign, TextAlign.center);

      expect(spaceText.style?.fontSize, equals(24.0));
      expect(spaceText.style?.fontWeight, equals(FontWeight.w300));
      expect(spaceText.style?.letterSpacing, equals(1.5));

      expect(searchText.style?.fontSize, equals(24.0));
      expect(searchText.style?.fontWeight, equals(FontWeight.w300));
      expect(searchText.style?.letterSpacing, equals(1.5));

      expect(libraryText.style?.fontSize, equals(24.0));
      expect(libraryText.style?.fontWeight, equals(FontWeight.w300));
      expect(libraryText.style?.letterSpacing, equals(1.5));
    });
  });

  group('HomeScreen (Space) Isolation Tests', () {
    testWidgets('HomeScreen renders with SpaceTilesGrid and AmbientParticlesCanvas',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomeScreen(
            showBottomNav: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SpaceTilesGrid), findsOneWidget);
      expect(find.byType(AmbientParticlesCanvas), findsOneWidget);
      expect(find.byType(SpaceHeader), findsNothing);

      // Verify absence of legacy content
      expect(find.text('WELCOME'), findsNothing);
      expect(find.text('Today Selection'), findsNothing);
      expect(find.text('Favoritos'), findsNothing);
      expect(find.text('Favorites'), findsNothing);
      expect(find.text('PINNED FAVORITES'), findsNothing);
    });

    testWidgets('SearchScreen and LibraryScreen do not contain AmbientParticlesCanvas',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: SearchScreen(showBottomNav: false)),
                Expanded(child: LibraryScreen(showBottomNav: false)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AmbientParticlesCanvas), findsNothing);
    });
  });

  group('AppBottomNav Heart Icon and Space Naming Tests', () {
    testWidgets('AppBottomNav renders native heart icon and Space label in English and Spanish',
        (tester) async {
      // English test
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: 1,
              showMiniPlayer: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);

      // Spanish test
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: 2,
              showMiniPlayer: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Space" remains "Space" in Spanish as requested
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Inicio'), findsNothing);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });

  group('Startup Destination to Space Screen Tests', () {
    test('NavigationController and MenuTransitionController default to index 2 (Space)', () {
      expect(NavigationController.instance.currentIndex, equals(2));
      expect(MenuTransitionController.instance.currentIndex, equals(2));
    });

    testWidgets('MenuTransitionControl mounts with Space (HomeScreen) active by default',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MenuTransitionControl(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // MenuTransitionControl should show HomeScreen (Space) with SpaceTilesGrid and Space bottom nav tab
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SpaceTilesGrid), findsOneWidget);
      expect(find.text('Space'), findsOneWidget); // Bottom nav tab
    });
  });

  group('Five-Tab Bottom Navigation Tests', () {
    testWidgets('AppBottomNav renders 5 tabs in exact order with Spanish localization',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: 0,
              showMiniPlayer: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 5 tabs present
      expect(find.text('Explorar'), findsOneWidget);
      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Space'), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // Verify exploration and profile icons
      expect(find.byIcon(Icons.explore_rounded), findsOneWidget); // Active explore
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget); // Inactive profile
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget); // Inactive space
    });

    testWidgets('AppBottomNav renders active profile icon when index is 4',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: 4,
              showMiniPlayer: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
    });

    testWidgets('MenuTransitionControl transitions between all 5 screens',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MenuTransitionControl(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Defaults to Space (index 2)
      expect(find.byType(HomeScreen), findsOneWidget);

      // Navigate to Explore (index 0)
      MenuTransitionController.instance.animateTo(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ExploreScreen), findsOneWidget);

      // Navigate to Search (index 1)
      MenuTransitionController.instance.animateTo(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(SearchScreen), findsOneWidget);

      // Navigate to Library (index 3)
      MenuTransitionController.instance.animateTo(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(LibraryScreen), findsOneWidget);

      // Navigate to Profile (index 4)
      MenuTransitionController.instance.animateTo(4);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
