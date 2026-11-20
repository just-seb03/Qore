/// File: system_dimensions_coordinator.dart
/// Description: Centralized coordinator querying hardware dimensions and notch
/// concealment state via MethodChannel, offering reactive updates and boundary configuration.
///
/// Components / Classes / Functions:
/// - SystemDimensionsCoordinator: Singleton ChangeNotifier/ValueNotifier coordinating dimensions.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:project_anima/core/dimensions/system_dimensions.dart';

/// Central coordinator for system dimensions and notch concealment boundary adaptation.
class SystemDimensionsCoordinator {
  static final SystemDimensionsCoordinator instance =
      SystemDimensionsCoordinator._internal();

  static const MethodChannel _channel =
      MethodChannel('project_anima/system_dimensions');

  final ValueNotifier<SystemDimensions> _dimensionsNotifier =
      ValueNotifier<SystemDimensions>(SystemDimensions.fallback());

  double? _customTopLimit;
  double? _customBottomLimit;
  bool _isInitialized = false;

  SystemDimensionsCoordinator._internal();

  factory SystemDimensionsCoordinator() => instance;

  /// Reactive notifier emitting updated system metrics.
  ValueListenable<SystemDimensions> get dimensionsNotifier =>
      _dimensionsNotifier;

  /// Current snapshot of system dimensions and safe boundary limits.
  SystemDimensions get currentDimensions => _dimensionsNotifier.value;

  /// Initializes system dimension querying and checks notch concealment state.
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await refresh();
  }

  /// Refreshes dimensions from the native Android WindowManager and DisplayCutout.
  Future<SystemDimensions> refresh() async {
    try {
      final result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>('getSystemDimensions');
      if (result != null) {
        final parsed = SystemDimensions.fromMap(
          result,
          customTop: _customTopLimit,
          customBottom: _customBottomLimit,
        );
        _dimensionsNotifier.value = parsed;
        return parsed;
      }
    } catch (e) {
      debugPrint('SystemDimensionsCoordinator: Native query unavailable ($e), using fallback.');
    }
    return _dimensionsNotifier.value;
  }

  /// Sets manual boundary limits (e.g. for user configuration or custom bezel compensation).
  void setCustomLimits({double? top, double? bottom}) {
    _customTopLimit = top;
    _customBottomLimit = bottom;
    _dimensionsNotifier.value = _dimensionsNotifier.value.copyWith(
      customTopLimit: top,
      customBottomLimit: bottom,
    );
  }

  /// Resets custom limits, returning to automatic system and notch detection.
  void resetLimits() {
    _customTopLimit = null;
    _customBottomLimit = null;
    refresh();
  }

  /// Instructs the native Android Window to apply a specific layoutInDisplayCutoutMode:
  /// - 'never': Never extend into cutout area (forces window below hidden notch).
  /// - 'shortEdges': Extend into cutout on short edges (full edge-to-edge).
  /// - 'default': Default system cutout behavior.
  /// - 'auto': Automatically select 'never' if notch is hidden, else 'shortEdges'.
  Future<bool> setNativeCutoutMode(String mode) async {
    try {
      final success =
          await _channel.invokeMethod<bool>('setCutoutMode', {'mode': mode});
      await refresh();
      return success ?? false;
    } catch (e) {
      debugPrint('SystemDimensionsCoordinator: setNativeCutoutMode failed: $e');
      return false;
    }
  }

  /// Moves the app task to background without finishing the Activity or interrupting audio.
  Future<bool> moveToBackground() async {
    try {
      final moved = await _channel.invokeMethod<bool>('moveToBackground');
      return moved ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Injects simulated dimensions for unit and widget testing.
  @visibleForTesting
  void setDimensionsForTesting(SystemDimensions dimensions) {
    _dimensionsNotifier.value = dimensions;
  }
}
