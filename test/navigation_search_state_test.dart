/// File: navigation_search_state_test.dart
/// Description: Unit and Widget tests verifying search state preservation across
/// menu transitions and search reset upon consecutive double-tap on the navigation Search tab.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/features/home/components/home_header.dart';
import 'package:project_anima/features/library/components/library_header.dart';
import 'package:project_anima/features/search/components/search_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NavigationController.instance.reset();
    MenuTransitionController.instance.reset();
  });

  group('NavigationController Double-Tap & Reselection Logic', () {
    test('Single tap on search switches tab without triggering reset', () {
      final nav = NavigationController.instance;
      int resetCount = 0;
      nav.searchResetNotifier.addListener(() => resetCount++);

      expect(nav.currentIndex, equals(0));

      // Tap 1: switch to Search tab
      nav.handleDestinationSelected(null, 1);

      expect(nav.currentIndex, equals(1));
      expect(resetCount, equals(0),
          reason: 'Single tap to switch to Search must not trigger reset');
    });

    test('Switching to Library and back to Search does NOT trigger reset', () {
      final nav = NavigationController.instance;
      int resetCount = 0;
      nav.searchResetNotifier.addListener(() => resetCount++);

      // 1. Switch to Search
      nav.handleDestinationSelected(null, 1);
      expect(nav.currentIndex, equals(1));
      expect(resetCount, equals(0));

      // 2. Switch to Library
      nav.handleDestinationSelected(null, 2);
      expect(nav.currentIndex, equals(2));
      expect(resetCount, equals(0));

      // 3. Switch back to Search
      nav.handleDestinationSelected(null, 1);
      expect(nav.currentIndex, equals(1));
      expect(resetCount, equals(0),
          reason: 'Returning to search must preserve state and not reset');
    });

    test('Two consecutive taps on Search within threshold triggers search reset', () {
      final nav = NavigationController.instance;
      int resetCount = 0;
      nav.searchResetNotifier.addListener(() => resetCount++);

      // Tap 1 on Search
      nav.handleDestinationSelected(null, 1);
      expect(resetCount, equals(0));

      // Tap 2 on Search immediately (consecutive tap)
      nav.handleDestinationSelected(null, 1);
      expect(resetCount, equals(1),
          reason: 'Second consecutive tap on search must trigger resetNotifier');
    });

    test('Third tap after reset does not immediately re-trigger without a fresh double-tap', () {
      final nav = NavigationController.instance;
      int resetCount = 0;
      nav.searchResetNotifier.addListener(() => resetCount++);

      // Tap 1 & 2
      nav.handleDestinationSelected(null, 1);
      nav.handleDestinationSelected(null, 1);
      expect(resetCount, equals(1));

      // Tap 3 (single tap)
      nav.handleDestinationSelected(null, 1);
      expect(resetCount, equals(1),
          reason: 'Third tap is the first tap of a new cycle; must not reset immediately');
    });
  });

  group('Widget Tests: Search State Preservation & Double-Tap Reset', () {
    testWidgets('Search query is preserved on tab change and resets on double-tap',
        (tester) async {
      // Build the app with MenuTransitionControl
      await tester.pumpWidget(
        const MaterialApp(
          home: MenuTransitionControl(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify we start on Home
      expect(find.byType(HomeHeader), findsOneWidget);

      // 2. Tap Search in bottom navigation (index 1)
      final searchNavFinder = find.byTooltip('Search');
      expect(searchNavFinder, findsOneWidget);
      await tester.tap(searchNavFinder);
      await tester.pumpAndSettle();

      // Verify we are on Search screen
      expect(find.text('BUSCAR EN LA BIBLIOTECA'), findsOneWidget);

      // 3. Type a query into the SearchBar
      final searchBarFinder = find.byType(AppSearchBar);
      expect(searchBarFinder, findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Radiohead');
      // Advance past the 280ms debounce window
      await tester.pump(const Duration(milliseconds: 350));

      // Verify the query is present
      expect(find.text('Radiohead'), findsOneWidget);

      // 4. Switch to Library tab
      final libraryNavFinder = find.byTooltip('Library');
      expect(libraryNavFinder, findsOneWidget);
      await tester.tap(libraryNavFinder);
      await tester.pump(const Duration(milliseconds: 300));
      // Ensure transition animation has fully finished and frame settled
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Library screen is active
      expect(find.byType(LibraryHeader), findsOneWidget);

      // 4b. Switch to Home tab
      final homeNavFinder = find.byTooltip('Home');
      expect(homeNavFinder, findsOneWidget);
      await tester.tap(homeNavFinder);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Home screen is active
      expect(find.byType(HomeHeader), findsOneWidget);

      // 5. Switch BACK to Search tab (single tap)
      await tester.tap(searchNavFinder);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      // CRITICAL ASSERTION 1: Search query MUST still be there!
      expect(find.text('Radiohead'), findsOneWidget,
          reason: 'Search query must be preserved when returning to Search screen');

      // 6. Tap Search in bottom navigation a SECOND time (consecutive tap on Search)
      await tester.tap(searchNavFinder);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      // CRITICAL ASSERTION 2: Initial state restored on double tap!
      expect(find.text('BUSCAR EN LA BIBLIOTECA'), findsOneWidget,
          reason: 'Search screen must return to initial state when tapping Search twice');
      expect(find.text('Radiohead'), findsNothing,
          reason: 'Search text must be cleared on double-tap');
    });
  });
}
