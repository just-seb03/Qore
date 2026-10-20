import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/controls/menu_transition_controller.dart';

void main() {
  group('MenuTransitionController tests', () {
    late MenuTransitionController controller;

    setUp(() {
      controller = MenuTransitionController();
      controller.reset();
    });

    test('Initial state is Home (index 0) and not animating', () {
      expect(controller.currentIndex, 0);
      expect(controller.previousIndex, 0);
      expect(controller.isAnimating, false);
      expect(controller.direction, MenuTransitionDirection.forward);
    });

    test('animateTo higher index sets forward direction', () {
      controller.animateTo(2);
      expect(controller.currentIndex, 2);
      expect(controller.previousIndex, 0);
      expect(controller.direction, MenuTransitionDirection.forward);
      expect(controller.isAnimating, true);
    });

    test('animateTo lower index sets backward direction', () {
      controller.animateTo(2);
      controller.notifyAnimationFinished();
      controller.animateTo(1);
      expect(controller.currentIndex, 1);
      expect(controller.previousIndex, 2);
      expect(controller.direction, MenuTransitionDirection.backward);
      expect(controller.isAnimating, true);
    });

    test('animateTo identical index is a no-op', () {
      controller.animateTo(0);
      expect(controller.isAnimating, false);
    });

    test('animateTo invalid index is ignored', () {
      controller.animateTo(5);
      expect(controller.currentIndex, 0);
      expect(controller.isAnimating, false);
    });

    test('OvershootResistanceCurve boundary checks', () {
      const curve = OvershootResistanceCurve(1.25);
      expect(curve.transform(0.0), closeTo(0.0, 0.001));
      expect(curve.transform(1.0), closeTo(1.0, 0.001));
      // Curve overshoots > 1.0 around t ~ 0.7-0.8
      expect(curve.transform(0.75), greaterThan(1.0));
    });
  });

  group('MenuTransitionControl Widget tests', () {
    testWidgets('Renders children and uses SlideTransition during transition',
        (tester) async {
      final controller = MenuTransitionController();
      controller.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: MenuTransitionControl(
            controller: controller,
            includeBottomNav: false,
            children: const [
              Text('Screen 0'),
              Text('Screen 1'),
              Text('Screen 2'),
            ],
          ),
        ),
      );

      expect(find.text('Screen 0'), findsOneWidget);
      expect(find.text('Screen 1'), findsNothing);

      // Trigger transition to Screen 1
      controller.animateTo(1);
      await tester.pump(); // Start animation frame

      // During transition, SlideTransitions are mounted inside MenuTransitionControl
      final transitionFinder = find.descendant(
        of: find.byType(MenuTransitionControl),
        matching: find.byType(SlideTransition),
      );
      expect(transitionFinder, findsNWidgets(2));
      expect(find.text('Screen 0'), findsOneWidget);
      expect(find.text('Screen 1'), findsOneWidget);

      // Settle animation to completion
      await tester.pumpAndSettle();

      // After settling, only current screen remains in the tree (0 SlideTransitions inside MenuTransitionControl)
      expect(transitionFinder, findsNothing);
      expect(find.text('Screen 1'), findsOneWidget);
      expect(find.text('Screen 0'), findsNothing);
    });
  });
}
