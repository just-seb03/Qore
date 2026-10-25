/// File: system_dimensions_test.dart
/// Description: Comprehensive unit and widget tests for SystemDimensions,
/// SystemDimensionsCoordinator, and AdaptiveSystemBoundary notch concealment adaptation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_anima/core/dimensions/adaptive_system_boundary.dart';
import 'package:project_anima/core/dimensions/system_dimensions.dart';
import 'package:project_anima/core/dimensions/system_dimensions_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SystemDimensions Model Unit Tests', () {
    test('Default fallback has notchHidden false and standard heights', () {
      final dimensions = SystemDimensions.fallback();
      expect(dimensions.isNotchHidden, isFalse);
      expect(dimensions.effectiveTopLimit, 0.0);
      expect(dimensions.effectiveBottomLimit, 0.0);
    });

    test('fromMap correctly parses Xiaomi force_black and calculates effectiveTopLimit', () {
      final map = {
        'isNotchHidden': true,
        'hasCutout': true,
        'notchHeight': 36.0,
        'statusBarHeight': 30.0,
        'navigationBarHeight': 48.0,
        'physicalWidth': 393.0,
        'physicalHeight': 851.0,
        'usableWidth': 393.0,
        'usableHeight': 815.0,
        'cutoutTop': 36.0,
        'density': 2.75,
        'manufacturer': 'Xiaomi',
        'model': 'Redmi Note 12',
      };

      final dimensions = SystemDimensions.fromMap(map);
      expect(dimensions.isNotchHidden, isTrue);
      expect(dimensions.hasCutout, isTrue);
      expect(dimensions.notchHeight, 36.0);
      expect(dimensions.statusBarHeight, 30.0);
      expect(dimensions.effectiveTopLimit, 36.0); // max(36, 30)
      expect(dimensions.manufacturer, 'Xiaomi');
    });

    test('customTopLimit overrides effectiveTopLimit even when notch is not hidden', () {
      const dimensions = SystemDimensions(
        isNotchHidden: false,
        notchHeight: 28.0,
        statusBarHeight: 24.0,
        customTopLimit: 50.0,
        customBottomLimit: 16.0,
      );

      expect(dimensions.effectiveTopLimit, 50.0);
      expect(dimensions.effectiveBottomLimit, 16.0);
    });
  });

  group('SystemDimensionsCoordinator Unit Tests', () {
    test('setCustomLimits updates notifier reactively', () {
      final coordinator = SystemDimensionsCoordinator.instance;
      coordinator.setDimensionsForTesting(
        const SystemDimensions(
          isNotchHidden: false,
          notchHeight: 30.0,
          statusBarHeight: 24.0,
        ),
      );

      expect(coordinator.currentDimensions.effectiveTopLimit, 0.0);

      coordinator.setCustomLimits(top: 42.0, bottom: 20.0);
      expect(coordinator.currentDimensions.customTopLimit, 42.0);
      expect(coordinator.currentDimensions.effectiveTopLimit, 42.0);
      expect(coordinator.currentDimensions.effectiveBottomLimit, 20.0);

      // Clean up
      coordinator.setCustomLimits(top: null, bottom: null);
    });
  });

  group('AdaptiveSystemBoundary Widget Tests', () {
    testWidgets('adapts MediaQuery padding and shifts content when notch is hidden', (tester) async {
      final coordinator = SystemDimensionsCoordinator.instance;
      coordinator.setDimensionsForTesting(
        const SystemDimensions(
          isNotchHidden: true,
          notchHeight: 40.0,
          statusBarHeight: 32.0,
          manufacturer: 'Xiaomi',
        ),
      );

      double capturedTopPadding = -1;
      bool capturedNotchHidden = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            // Simulate an edge-to-edge environment where top padding is 0 (rendering under notch)
            data: const MediaQueryData(
              padding: EdgeInsets.zero,
              viewPadding: EdgeInsets.zero,
            ),
            child: AdaptiveSystemBoundary(
              coordinator: coordinator,
              child: Builder(
                builder: (context) {
                  capturedTopPadding = MediaQuery.of(context).padding.top;
                  capturedNotchHidden = SystemBoundaryScope.isNotchHidden(context);
                  return const Scaffold(
                    body: Text('Content Safe from Hidden Notch'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Content Safe from Hidden Notch'), findsOneWidget);
      expect(capturedNotchHidden, isTrue);
      // MediaQuery padding top was dynamically adapted to 40.0!
      expect(capturedTopPadding, 40.0);
    });

    testWidgets('leaves padding untouched when notch is not hidden and no limits set', (tester) async {
      final coordinator = SystemDimensionsCoordinator.instance;
      coordinator.setDimensionsForTesting(
        const SystemDimensions(
          isNotchHidden: false,
          notchHeight: 24.0,
          statusBarHeight: 24.0,
        ),
      );

      double capturedTopPadding = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              padding: EdgeInsets.only(top: 24.0),
              viewPadding: EdgeInsets.only(top: 24.0),
            ),
            child: AdaptiveSystemBoundary(
              coordinator: coordinator,
              child: Builder(
                builder: (context) {
                  capturedTopPadding = MediaQuery.of(context).padding.top;
                  return const Scaffold(
                    body: Text('Normal Screen Content'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Normal Screen Content'), findsOneWidget);
      expect(capturedTopPadding, 24.0);
    });
  });
}
