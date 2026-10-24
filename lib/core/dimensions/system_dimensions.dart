/// File: system_dimensions.dart
/// Description: Immutable data model encapsulating device screen dimensions,
/// status/navigation bar metrics, display cutout/notch state, and boundary limits
/// for adaptive notch masking handling (e.g. Xiaomi MIUI / Samsung One UI "Hide Notch").
///
/// Components / Classes / Functions:
/// - SystemDimensions: Immutable metric model with calculated effective boundaries.
library;

import 'dart:math' as math;

/// Holds the hardware and window dimensions, cutout status, and boundary limits.
class SystemDimensions {
  /// Whether the operating system has enabled a "Hide Notch" / "Hide Camera Cutout" mode.
  final bool isNotchHidden;

  /// Whether the hardware display contains a physical camera cutout or notch.
  final bool hasCutout;

  /// Height of the display notch or status bar area in logical pixels (dp).
  final double notchHeight;

  /// System status bar height in logical pixels (dp).
  final double statusBarHeight;

  /// System navigation bar height in logical pixels (dp).
  final double navigationBarHeight;

  /// Total physical screen width in logical pixels (dp).
  final double physicalWidth;

  /// Total physical screen height in logical pixels (dp).
  final double physicalHeight;

  /// Usable window width currently available to the application in dp.
  final double usableWidth;

  /// Usable window height currently available to the application in dp.
  final double usableHeight;

  /// Safe inset at the top of the display cutout in dp.
  final double cutoutTop;

  /// Safe inset at the bottom of the display cutout in dp.
  final double cutoutBottom;

  /// Display pixel density factor.
  final double density;

  /// Device hardware manufacturer (e.g. "Xiaomi", "samsung").
  final String manufacturer;

  /// Device hardware model name.
  final String model;

  /// Optional user/system configured top boundary override in dp.
  final double? customTopLimit;

  /// Optional user/system configured bottom boundary override in dp.
  final double? customBottomLimit;

  const SystemDimensions({
    this.isNotchHidden = false,
    this.hasCutout = false,
    this.notchHeight = 0.0,
    this.statusBarHeight = 0.0,
    this.navigationBarHeight = 0.0,
    this.physicalWidth = 0.0,
    this.physicalHeight = 0.0,
    this.usableWidth = 0.0,
    this.usableHeight = 0.0,
    this.cutoutTop = 0.0,
    this.cutoutBottom = 0.0,
    this.density = 1.0,
    this.manufacturer = '',
    this.model = '',
    this.customTopLimit,
    this.customBottomLimit,
  });

  /// Factory creating fallback system dimensions when platform channels are unavailable.
  factory SystemDimensions.fallback() {
    return const SystemDimensions(
      isNotchHidden: false,
      hasCutout: false,
      notchHeight: 24.0,
      statusBarHeight: 24.0,
      navigationBarHeight: 48.0,
    );
  }

  /// Factory parsing platform channel dictionary returned by native Android MainActivity.
  factory SystemDimensions.fromMap(Map<dynamic, dynamic> map, {double? customTop, double? customBottom}) {
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    bool toBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val != 0;
      return val.toString().toLowerCase() == 'true';
    }

    return SystemDimensions(
      isNotchHidden: toBool(map['isNotchHidden']),
      hasCutout: toBool(map['hasCutout']),
      notchHeight: toDouble(map['notchHeight']),
      statusBarHeight: toDouble(map['statusBarHeight']),
      navigationBarHeight: toDouble(map['navigationBarHeight']),
      physicalWidth: toDouble(map['physicalWidth']),
      physicalHeight: toDouble(map['physicalHeight']),
      usableWidth: toDouble(map['usableWidth']),
      usableHeight: toDouble(map['usableHeight']),
      cutoutTop: toDouble(map['cutoutTop']),
      cutoutBottom: toDouble(map['cutoutBottom']),
      density: toDouble(map['density'] ?? 1.0),
      manufacturer: map['manufacturer']?.toString() ?? '',
      model: map['model']?.toString() ?? '',
      customTopLimit: customTop,
      customBottomLimit: customBottom,
    );
  }

  /// Effective top boundary limit in logical pixels.
  /// If a custom top limit is set, it takes precedence.
  /// Otherwise, if the notch is hidden, enforces the notch or status bar height
  /// to prevent the application from rendering underneath the simulated black bezel.
  double get effectiveTopLimit {
    if (customTopLimit != null) {
      return customTopLimit!;
    }
    if (isNotchHidden) {
      return math.max(notchHeight, statusBarHeight);
    }
    return 0.0;
  }

  /// Effective bottom boundary limit in logical pixels.
  double get effectiveBottomLimit {
    if (customBottomLimit != null) {
      return customBottomLimit!;
    }
    return 0.0;
  }

  /// Copies instance with optional overrides.
  SystemDimensions copyWith({
    bool? isNotchHidden,
    bool? hasCutout,
    double? notchHeight,
    double? statusBarHeight,
    double? navigationBarHeight,
    double? physicalWidth,
    double? physicalHeight,
    double? usableWidth,
    double? usableHeight,
    double? cutoutTop,
    double? cutoutBottom,
    double? density,
    String? manufacturer,
    String? model,
    double? customTopLimit,
    double? customBottomLimit,
  }) {
    return SystemDimensions(
      isNotchHidden: isNotchHidden ?? this.isNotchHidden,
      hasCutout: hasCutout ?? this.hasCutout,
      notchHeight: notchHeight ?? this.notchHeight,
      statusBarHeight: statusBarHeight ?? this.statusBarHeight,
      navigationBarHeight: navigationBarHeight ?? this.navigationBarHeight,
      physicalWidth: physicalWidth ?? this.physicalWidth,
      physicalHeight: physicalHeight ?? this.physicalHeight,
      usableWidth: usableWidth ?? this.usableWidth,
      usableHeight: usableHeight ?? this.usableHeight,
      cutoutTop: cutoutTop ?? this.cutoutTop,
      cutoutBottom: cutoutBottom ?? this.cutoutBottom,
      density: density ?? this.density,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      customTopLimit: customTopLimit ?? this.customTopLimit,
      customBottomLimit: customBottomLimit ?? this.customBottomLimit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNotchHidden': isNotchHidden,
      'hasCutout': hasCutout,
      'notchHeight': notchHeight,
      'statusBarHeight': statusBarHeight,
      'navigationBarHeight': navigationBarHeight,
      'physicalWidth': physicalWidth,
      'physicalHeight': physicalHeight,
      'usableWidth': usableWidth,
      'usableHeight': usableHeight,
      'cutoutTop': cutoutTop,
      'cutoutBottom': cutoutBottom,
      'density': density,
      'manufacturer': manufacturer,
      'model': model,
      'customTopLimit': customTopLimit,
      'customBottomLimit': customBottomLimit,
      'effectiveTopLimit': effectiveTopLimit,
      'effectiveBottomLimit': effectiveBottomLimit,
    };
  }

  @override
  String toString() {
    return 'SystemDimensions(isNotchHidden: $isNotchHidden, hasCutout: $hasCutout, '
        'notchHeight: $notchHeight, statusBar: $statusBarHeight, navBar: $navigationBarHeight, '
        'effectiveTop: $effectiveTopLimit, effectiveBottom: $effectiveBottomLimit)';
  }
}
