/// File: film_grain.dart
/// Description: Provides a lightweight, GPU-accelerated monochromatic film grain
/// texture overlay. Uses a deterministic point distribution to simulate authentic
/// analog film grain with zero external asset dependencies and optimal frame rate.
///
/// Components / Classes / Functions:
/// - FilmGrain: Widget that overlays a subtle film grain layer over its child or canvas.
/// - FilmGrainPainter: CustomPainter rendering hardware-accelerated noise micro-points.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A widget that applies a monochromatic analog film grain texture.
///
/// Can be used as a standalone background or as an overlay wrapping a child widget.
/// Utilizes an [IgnorePointer] to ensure touch and gesture events pass through uninterrupted.
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
        child: CustomPaint(
          painter: FilmGrainPainter(
            intensity: intensity,
            seed: seed,
          ),
        ),
      ),
    );

    if (child == null) {
      return SizedBox.expand(
        child: IgnorePointer(
          child: CustomPaint(
            painter: FilmGrainPainter(
              intensity: intensity,
              seed: seed,
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

/// A high-performance [CustomPainter] that renders monochromatic noise points.
class FilmGrainPainter extends CustomPainter {
  final double intensity;
  final int seed;

  const FilmGrainPainter({
    required this.intensity,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paintLight = Paint()
      ..color = Colors.white.withValues(alpha: intensity.clamp(0.0, 1.0))
      ..strokeWidth = 1.0;

    final paintDark = Paint()
      ..color = Colors.black.withValues(alpha: (intensity * 1.4).clamp(0.0, 1.0))
      ..strokeWidth = 1.0;

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

    canvas.drawPoints(ui.PointMode.points, lightPoints, paintLight);
    canvas.drawPoints(ui.PointMode.points, darkPoints, paintDark);
  }

  @override
  bool shouldRepaint(covariant FilmGrainPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.seed != seed;
  }
}
