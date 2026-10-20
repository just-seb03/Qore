import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';
import 'package:project_anima/controls/navigation_controller.dart';
import 'package:project_anima/features/home/components/home_header.dart';
import 'package:project_anima/features/search/components/search_header.dart';
import 'package:project_anima/main.dart';

void main() {
  setUp(() {
    MenuTransitionController.instance.reset();
    NavigationController.instance.setIndex(0);
  });

  group('OvershootResistanceCurve tests', () {
    test('Boundary conditions and peak overshoot', () {
      const curve = OvershootResistanceCurve(1.25);

      // Start at 0.0
      expect(curve.transform(0.0), closeTo(0.0, 0.0001));

      // End at 1.0
      expect(curve.transform(1.0), closeTo(1.0, 0.0001));

      // Peak overshoot occurs at ~0.63 with value ~1.057 (> 1.0)
      final peakVal = curve.transform(0.63);
      expect(peakVal, greaterThan(1.05));
      expect(peakVal, lessThan(1.07));

      // Resistance settle: value decreases from peak back down to 1.0
      final settleVal = curve.transform(0.9);
      expect(settleVal, lessThan(peakVal));
      expect(settleVal, greaterThan(1.0));
    });
  });

  group('MenuTransitionController unit tests', () {
    test('Initial state is tab 0 (home) and forward direction', () {
      final controller = MenuTransitionController.instance;
      expect(controller.currentIndex, 0);
      expect(controller.previousIndex, 0);
      expect(controller.direction, MenuTransitionDirection.forward);
      expect(controller.isForward, isTrue);
      expect(controller.isAnimating, isFalse);
      expect(controller.duration, const Duration(milliseconds: 250));
      expect(controller.curve, isA<OvershootResistanceCurve>());
    });

    test('animateTo higher index sets forward direction', () {
      final controller = MenuTransitionController.instance;

      controller.animateTo(1);
      expect(controller.previousIndex, 0);
      expect(controller.currentIndex, 1);
      expect(controller.direction, MenuTransitionDirection.forward);
      expect(controller.isForward, isTrue);
      expect(controller.isAnimating, isTrue);

      controller.notifyAnimationFinished();
      expect(controller.isAnimating, isFalse);

      controller.animateTo(2);
      expect(controller.previousIndex, 1);
      expect(controller.currentIndex, 2);
      expect(controller.direction, MenuTransitionDirection.forward);
      expect(controller.isForward, isTrue);
    });

    test('animateTo lower index sets backward direction', () {
      final controller = MenuTransitionController.instance;

      // Start at 2 (Library)
      controller.animateTo(2);
      controller.notifyAnimationFinished();

      // Go to 0 (Home)
      controller.animateTo(0);
      expect(controller.previousIndex, 2);
      expect(controller.currentIndex, 0);
      expect(controller.direction, MenuTransitionDirection.backward);
      expect(controller.isForward, isFalse);

      controller.notifyAnimationFinished();

      // Go to 1 (Search)
      controller.animateTo(1);
      expect(controller.direction, MenuTransitionDirection.forward);
      controller.notifyAnimationFinished();

      // Go from 1 (Search) to 0 (Home)
      controller.animateTo(0);
      expect(controller.previousIndex, 1);
      expect(controller.currentIndex, 0);
      expect(controller.direction, MenuTransitionDirection.backward);
    });

    test('animateTo ignores identical or out-of-bound indices', () {
      final controller = MenuTransitionController.instance;

      controller.animateTo(0); // already at 0
      expect(controller.isAnimating, isFalse);

      controller.animateTo(-1); // out of bounds
      expect(controller.currentIndex, 0);

      controller.animateTo(3); // out of bounds
      expect(controller.currentIndex, 0);
    });

    test('animateToTab accepts NavigationTab enum values', () {
      final controller = MenuTransitionController.instance;

      controller.animateToTab(NavigationTab.search);
      expect(controller.currentIndex, 1);
      expect(controller.direction, MenuTransitionDirection.forward);

      controller.animateToTab(NavigationTab.library);
      expect(controller.currentIndex, 2);
      expect(controller.direction, MenuTransitionDirection.forward);

      controller.animateToTab(NavigationTab.home);
      expect(controller.currentIndex, 0);
      expect(controller.direction, MenuTransitionDirection.backward);
    });
  });

  group('MenuTransitionControl widget transition tests', () {
    testWidgets('Renders full AnimaApp with initial Home screen', (tester) async {
      await tester.pumpWidget(const AnimaApp());
      await tester.pump();

      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('Forward transition (Home -> Search) with overshoot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: MenuTransitionControl(),
        ),
      );
      await tester.pump();

      expect(find.byType(HomeHeader), findsOneWidget);

      // Tap the Search tab
      await tester.tap(find.text('Search'));
      await tester.pump(); // Start animation

      // Pump 157ms (~63% of 250ms where peak overshoot occurs)
      await tester.pump(const Duration(milliseconds: 157));

      final homeHeaderFinder = find.byType(HomeHeader);
      final searchHeaderFinder = find.byType(SearchHeader);

      expect(homeHeaderFinder, findsOneWidget);
      expect(searchHeaderFinder, findsOneWidget);

      final searchCenter = tester.getCenter(searchHeaderFinder);
      // At overshoot peak (~1.057), incoming offset is 1.0 - 1.057 = -0.057
      // On an 800px width screen, centerX is 400 - (0.057 * 800) = ~354px (< 400.0)!
      // The incoming window has overshot past center to the left!
      expect(searchCenter.dx < 400.0, isTrue);

      // Complete transition (settles back to center)
      await tester.pumpAndSettle();

      expect(find.byType(HomeHeader), findsNothing);
      expect(find.byType(SearchHeader), findsOneWidget);
      expect(tester.getCenter(find.byType(SearchHeader)).dx, 400.0);
    });

    testWidgets('Backward transition (Search -> Home) with overshoot', (tester) async {
      MenuTransitionController.instance.reset();

      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.dark,
          home: MenuTransitionControl(),
        ),
      );
      await tester.pump();

      // Go to Search first
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Tap Home
      await tester.tap(find.text('Home'));
      await tester.pump();

      // At peak overshoot (~157ms)
      await tester.pump(const Duration(milliseconds: 157));

      final homeCenter = tester.getCenter(find.byType(HomeHeader));
      // Moving backward from left: at overshoot peak (-1.0 + 1.057 = +0.057),
      // centerX is 400 + (0.057 * 800) = ~445px (> 400.0)!
      // The incoming window has overshot past center to the right!
      expect(homeCenter.dx > 400.0, isTrue);

      await tester.pumpAndSettle();

      // Settled exactly at center
      expect(tester.getCenter(find.byType(HomeHeader)).dx, 400.0);
    });
  });
}
