/// File: film_grain.dart
/// Description: Provides a lightweight, GPU-accelerated monochromatic film grain
/// texture overlay. Uses a deterministic point distribution to simulate authentic
/// analog film grain with zero external asset dependencies and optimal frame rate.
/// Employs RepaintBoundary isolation and static point caching to eliminate heap allocations.
///
/// Components / Classes / Functions:
/// - FilmGrain: Widget that overlays a subtle film grain layer over its child or canvas.
/// - FilmGrainPainter: High-performance CustomPainter rendering cached noise micro-points.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A widget that applies a monochromatic analog film grain texture.
///
/// Can be used as a standalone background or as an overlay wrapping a child widget.
/// Utilizes an [IgnorePointer] to ensure touch and gesture events pass through uninterrupted,
/// and encapsulates the noise layer in a [RepaintBoundary] to isolate it from child animations.
class FilmGrain extends StatelessWidget {
  /// The optional widget over which the film grain texture is overlaid.
  final Widget? child;

  /// Grain opacity intensity (recommended range: 0.02 - 0.06).
  final double intensity;

  /// Seed value used for deterministic point generation to avoid re-calculation flicker.
  final int seed;

  const FilmGrain({
    super.key,
    this.child,
    this.intensity = 0.035,
    this.seed = 999,
  });

  @override
  Widget build(BuildContext context) {
    final grainOverlay = Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: FilmGrainPainter(
              intensity: intensity,
              seed: seed,
            ),
          ),
        ),
      ),
    );

    if (child == null) {
      return SizedBox.expand(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: FilmGrainPainter(
                intensity: intensity,
                seed: seed,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child!,
        grainOverlay,
      ],
    );
  }
}

/// Cache key identifying points by integer dimensions and random seed.
class _GrainCacheKey {
  final int width;
  final int height;
  final int seed;

  const _GrainCacheKey(this.width, this.height, this.seed);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _GrainCacheKey &&
          other.width == width &&
          other.height == height &&
          other.seed == seed;

  @override
  int get hashCode => Object.hash(width, height, seed);
}

/// Pre-allocated point clusters for light and dark micro-points.
class _GrainPointData {
  final List<Offset> lightPoints;
  final List<Offset> darkPoints;

  const _GrainPointData(this.lightPoints, this.darkPoints);
}

/// A high-performance [CustomPainter] that renders cached monochromatic noise points.
class FilmGrainPainter extends CustomPainter {
  final double intensity;
  final int seed;

  FilmGrainPainter({
    required this.intensity,
    required this.seed,
  });

  // Global LRU-style cache storing generated point coordinates per dimension/seed.
  // Completely eliminates object allocations in paint() across consecutive frames.
  static final Map<_GrainCacheKey, _GrainPointData> _pointCache = {};

  Paint? _paintLight;
  Paint? _paintDark;
  double? _lastPaintIntensity;

  void _ensurePaints() {
    if (_paintLight == null || _lastPaintIntensity != intensity) {
      _lastPaintIntensity = intensity;
      _paintLight = Paint()
        ..color = Colors.white.withValues(alpha: intensity.clamp(0.0, 1.0))
        ..strokeWidth = 1.0;
      _paintDark = Paint()
        ..color = Colors.black.withValues(alpha: (intensity * 1.4).clamp(0.0, 1.0))
        ..strokeWidth = 1.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final key = _GrainCacheKey(size.width.toInt(), size.height.toInt(), seed);
    var pointData = _pointCache[key];

    if (pointData == null) {
      // Keep cache small and bounded to avoid any memory leak over layout changes
      if (_pointCache.length >= 8) {
        _pointCache.clear();
      }

      final random = math.Random(seed);
      // Density calculation: approx 1 point per 16 px² bounded between 200 and 4000 points
      final pointCount = ((size.width * size.height) / 16).clamp(200, 4000).toInt();

      final lightPoints = <Offset>[];
      final darkPoints = <Offset>[];

      for (int i = 0; i < pointCount; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        if (random.nextBool()) {
          lightPoints.add(Offset(x, y));
        } else {
          darkPoints.add(Offset(x, y));
        }
      }

      pointData = _GrainPointData(lightPoints, darkPoints);
      _pointCache[key] = pointData;
    }

    _ensurePaints();
    canvas.drawPoints(ui.PointMode.points, pointData.lightPoints, _paintLight!);
    canvas.drawPoints(ui.PointMode.points, pointData.darkPoints, _paintDark!);
  }

  @override
  bool shouldRepaint(covariant FilmGrainPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.seed != seed;
  }
}
