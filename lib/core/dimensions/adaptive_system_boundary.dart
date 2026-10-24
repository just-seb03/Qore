/// File: adaptive_system_boundary.dart
/// Description: Adaptive layout boundary wrapper adjusting MediaQuery padding, viewPadding,
/// and safe boundary limits when a device's display notch is concealed (e.g. Xiaomi MIUI
/// or Samsung One UI "Hide Notch"), preventing top content clipping and bottom navigation truncation.
///
/// Components / Classes / Functions:
/// - SystemBoundaryScope: InheritedWidget providing inherited SystemDimensions to descendent widgets.
/// - AdaptiveSystemBoundary: Widget listening to SystemDimensionsCoordinator and enforcing safe boundaries.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:project_anima/core/dimensions/system_dimensions.dart';
import 'package:project_anima/core/dimensions/system_dimensions_coordinator.dart';

/// Inherited scope providing access to active [SystemDimensions] in the widget tree.
class SystemBoundaryScope extends InheritedWidget {
  final SystemDimensions dimensions;

  const SystemBoundaryScope({
    super.key,
    required this.dimensions,
    required super.child,
  });

  /// Retrieves the closest [SystemDimensions] from the widget hierarchy.
  static SystemDimensions of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SystemBoundaryScope>();
    return scope?.dimensions ??
        SystemDimensionsCoordinator.instance.currentDimensions;
  }

  /// Convenience lookup returning whether the active device has notch concealment enabled.
  static bool isNotchHidden(BuildContext context) {
    return of(context).isNotchHidden;
  }

  @override
  bool updateShouldNotify(SystemBoundaryScope oldWidget) {
    return dimensions != oldWidget.dimensions;
  }
}

/// Adaptive boundary container that synchronizes screen boundaries with system dimensions.
///
/// Automatically intercepts [MediaQuery] and ensures that if a manufacturer has simulated
/// a black bezel / hidden notch over the screen, the application's padding and limits
/// adapt dynamically, preventing UI elements from drawing under the black bar or
/// pushing the bottom navigation bar off-screen.
class AdaptiveSystemBoundary extends StatelessWidget {
  final Widget child;

  /// Optional override coordinator (for dependency injection/testing).
  final SystemDimensionsCoordinator? coordinator;

  const AdaptiveSystemBoundary({
    super.key,
    required this.child,
    this.coordinator,
  });

  @override
  Widget build(BuildContext context) {
    final activeCoordinator = coordinator ?? SystemDimensionsCoordinator.instance;

    return ValueListenableBuilder<SystemDimensions>(
      valueListenable: activeCoordinator.dimensionsNotifier,
      builder: (context, dimensions, _) {
        final mediaQuery = MediaQuery.of(context);

        final effectiveTopLimit = dimensions.effectiveTopLimit;
        final effectiveBottomLimit = dimensions.effectiveBottomLimit;

        // Determine adapted top and bottom insets
        final double adaptedTop = math.max(mediaQuery.padding.top, effectiveTopLimit);
        final double adaptedBottom =
            math.max(mediaQuery.padding.bottom, effectiveBottomLimit);

        final adaptedMediaQuery = mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(
            top: adaptedTop,
            bottom: adaptedBottom,
          ),
          viewPadding: mediaQuery.viewPadding.copyWith(
            top: adaptedTop,
            bottom: adaptedBottom,
          ),
        );

        return MediaQuery(
          data: adaptedMediaQuery,
          child: SystemBoundaryScope(
            dimensions: dimensions,
            child: child,
          ),
        );
      },
    );
  }
}
